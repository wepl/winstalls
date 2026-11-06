;*---------------------------------------------------------------------------
;  :Module.	amigus.s
;  :Contents.	AmiGUS driver for the WHDLoad audio plugin WHDLoad.Audio
;  :Author.	Wepl
;  :History.	18.10.26 moved from WHDLoad.Audio.asm into separate file
;		18.10.26 AmiGUS mini support (interrupt via Gayle)
;		27.10.26 AmiGUS: VS1063a patches 2.6 of VLSI are loaded
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly, Vasm
;---------------------------------------------------------------------------*
; included by WHDLoad.Audio.asm, the variables are located at _vars which has
; a size of VARS_SIZEOF

;############################################################################
; AmiGUS
; https://github.com/necronomfive/AmiGUS-pub
; register maps Documentation/AmiGUS/AmiGUS_Register_Map.xlsx and
; Documentation/AmiGUS_mini/AmiGUS_mini_Register_Map.xlsx
; the codec part contains a VS1063a decoder which is fed via a fifo
; the card raises level 2 interrupts (INT2/PORTS)
; the Zorro II card has its own board, the AmiGUS mini is a PCMCIA card which
; is accessed via the attribute memory, its interrupt is routed via Gayle and
; must be acknowledged there too (normally done by card.resource)
;############################################################################

AMIGUS_FindCard		= -30		;a0=card -> d0=card
AMIGUS_ReserveCard	= -36		;a0=card d0=which d1=owner -> d0=error
AMIGUS_FreeCard		= -42		;a0=card d0=which d1=owner

AMIGUS_FLAG_CODEC	= 4
AMIGUS_TYPE_ZORRO2	= $7000
AMIGUS_TYPE_MINI	= $7001

	;Gayle (A600/A1200), see Linux arch/m68k/include/asm/amigayle.h
GAYLE_BASE		= $da8000
GAYLE_END		= $dabfff
GAYLE_INTREQ		= $da9000	;write: 0 = clear request, 1 = unchanged
GAYLE_INTEN		= $daa000
GAYLEB_IRQ		= 2		;PCMCIA card interrupt
GAYLE_INTREQ_ACK	= $f8		;clear card interrupt (like Linux pcmcia_ack_int)

	;struct AmiGUS (amigus.h)
agus_PcmBase		= 0
agus_WavetableBase	= 4
agus_CodecBase		= 8
agus_FpgaId		= 12
agus_HardwareRev	= 20
agus_FirmwareRev	= 24
agus_TypeName		= 28
agus_TypeId		= 32
agus_Year		= 34
agus_Month		= 36
agus_Day		= 37
agus_Hour		= 38
agus_Minute		= 39

	;codec registers
AGC_INT_CONTROL		= $00		;interrupt request, write: bit15=1 set, bit15=0 clear
AGC_INT_ENABLE		= $02		;interrupt enable, write: bit15=1 set, bit15=0 clear
AGC_FIFO_CONTROL	= $04		;bit15 = dma fifo -> vs1063 enable
AGC_FIFO_RESET		= $06		;strobe
AGC_FIFO_WATERMARK	= $08		;in words
AGC_FIFO_WRITE		= $0a		;long write
AGC_FIFO_USAGE		= $0e		;in words
AGC_SPI_ADDRESS		= $20
AGC_SPI_WDATA		= $22
AGC_SPI_WTRIGGER	= $24
AGC_SPI_RTRIGGER	= $26
AGC_SPI_RDATA		= $28
AGC_SPI_STATUS		= $2a		;bit15 = spi busy, bit14 = vs1063 busy (!DREQ)

AGCINTF_EMPTY		= $0001
AGCINTF_FULL		= $0002
AGCINTF_WATERMARK	= $0004
AGCINTF_SPI		= $0008
AGCINTF_DRQ		= $0010
AGCINTF_TIMER		= $4000
AGCINTF_SET		= $8000
AGCINTF_ALL		= AGCINTF_EMPTY|AGCINTF_FULL|AGCINTF_WATERMARK|AGCINTF_SPI|AGCINTF_DRQ|AGCINTF_TIMER
AGCINTF_USED		= AGCINTF_EMPTY|AGCINTF_WATERMARK
AGC_FIFO_DMA		= $8000
AGC_SPI_BUSY		= $c000
AGCSPIB_VSBUSY		= 14		;vs1063 busy (!DREQ)

AGC_FIFO_WORDS		= 2048
AGC_WATERMARK		= 1024		;words
AGC_ENDFILLBYTES	= 12288		;end fill bytes after stream (FLAC requires 12288)
AGC_CANCELBYTES		= 2048		;max end fill bytes until SM_CANCEL is cleared
AGC_SPITIMEOUT		= 100000
AGC_DRAINTIMEOUT	= 5000000	;the decoder plays the rest of the fifo
AGC_CANCELWAIT		= 50000		;SCI reads, about one second
AGC_RLOGSIZE		= 8		;resets logged

	;VS1063 SCI registers
SCI_MODE		= 0
SCI_STATUS		= 1
SCI_CLOCKF		= 3
SCI_WRAM		= 6
SCI_WRAMADDR		= 7
SCI_HDAT0		= 8
SCI_HDAT1		= 9
SCI_VOL			= $b

SM_LAYER12		= $0002
SM_RESET		= $0004
SM_CANCEL		= $0008
SM_SDINEW		= $0800
SM_CLK_RANGE		= $4000
SC_MULT_5_0X		= $e000
VS_ENDFILL		= $c0c6
VS_GPIO_DDR		= $c017
VS_I2S_CONFIG		= $c040
VS_GPIO_DDR_I2S		= $d0		;GPIO4/6/7 (LROUT/SCLK/SDATA) as outputs
VS_I2S_CONFIG_192K	= $06		;I2S enable, 192 kHz
VS_HDAT1_FLAC		= $664c		;"fL"
VS_CANCELFILL		= 2052		;end fill bytes on stop, FLAC requires AGC_ENDFILLBYTES

	;state
AGS_IDLE		= 0		;not playing
AGS_PLAY		= 1		;audio data are fed
AGS_ENDFILL		= 2		;end fill bytes are fed
AGS_FINISHED		= 3		;everything fed

	;entry of the reset log, traced on exit
	STRUCTURE	AmiGUSResetLog,0
		ULONG	rl_stop			;number of the stop
		CPTR	rl_reason		;reason of the reset
		ULONG	rl_fmt			;format (HDAT1) of the stream
		ULONG	rl_mode			;SCI_MODE before reset
		ULONG	rl_result		;amigusi_reset result, 0 = success
		ULONG	rl_spistat		;spi status after reset
		LABEL	rl_SIZEOF

	STRUCTURE	AmiGUSVars,0
		APTR	agv_libbase		;amigus.library
		APTR	agv_card		;struct AmiGUS
		APTR	agv_codec		;codec register base
		APTR	agv_start		;audio data start
		APTR	agv_end			;audio data end
		APTR	agv_ptr			;actual position
		ULONG	agv_endcnt		;remaining end fill longs
		ULONG	agv_endfill		;end fill pattern
		ULONG	agv_flags		;WHDLAUDF_*
		UWORD	agv_state		;AGS_*
		UWORD	agv_volume		;SCI_VOL value
		UBYTE	agv_mini		;<>0 = AmiGUS mini
		UBYTE	agv_inten		;original Gayle INTEN
		STRUCT	agv_mem,(2*3+1)*4	;memory list for WHDLoad
		UWORD	agv_cfmt		;format (HDAT1) of the stream being canceled
	;statistics about canceling the decoder, traced on exit
		ULONG	agv_cancels		;successful cancels
		ULONG	agv_resspi		;resets because of spi timeout
		ULONG	agv_resfull		;resets because fifo stays full
		ULONG	agv_resdrain		;resets because fifo is not drained
		ULONG	agv_restime		;resets because SM_CANCEL not cleared
		ULONG	agv_reshdat		;resets because HDAT0/1 <> 0 after cancel
		ULONG	agv_stops		;calls of amigusi_cancel
		ULONG	agv_rlogcnt		;resets, only AGC_RLOGSIZE are logged
		STRUCT	agv_rlog,AGC_RLOGSIZE*rl_SIZEOF
		LABEL	agv_SIZEOF

	IFLT VARS_SIZEOF-agv_SIZEOF
	FAIL	VARS_SIZEOF is too small for AmiGUSVars
	ENDC

	CNOP 0,4
amigus_driver	dc.l	amigus_name
		dc.l	amigus_init
		dc.l	amigus_exts
		dc.l	_vars+agv_mem
		dc.l	amigus_exit
		dc.l	amigus_play
		dc.l	amigus_stop
		dc.l	amigus_suspend
		dc.l	amigus_resume
		dc.l	amigus_volume
		dc.l	amigus_irq

;----------------------------------------
; detect and init AmiGUS
; IN:	-
; OUT:	d0 = LONG WAUDINIT_*
;	a0 = CPTR error message

amigus_init	movem.l	d1/d5/a2-a3/a5-a6,-(a7)	;d1 = stack space for trace args
		moveq	#WAUDINIT_NOHW,d5	;D5 = return code
		sub.l	a5,a5			;A5 = error message
		lea	(_vars,pc),a3		;A3 = vars

	;open library
		move.l	(4),a6
		moveq	#0,d0			;version
		lea	(amigus_libname,pc),a1
		jsr	(_LVOOpenLibrary,a6)
		move.l	d0,(agv_libbase,a3)
		lea	(amigus_trc_nolib,pc),a0
		beq	.trace

	;find card
		move.l	d0,a6			;A6 = library
		sub.l	a0,a0
		jsr	(AMIGUS_FindCard,a6)
		move.l	d0,(agv_card,a3)
		lea	(amigus_trc_nocard,pc),a0
		beq	.trace_closelib
		move.l	d0,a2			;A2 = struct AmiGUS

	;trace card properties
		move.l	(agus_PcmBase,a2),-(a7)
		move.l	(agus_CodecBase,a2),-(a7)
		moveq	#0,d0
		move.b	(agus_Minute,a2),d0
		move	d0,-(a7)
		move.b	(agus_Hour,a2),d0
		move	d0,-(a7)
		move.b	(agus_Day,a2),d0
		move	d0,-(a7)
		move.b	(agus_Month,a2),d0
		move	d0,-(a7)
		move	(agus_Year,a2),-(a7)
		move.l	(agus_FirmwareRev,a2),-(a7)
		move.l	(agus_HardwareRev,a2),-(a7)
		move	(agus_TypeId,a2),-(a7)
		move.l	(agus_TypeName,a2),-(a7)
		lea	(amigus_trc_card,pc),a0
		move.l	a7,a1
		bsr	_trace
		add	#5*4+6*2,a7

	;check type
		lea	(amigus_trc_type,pc),a0
		move	(agus_TypeId,a2),d0
		cmp	#AMIGUS_TYPE_ZORRO2,d0
		beq	.typeok
		cmp	#AMIGUS_TYPE_MINI,d0
		bne	.trace_closelib
.typeok
	;from now on each failure is an error
		moveq	#WAUDINIT_ERROR,d5

	;reserve codec
		move.l	a2,a0			;struct AmiGUS
		moveq	#AMIGUS_FLAG_CODEC,d0
		lea	(_base,pc),a1
		move.l	a1,d1			;owner
		jsr	(AMIGUS_ReserveCard,a6)
		lea	(amigus_err_inuse,pc),a5
		tst.l	d0
		beq	.reserved
		lea	(amigus_trc_inuse,pc),a0
		move.l	d0,(a7)
		move.l	a7,a1
		bra	.trace_closelib
.reserved	move.l	(agus_CodecBase,a2),a0
		move.l	a0,(agv_codec,a3)

	;memory list
		lea	(agv_mem,a3),a1
		moveq	#WAUDMEM_NCS,d0
		move.l	a0,(a1)+		;start
		cmp	#AMIGUS_TYPE_MINI,(agus_TypeId,a2)
		beq	.mini
	;Zorro II, the codec is a separate 64 KiB board
		add.l	#$ffff,a0
		move.l	a0,(a1)+		;end
		move.l	d0,(a1)+		;flags
		bra	.memend
	;mini, the codec registers are located in the PCMCIA attribute memory,
	;the interrupt is routed via Gayle
.mini		st	(agv_mini,a3)
		add	#$ff,a0
		move.l	a0,(a1)+		;end
		move.l	d0,(a1)+		;flags
		move.l	#GAYLE_BASE,(a1)+	;start
		move.l	#GAYLE_END,(a1)+	;end
		move.l	d0,(a1)+		;flags
		moveq	#0,d0
		move.b	(GAYLE_INTEN),d0
		move.b	d0,(agv_inten,a3)
		lea	(amigus_trc_gayle,pc),a0
		move.l	d0,(a7)
		move.l	a7,a1
		bsr	_trace
.memend

	;init codec, volume is maximum because vars are cleared
	;start with a software reset, the decoder may still hang from a
	;previous run
		lea	(amigus_err_vs,pc),a5
		move.l	(agv_codec,a3),a0
		bsr	amigusi_hwstop
		bsr	amigusi_reset
		bne	.free
	;success
		moveq	#WAUDINIT_OK,d5
		lea	(amigus_trc_ok,pc),a0

.trace		sub.l	a1,a1
		bsr	_trace
.end		move.l	d5,d0
		move.l	a5,a0
		movem.l	(a7)+,_MOVEMREGS
		rts

	;codec init failed, trace error with spi status
	;$ffff means the codec registers don't respond at all (open bus),
	;e.g. if the fpga config of the card is invalid
.free		moveq	#0,d0
		move	(AGC_SPI_STATUS,a0),d0
		cmp	#$ffff,d0
		bne	.vsfail
		move.l	d0,(a7)
		lea	(amigus_err_noacc,pc),a5
		lea	(amigus_trc_noacc,pc),a0
		move.l	a7,a1
		bsr	_trace
		bra	.freeend
	;additionally trace some SCI registers, read without waiting for DREQ,
	;to see whether the VS1063 still answers, the stack space of the saved
	;d1 is the last of the 5 arguments
.vsfail		lea	(-4*4,a7),a7
		move.l	d0,(a7)			;spi status
		moveq	#SCI_MODE,d0
		bsr	amigusi_sciraw
		move.l	d0,(4,a7)
		moveq	#SCI_STATUS,d0
		bsr	amigusi_sciraw
		move.l	d0,(8,a7)
		moveq	#SCI_HDAT0,d0
		bsr	amigusi_sciraw
		move.l	d0,(12,a7)
		moveq	#SCI_HDAT1,d0
		bsr	amigusi_sciraw
		move.l	d0,(16,a7)
		lea	(amigus_trc_vsfail,pc),a0
		move.l	a7,a1
		bsr	_trace
		lea	(4*4,a7),a7
.freeend	bsr	amigusi_free
		bra	.end

.trace_closelib	bsr	_trace
		move.l	a6,a1
		move.l	(4),a6
		jsr	(_LVOCloseLibrary,a6)
		bra	.end

;----------------------------------------
; free AmiGUS
; IN:	-
; OUT:	-

amigus_exit	movem.l	d2/a2-a3,-(a7)
		lea	(_vars,pc),a3
		move.l	(agv_codec,a3),a0
		bsr	amigusi_hwstop
	;trace decoder statistics
		move.l	(agv_reshdat,a3),-(a7)
		move.l	(agv_restime,a3),-(a7)
		move.l	(agv_resdrain,a3),-(a7)
		move.l	(agv_resfull,a3),-(a7)
		move.l	(agv_resspi,a3),-(a7)
		move.l	(agv_cancels,a3),-(a7)
		lea	(amigus_trc_stat,pc),a0
		move.l	a7,a1
		bsr	_trace
		add	#6*4,a7
	;trace reset log
		lea	(agv_rlog,a3),a2
		move.l	(agv_rlogcnt,a3),d2
		cmp.l	#AGC_RLOGSIZE,d2
		bls	.rlognext
		moveq	#AGC_RLOGSIZE,d2
		bra	.rlognext
.rlog		lea	(amigus_trc_rlog,pc),a0
		move.l	a2,a1
		bsr	_trace
		add	#rl_SIZEOF,a2
.rlognext	dbf	d2,.rlog
	;restore Gayle card interrupt enable
		tst.b	(agv_mini,a3)
		beq	.free
		btst	#GAYLEB_IRQ,(agv_inten,a3)
		bne	.free
		bclr	#GAYLEB_IRQ,(GAYLE_INTEN)
.free		bsr	amigusi_free
		movem.l	(a7)+,_MOVEMREGS
		rts

;----------------------------------------
; release codec and close amigus.library
; IN:	a3 = APTR vars
; OUT:	-
;	d0-d1/a0-a1 destroyed

amigusi_free	move.l	a6,-(a7)
		move.l	(agv_libbase,a3),a6
		move.l	(agv_card,a3),a0
		moveq	#AMIGUS_FLAG_CODEC,d0
		lea	(_base,pc),a1
		move.l	a1,d1			;owner
		jsr	(AMIGUS_FreeCard,a6)
		move.l	a6,a1
		move.l	(4),a6
		jsr	(_LVOCloseLibrary,a6)
		move.l	(a7)+,a6
		rts

;----------------------------------------
; start playing
; IN:	d0 = ULONG length
;	d1 = ULONG flags
;	a0 = APTR  audio data
; OUT:	-

amigus_play	move.l	a3,-(a7)
		lea	(_vars,pc),a3
		move.l	a0,(agv_start,a3)
		move.l	a0,(agv_ptr,a3)
		addq.l	#3,d0			;round up to longs, the data start is long
		and	#-4,d0			;aligned and the WHDLoad allocation covers it
		add.l	d0,a0
		move.l	a0,(agv_end,a3)
		move.l	d1,(agv_flags,a3)
		move.l	(agv_codec,a3),a0
	;stop actual stream, also if it has already finished, because the
	;decoder must be canceled before a new stream can be started
		bsr	amigusi_stop
		move	#AGC_WATERMARK,(AGC_FIFO_WATERMARK,a0)
		move	#AGS_PLAY,(agv_state,a3)
	;prefill fifo
		bsr	amigusi_fill
	;start
		move	#AGC_FIFO_DMA,(AGC_FIFO_CONTROL,a0)
		move	#AGCINTF_SET|AGCINTF_USED,(AGC_INT_ENABLE,a0)
	;enable card interrupt in Gayle
		tst.b	(agv_mini,a3)
		beq	.end
		bset	#GAYLEB_IRQ,(GAYLE_INTEN)
.end		move.l	(a7)+,a3
		rts

;----------------------------------------
; stop playing
; IN:	-
; OUT:	-

amigus_stop	move.l	a3,-(a7)
		lea	(_vars,pc),a3
		move.l	(agv_codec,a3),a0
		bsr	amigusi_stop
		move.l	(a7)+,a3
		rts

;----------------------------------------
; suspend/resume interrupts
; IN:	-
; OUT:	-

amigus_suspend	move.l	(_vars+agv_codec,pc),a0
		move	#AGCINTF_USED,(AGC_INT_ENABLE,a0)
		rts

amigus_resume	move.l	(_vars+agv_codec,pc),a0
		move	(_vars+agv_state,pc),d0
		beq	.end
		cmp	#AGS_FINISHED,d0
		beq	.end
		move	#AGCINTF_SET|AGCINTF_USED,(AGC_INT_ENABLE,a0)
.end		rts

;----------------------------------------
; set volume
; IN:	d0 = ULONG volume 0..$7fff
; OUT:	-

amigus_volume	move.l	a3,-(a7)
		lea	(_vars,pc),a3
		moveq	#-2,d1			;$fe = silent
		tst	d0
		beq	.set
		lsr	#8,d0			;0..127
		move.b	(.voltab,pc,d0.w),d1
.set		move.b	d1,d0
		lsl	#8,d0
		move.b	d1,d0			;left/right
		move	d0,(agv_volume,a3)
		move.l	(agv_codec,a3),a0
		bsr	amigusi_setvol
		move.l	(a7)+,a3
		rts

	;attenuation in 0.5 dB steps for volume>>8
	;-40*log10((i+0.5)*256/32767), i = 0..127
.voltab		dc.b	96,77,68,63,58,55,52,49,47,45,43,42,40,39,38,37
		dc.b	36,35,34,33,32,31,30,29,29,28,27,27,26,25,25,24
		dc.b	24,23,23,22,22,21,21,20,20,20,19,19,18,18,18,17
		dc.b	17,17,16,16,15,15,15,15,14,14,14,13,13,13,12,12
		dc.b	12,12,11,11,11,11,10,10,10,10,9,9,9,9,8,8
		dc.b	8,8,8,7,7,7,7,7,6,6,6,6,6,5,5,5
		dc.b	5,5,5,4,4,4,4,4,4,3,3,3,3,3,3,2
		dc.b	2,2,2,2,2,1,1,1,1,1,1,1,0,0,0,0

;----------------------------------------
; interrupt routine
; IN:	-
; OUT:	d0 = ULONG WAUDIRQF_*

amigus_irq	movem.l	d2/a3,-(a7)
		lea	(_vars,pc),a3
		moveq	#0,d0
		move.l	(agv_codec,a3),a0
	;check if the interrupt is ours
		move	(AGC_INT_ENABLE,a0),d2
		and	(AGC_INT_CONTROL,a0),d2
		and	#AGCINTF_USED,d2
		beq	.end
	;feed the fifo
		bsr	amigusi_fill		;d0 = WAUDIRQF_*
	;acknowledge
		move	d2,(AGC_INT_CONTROL,a0)
	;mini, acknowledge card interrupt in Gayle
	;also if not caused by the codec, otherwise it would never be cleared
.end		tst.b	(agv_mini,a3)
		beq	.rts
		btst	#GAYLEB_IRQ,(GAYLE_INTREQ)
		beq	.rts
		move.b	#GAYLE_INTREQ_ACK,(GAYLE_INTREQ)
.rts		movem.l	(a7)+,_MOVEMREGS
		rts

;----------------------------------------
; feed the fifo
; called by amigus_play to prefill the fifo and by amigus_irq on watermark or
; empty interrupt
; the fifo is filled as far as possible, depending on agv_state with:
;   AGS_PLAY	audio data, at the end of the data either continue at the
;		start (WHDLAUDF_LOOP) or switch to AGS_ENDFILL
;   AGS_ENDFILL	end fill bytes, required by the VS1063 to decode the last
;		data completely, they don't fit into the fifo at once and
;		are fed over multiple interrupts, at the end the interrupts
;		are disabled and WAUDIRQF_FINISHED is returned
;   other	nothing
; WAUDIRQF_FINISHED is returned when the last end fill byte is in the fifo,
; the audio data itself has already been passed to the decoder at this time
; on prefill the fifo is empty and the end fill bytes don't fit into it,
; therefore the finished state cannot be reached from amigus_play
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	d0 = ULONG WAUDIRQF_*
;	d1/a1 destroyed

amigusi_fill	movem.l	d3-d4/a2,-(a7)
		moveq	#0,d4			;D4 = rc
	;get free space in fifo in longs, the fifo has 2048 words and
	;FIFO_USAGE returns the words not yet passed to the VS1063,
	;therefore D3 is 0..1023 and a word counter is sufficient
	;the upper word of D3 is 0 because of the move.l
		move.l	#AGC_FIFO_WORDS-2,d3	;keep one long distance to the limit
		sub	(AGC_FIFO_USAGE,a0),d3	;FIFO words pending
		bls	.end			;fifo is full
		lsr	#1,d3			;D3 = free longs
		beq	.end
		lea	(AGC_FIFO_WRITE,a0),a2	;A2 = fifo, accepts long writes

	;fill until the fifo is full or nothing remains to feed
.loop		move	(agv_state,a3),d0
		cmp	#AGS_PLAY,d0
		beq	.play
		cmp	#AGS_ENDFILL,d0
		bne	.end			;AGS_IDLE or AGS_FINISHED

	;feed end fill bytes, agv_endcnt counts the remaining longs over
	;multiple calls
.endfill	move.l	(agv_endfill,a3),d1
.ef_loop	move.l	d1,(a2)
		subq.l	#1,(agv_endcnt,a3)
		beq	.ef_done
		subq	#1,d3
		bne	.ef_loop
		bra	.end			;fifo is full
	;all end fill bytes fed, disable interrupts (write without
	;AGCINTF_SET clears the enable bits), WHDLoad gets notified
.ef_done	move	#AGS_FINISHED,(agv_state,a3)
		move	#AGCINTF_USED,(AGC_INT_ENABLE,a0)
		moveq	#WAUDIRQF_FINISHED,d4
		bra	.end

	;feed audio data, the length is a multiple of 4 because amigus_play
	;rounds it up and WHDLoad clears the pad bytes
.play		move.l	(agv_ptr,a3),a1
		move.l	(agv_end,a3),d0
		sub.l	a1,d0			;D0 = remaining bytes, multiple of 4
		beq	.stream_end
		lsr.l	#2,d0			;remaining longs
	;copy min(remaining longs, free longs)
		cmp.l	d3,d0			;upper word of D3 is 0
		bls	.cnt
		move	d3,d0			;D0 <= 1023 because of the fifo size
.cnt		sub	d0,d3			;D3 = free longs left
		subq	#1,d0
.copy		move.l	(a1)+,(a2)
		dbf	d0,.copy
		move.l	a1,(agv_ptr,a3)
	;space left means the end of the audio data has been reached
		tst	d3
		bne	.loop
		bra	.end			;fifo is full

	;end of audio data reached
	;on loop continue directly at the start, the decoder gets a
	;continuous stream
.stream_end	btst	#WHDLAUDB_LOOP,(agv_flags+3,a3)
		beq	.noloop
		move.l	(agv_start,a3),(agv_ptr,a3)
		bra	.loop
	;without loop switch to feeding end fill bytes
.noloop		bsr	amigusi_getendfill
		move.l	#AGC_ENDFILLBYTES/4,(agv_endcnt,a3)
		move	#AGS_ENDFILL,(agv_state,a3)
		bra	.endfill

.end		move.l	d4,d0
		movem.l	(a7)+,_MOVEMREGS
		rts

;----------------------------------------
; stop fifo, disable and clear interrupts
; IN:	a0 = APTR codec base
; OUT:	-

amigusi_hwstop	move	#AGCINTF_ALL,(AGC_INT_ENABLE,a0)
		move	#0,(AGC_FIFO_CONTROL,a0)
		move	#AGCINTF_ALL,(AGC_INT_CONTROL,a0)
		move	d0,(AGC_FIFO_RESET,a0)	;strobe, value doesn't matter
		rts

;----------------------------------------
; stop the actual stream
; the decoder is always canceled, also in state AGS_FINISHED, because after
; the end fill bytes it may still be in the mode of the last format (e.g.
; WAV would play a following MP3 as PCM data, VS1063a datasheet 11.5.1)
; only the interrupts are disabled, the fifo continues because amigusi_cancel
; lets the decoder play the rest of the stream
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	-
;	d0-d1/a1 destroyed

amigusi_stop	tst	(agv_state,a3)
		beq	amigusi_hwstop		;AGS_IDLE, nothing to cancel
		move	#AGCINTF_ALL,(AGC_INT_ENABLE,a0)
		move	#AGCINTF_ALL,(AGC_INT_CONTROL,a0)
		bra	amigusi_cancel

;----------------------------------------
; finish decoding of the actual stream like at the end of a file (VS1063a
; datasheet 11.5.1), like the MHI driver of the AmiGUS does
; cancelling in the middle of a stream (datasheet 11.5.2) sometimes resulted
; in a following FLAC stream which has been detected but not decoded
;   1. send the remaining end fill bytes, 2052, FLAC 12288, in state
;      AGS_ENDFILL the rest, in state AGS_FINISHED none
;   2. wait until the fifo is drained, the decoder plays the rest of the
;      stream, this may take some time
;   3. set SM_CANCEL
;   4. send end fill bytes in blocks of 32 until SM_CANCEL is cleared, each
;      block is checked after the fifo is drained, at most 2048 bytes,
;      then check for about one second more (datasheet 11.5.2)
;   5. HDAT0 and HDAT1 must be 0 to indicate that no format is decoded
; if anything fails a software reset is performed
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	-
;	d0-d1/a1 destroyed

amigusi_cancel	move.l	d2,-(a7)
		addq.l	#1,(agv_stops,a3)
		move	#AGC_FIFO_DMA,(AGC_FIFO_CONTROL,a0)
	;remember format
		moveq	#SCI_HDAT1,d0
		bsr	amigusi_spiread
		bne	.spi
		move	d0,(agv_cfmt,a3)
	;get end fill bytes to send depending on the state
		move	(agv_state,a3),d0
		clr	(agv_state,a3)
		cmp	#AGS_ENDFILL,d0
		beq	.sendfill		;agv_endfill/agv_endcnt are set
		clr.l	(agv_endcnt,a3)
		cmp	#AGS_PLAY,d0
		bne	.sendfill		;AGS_FINISHED, all sent
		bsr	amigusi_getendfill
		move.l	#(VS_CANCELFILL+3)/4,d1
		cmp	#VS_HDAT1_FLAC,(agv_cfmt,a3)
		bne	.setcnt
		move.l	#AGC_ENDFILLBYTES/4,d1
.setcnt		move.l	d1,(agv_endcnt,a3)
	;send end fill bytes in blocks of 32 bytes
.sendfill	move.l	(agv_endcnt,a3),d2
		addq.l	#7,d2
		lsr.l	#3,d2			;blocks
		bra	.ef_next
.ef_loop	bsr	amigusi_fill32
		bne	.full
.ef_next	dbf	d2,.ef_loop
	;wait until the decoder has got everything
		bsr	amigusi_drain
		bne	.drain
	;set SM_CANCEL
		moveq	#SCI_MODE,d0
		bsr	amigusi_spiread
		bne	.spi
		or	#SM_CANCEL,d0
		move	d0,d1
		moveq	#SCI_MODE,d0
		bsr	amigusi_spiwrite
		bne	.spi
	;send end fill bytes until SM_CANCEL is cleared, each block is
	;checked after it has been transferred to the decoder
		move	#AGC_CANCELBYTES/32-1,d2
.loop		bsr	amigusi_fill32
		bne	.full
		bsr	amigusi_drain
		bne	.drain
		moveq	#SCI_MODE,d0
		bsr	amigusi_spiread
		bne	.spi
		and	#SM_CANCEL,d0
		beq	.canceled
		dbf	d2,.loop
	;not cleared after AGC_CANCELBYTES, check for about one second more
	;(datasheet 11.5.2)
		move.l	#AGC_CANCELWAIT,d2
.wait		moveq	#SCI_MODE,d0
		bsr	amigusi_spiread
		bne	.spi
		and	#SM_CANCEL,d0
		beq	.canceled
		subq.l	#1,d2
		bne	.wait
		addq.l	#1,(agv_restime,a3)
		lea	(amigus_rs_time,pc),a1
		bra	.reset
	;check that the decoder is idle
.canceled	moveq	#SCI_HDAT0,d0
		bsr	amigusi_spiread
		bne	.spi
		move	d0,d2
		moveq	#SCI_HDAT1,d0
		bsr	amigusi_spiread
		bne	.spi
		or	d0,d2
		bne	.hdat
		addq.l	#1,(agv_cancels,a3)
		bra	.end
	;decoder is not idle or cancel failed, perform software reset
.hdat		addq.l	#1,(agv_reshdat,a3)
		lea	(amigus_rs_hdat,pc),a1
		bra	.reset
.full		addq.l	#1,(agv_resfull,a3)
		lea	(amigus_rs_full,pc),a1
		bra	.reset
.drain		addq.l	#1,(agv_resdrain,a3)
		lea	(amigus_rs_drain,pc),a1
		bra	.reset
.spi		addq.l	#1,(agv_resspi,a3)
		lea	(amigus_rs_spi,pc),a1
.reset		bsr	amigusi_logreset
.end		move.l	(a7)+,d2
		bra	amigusi_hwstop

;----------------------------------------
; wait until the fifo is empty, all data have been transferred to the decoder
; IN:	a0 = APTR codec base
; OUT:	Z-flag set on success, cleared on timeout
;	d1 destroyed

amigusi_drain	move.l	#AGC_DRAINTIMEOUT,d1
.wait		tst	(AGC_FIFO_USAGE,a0)
		beq	.end
		subq.l	#1,d1
		bne	.wait
		moveq	#-1,d1			;Z-flag cleared
.end		rts

;----------------------------------------
; software reset after a failed cancel, the first AGC_RLOGSIZE resets are
; logged and traced on exit
; IN:	a0 = APTR codec base
;	a1 = CPTR reason
;	a3 = APTR vars
; OUT:	-
;	d0-d1/a1 destroyed

amigusi_logreset
		move.l	a2,-(a7)
		move.l	(agv_rlogcnt,a3),d0
		addq.l	#1,(agv_rlogcnt,a3)
		cmp.l	#AGC_RLOGSIZE,d0
		bhs	.nolog
		lea	(agv_rlog,a3),a2
		mulu	#rl_SIZEOF,d0
		add.l	d0,a2
		move.l	(agv_stops,a3),(rl_stop,a2)
		move.l	a1,(rl_reason,a2)
		moveq	#0,d0
		move	(agv_cfmt,a3),d0
		move.l	d0,(rl_fmt,a2)
		moveq	#SCI_MODE,d0
		bsr	amigusi_sciraw
		move.l	d0,(rl_mode,a2)
		bsr	amigusi_hwstop
		bsr	amigusi_reset
		move.l	d0,(rl_result,a2)
		moveq	#0,d0
		move	(AGC_SPI_STATUS,a0),d0
		move.l	d0,(rl_spistat,a2)
		bra	.end
.nolog		bsr	amigusi_hwstop
		bsr	amigusi_reset
.end		move.l	(a7)+,a2
		rts

;----------------------------------------
; software reset and init of the VS1063, load patches, set volume
; SM_RESET is written without waiting for DREQ, because DREQ stays low
; forever if the decoder hangs with a full stream buffer, then also all
; other SCI accesses fail with timeout
; the patches must be loaded after each reset, the codec is initialized
; before to load them with full clock and again after the patch start
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1/a1 destroyed

amigusi_reset	bsr	amigusi_spifree
		beq	.write
		moveq	#-1,d0
		rts
.write		moveq	#SCI_MODE,d0
		move	d0,(AGC_SPI_ADDRESS,a0)
		move	#SM_CLK_RANGE|SM_SDINEW|SM_RESET|SM_LAYER12,(AGC_SPI_WDATA,a0)
		move	d0,(AGC_SPI_WTRIGGER,a0)	;strobe, value doesn't matter
		bsr	amigusi_restartwait
		bne	.end
		bsr	amigusi_vsinit
		bne	.end
		bsr	amigusi_patch
		bne	.end
		bsr	amigusi_restartwait
		bne	.end
		bsr	amigusi_vsinit
		bne	.end
		bsr	amigusi_setvol
.end		rts

;----------------------------------------
; wait until the VS1063 has restarted after a reset or the start of the
; patches, DREQ goes low after at least 2 us and stays low for about 1.8 ms
; (datasheet 11.3), wait for low, then spiwait waits for high
; IN:	a0 = APTR codec base
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1 destroyed

amigusi_restartwait
		move	#1000-1,d1
.low		move	(AGC_SPI_STATUS,a0),d0
		btst	#AGCSPIB_VSBUSY,d0
		dbne	d1,.low
		moveq	#0,d0
		bsr	amigusi_spiwait		;preserves d0
		beq	.end
		moveq	#-1,d0
.end		rts

;----------------------------------------
; load the VS1063a patches package of VLSI, the last write to SCI_AIADDR
; starts the patches and restarts the system
; the data are compressed, each entry is: register, count, if count bit 15
; is set the next word is written count&$7fff times, otherwise count words
; follow which are written one after another
; IN:	a0 = APTR codec base
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1/a1 destroyed

amigusi_patch	movem.l	d2-d3/a2,-(a7)
		lea	(amigus_patches,pc),a2
		lea	(amigus_patches_end,pc),a1
.next		move	(a2)+,d2		;register
		move	(a2)+,d3		;count
		bclr	#15,d3
		beq	.copynext
	;run, write next word count times
		move	(a2)+,d1
		bra	.runnext
.run		move	d2,d0
		bsr	amigusi_spiwrite	;preserves d1
		bne	.end
.runnext	dbf	d3,.run
		bra	.check
	;copy, write count words
.copy		move	d2,d0
		move	(a2)+,d1
		bsr	amigusi_spiwrite
		bne	.end
.copynext	dbf	d3,.copy
.check		cmp.l	a1,a2
		blo	.next
		moveq	#0,d0
.end		movem.l	(a7)+,_MOVEMREGS
		rts

;----------------------------------------
; write 32 end fill bytes into the fifo, wait for space before
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1 destroyed

amigusi_fill32	move.l	#AGC_SPITIMEOUT,d1
.wait		cmp	#AGC_FIFO_WORDS-32/2-2,(AGC_FIFO_USAGE,a0)
		bls	.space
		subq.l	#1,d1
		bne	.wait
		moveq	#-1,d0			;fifo is not drained, decoder hangs
		rts
.space		move.l	(agv_endfill,a3),d1
		moveq	#32/4-1,d0
.fill		move.l	d1,(AGC_FIFO_WRITE,a0)
		dbf	d0,.fill
		moveq	#0,d0
		rts

;----------------------------------------
; read end fill byte and build end fill pattern
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	-
;	d0-d1 destroyed

amigusi_getendfill
		move	#VS_ENDFILL,d1
		moveq	#SCI_WRAMADDR,d0
		bsr	amigusi_spiwrite
		moveq	#SCI_WRAM,d0
		bsr	amigusi_spiread
		beq	.ok
		moveq	#0,d0
.ok		move.b	d0,d1
		lsl	#8,d1
		move.b	d0,d1
		move	d1,d0
		swap	d1
		move	d0,d1
		move.l	d1,(agv_endfill,a3)
		rts

;----------------------------------------
; init VS1063 decoder
; IN:	a0 = APTR codec base
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1 destroyed

amigusi_vsinit	move	#SM_CLK_RANGE|SM_SDINEW|SM_LAYER12,d1
		moveq	#SCI_MODE,d0
		bsr	amigusi_spiwrite
		bne	.end
		move	#SC_MULT_5_0X,d1
		moveq	#SCI_CLOCKF,d0
		bsr	amigusi_spiwrite
		bne	.end
	;enable I2S interface at 192 kHz
		move	#VS_GPIO_DDR,d1
		move	#VS_GPIO_DDR_I2S,d0
		bsr	amigusi_memwrite
		bne	.end
		move	#VS_I2S_CONFIG,d1
		moveq	#0,d0			;reset
		bsr	amigusi_memwrite
		bne	.end
		move	#VS_I2S_CONFIG,d1
		moveq	#VS_I2S_CONFIG_192K,d0
		bsr	amigusi_memwrite
.end		rts

;----------------------------------------
; set volume
; IN:	a0 = APTR codec base
;	a3 = APTR vars
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1 destroyed

amigusi_setvol	move	(agv_volume,a3),d1
		moveq	#SCI_VOL,d0
		bra	amigusi_spiwrite

;----------------------------------------
; write VS1063 memory
; IN:	d0 = UWORD value
;	d1 = UWORD address
;	a0 = APTR  codec base
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly
;	d1 destroyed

amigusi_memwrite
		move.l	d0,-(a7)
		moveq	#SCI_WRAMADDR,d0
		bsr	amigusi_spiwrite
		move.l	(a7)+,d1
		tst.l	d0
		bne	.end
		moveq	#SCI_WRAM,d0
		bsr	amigusi_spiwrite
.end		rts

;----------------------------------------
; write SCI register
; IN:	d0 = UWORD register
;	d1 = UWORD value
;	a0 = APTR  codec base
; OUT:	d0 = LONG 0 = success, Z-flag set accordingly

amigusi_spiwrite
		bsr	amigusi_spiwait
		bne	.timeout
		move	d0,(AGC_SPI_ADDRESS,a0)
		move	d1,(AGC_SPI_WDATA,a0)
		move	d0,(AGC_SPI_WTRIGGER,a0)	;strobe, value doesn't matter
		moveq	#0,d0
		rts
.timeout	moveq	#-1,d0
		rts

;----------------------------------------
; read SCI register
; IN:	d0 = UWORD register
;	a0 = APTR  codec base
; OUT:	d0 = UWORD value (upper word undefined), Z-flag set on success
;	d1 destroyed

amigusi_spiread	bsr	amigusi_spiwait
		bne	.timeout
		move	d0,(AGC_SPI_ADDRESS,a0)
		move	d0,(AGC_SPI_RTRIGGER,a0)	;strobe, value doesn't matter
		bsr	amigusi_spiwait
		bne	.timeout
		move	(AGC_SPI_RDATA,a0),d0
		cmp	d0,d0			;set Z-flag
		rts
.timeout	moveq	#-1,d0
		rts

;----------------------------------------
; read SCI register without waiting for DREQ, only for diagnostics
; IN:	d0 = UWORD register
;	a0 = APTR  codec base
; OUT:	d0 = ULONG value, -1 on timeout
;	d1 destroyed

amigusi_sciraw	bsr	amigusi_spifree
		bne	.timeout
		move	d0,(AGC_SPI_ADDRESS,a0)
		move	d0,(AGC_SPI_RTRIGGER,a0)	;strobe, value doesn't matter
		bsr	amigusi_spifree
		bne	.timeout
		moveq	#0,d0
		move	(AGC_SPI_RDATA,a0),d0
		rts
.timeout	moveq	#-1,d0
		rts

;----------------------------------------
; wait until spi is ready, ignore vs1063 busy (DREQ)
; IN:	a0 = APTR codec base
; OUT:	Z-flag set on success, cleared on timeout
;	d1 destroyed

amigusi_spifree	move.l	#AGC_SPITIMEOUT,d1
.wait		tst	(AGC_SPI_STATUS,a0)	;bit15 = spi busy
		bpl	.ready
		subq.l	#1,d1
		bne	.wait
		moveq	#-1,d1			;Z-flag cleared
		rts
.ready		moveq	#0,d1			;Z-flag set
		rts

;----------------------------------------
; wait until spi and vs1063 are ready
; IN:	a0 = APTR codec base
; OUT:	Z-flag set on success, cleared on timeout
;	d0/d1 preserved

amigusi_spiwait	movem.l	d0-d1,-(a7)
		move.l	#AGC_SPITIMEOUT,d1
.wait		move	(AGC_SPI_STATUS,a0),d0
		and	#AGC_SPI_BUSY,d0	;Z-flag set if ready
		beq	.end
		subq.l	#1,d1
		bpl	.wait			;on timeout d1 = -1, Z-flag cleared
.end		movem.l	(a7)+,_MOVEMREGS	;movem doesn't change flags
		rts

;----------------------------------------

amigus_name		dc.b	"AmiGUS",0
amigus_libname		dc.b	"amigus.library",0
amigus_exts		dc.b	"mp3",0,"ogg",0,"flac",0,"wav",0,"aac",0,"m4a",0,"wma",0,0
amigus_trc_nolib	dc.b	"AmiGUS: amigus.library not found",0
amigus_trc_nocard	dc.b	"AmiGUS: no card found",0
amigus_trc_card		dc.b	"AmiGUS: card '%s' type=$%x hwrev=$%lx fwrev=$%lx fwdate=%d-%02d-%02d %02d:%02d codec=$%lx pcm=$%lx",0
amigus_trc_type		dc.b	"AmiGUS: unknown card type",0
amigus_trc_gayle	dc.b	"AmiGUS: mini, Gayle inten=$%lx",0
amigus_trc_inuse	dc.b	"AmiGUS: codec is in use (error=$%lx)",0
amigus_trc_ok		dc.b	"AmiGUS: codec initialized, VS1063a patches 2.6 loaded",0
amigus_trc_vsfail	dc.b	"AmiGUS: VS1063 codec is not responding (spi status=$%lx mode=$%lx status=$%lx hdat0=$%lx hdat1=$%lx)",0
amigus_trc_noacc	dc.b	"AmiGUS: codec registers not accessible (spi status=$%lx), card config may be invalid",0
amigus_trc_stat		dc.b	"AmiGUS: decoder cancels=%ld resets: spi=%ld full=%ld drain=%ld timeout=%ld hdat=%ld",0
amigus_trc_rlog		dc.b	"AmiGUS: reset at stop %ld reason=%s fmt=$%lx mode=$%lx result=%ld spi status=$%lx",0
amigus_rs_spi		dc.b	"spi",0
amigus_rs_full		dc.b	"full",0
amigus_rs_drain		dc.b	"drain",0
amigus_rs_time		dc.b	"timeout",0
amigus_rs_hdat		dc.b	"hdat",0
amigus_err_vs		dc.b	"AmiGUS: VS1063 codec is not responding",0
amigus_err_noacc	dc.b	"AmiGUS: codec registers not accessible, card config may be invalid (check with AmiGUS flash tool)",0
amigus_err_inuse	dc.b	"AmiGUS: codec is in use by another program",0
	EVEN

;----------------------------------------
; VS1063a patches package 2.6 (2025-10-09) of VLSI Solution, from
; https://www.vlsi.fi/en/support/software/vs10xxpatches.html
; vs1063a-patches.plg converted into big endian words (UWORD plugin[])

amigus_patches		INCBIN	"vs1063a-patches.bin"
amigus_patches_end

