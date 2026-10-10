;*---------------------------------------------------------------------------
;  :Program.	snoopspeed.asm
;  :Contents.	Slave to benchmark the paths of the WHDLoad access fault
;		handler which are used to snoop accesses to custom and cia
;		registers, the normal memory performance is not measured,
;		see speed.asm for that
;  :Author.	Wepl
;  :History.	08.10.26 started, derived from speed.asm
;  :Requires.	WHDLoad v18, MMU
;  :Copyright.	Public Domain
;  :Language.	68020 Assembler
;  :Translator.	vasm, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*
; every line of the result shows how often one access could be performed
; within the test period and how long one access took, the paths are
; selected by the register which is accessed:
;
;	the read paths only fault if the custom page is invalid, that is
;	SnoopOCS/ECS/AGA, with Snoop/S the page is readable and the
;	accesses are not snooped at all
;
;	the write paths without a callback are the cheapest ones, since
;	WHDLoad 20.1 the 68060 handler completes them itself instead of
;	restarting the faulted instruction, the movem line uses the same
;	register and operand size but is still restarted, so both lines
;	together show what the completion saves
;
;	the write paths with a callback add the costs of the callback,
;	cop1lc and dmacon with the copper bit set walk the copperlist,
;	therefore both are measured with a short and a long one
;
;	the cia accesses are snooped in every snoop mode, the cia pages
;	are write protected but readable, so only writes fault
;
;	the last two groups are not snooped and are the reference for
;	everything above, chip memory is mapped noncachable serialized,
;	which is required for precise access faults, the slave is cachable
;
; the blitter checks (ChkBltSize/ChkBltWait) are not covered because every
; access which reaches them starts a blit, which would both disturb the
; measurement by dma contention and terminate on the blitter wait check
;
; the copcon path requires the copcon check, which the slave enables itself
;
; the stack is in basemem by default, which the mmu maps noncachable
; serialized, with the option Custom3 it is moved into expmem, which is
; mapped cachable copyback, that shows in every path which pushes an
; exception frame
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY

	OUTPUT	"ram:snoopspeed.slave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER

	ENDC

	MC68020

EXPMEMLEN	= $1000			;expmem, used as stack

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	18
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
		dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEMLEN		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Snoop Speed Benchmark Slave",0
_copy		dc.b	"2026 Wepl",0
_info		dc.b	"done by Wepl "
	INCBIN	.date
		dc.b	0
_config		dc.b	"C1:B:Run in Usermode;"
		dc.b	"C2:L:Test period:1/11s,1s,2s,10s;"
		dc.b	"C3:B:Use the stack in expmem",0
	EVEN

;======================================================================

SCREENWIDTH	= 320
SCREENHEIGHT	= 279
CHARHEIGHT	= 5
CHARWIDTH	= 5

COPFILL		= 100			;fillers in the long copperlist
COPSHORT	= (_copper_end-_copper)/4	;instructions in the short copperlist
COPLONG		= COPSHORT+COPFILL	;instructions in the long copperlist

;all variables are located in basemem below $8000, so that they can be
;accessed with absolute short addressing and the slave stays free of
;relocations, they are cleared by WHDLF_ClearMem and none of them is touched
;within a measured loop

	STRUCTURE Globals,$1000
		LONG	_logptr		;next byte to write
		LONG	_logmax		;end of the log, the highest _logptr
		LONG	_logname	;name of the test, 1st argument of _logline
		LONG	_loggap		;flag, a group separator is pending
		LONG	_loops		;additional periods to measure
		LONG	_period		;1/100 us of the whole test period
		STRUCT	_args1,3*4	;periods and the enabled options, the
					;arguments of _top1
		STRUCT	_args2,6*2+5*4	;day,month,year,hour,min,sec and
					;attnflags,eclock,version,revision,build
					;are the arguments of _top2
		STRUCT	_filename,32	;name of the text file
		LABEL	_filename_end
		STRUCT	_hdr,320	;header of the text file
		LABEL	_hdrend
		STRUCT	_logbuf,4096	;the measured lines as text
		LABEL	_logend
	;the memory used by the display and by the reference tests, unlike the
	;variables above it is accessed within the measured loops
		LONG	_memchip	;not snooped reference
		STRUCT	_copshort,COPSHORT*4	;copperlist driving the display
		STRUCT	_coplong,COPLONG*4	;the same plus COPFILL fillers
		STRUCT	_screen,SCREENHEIGHT*SCREENWIDTH/8

RESX		= 34*CHARWIDTH		;column of the results
LOGIND		= 2			;chars the lines are indented on the
					;screen to have room for the marker of
					;the copperlist check, the log does not
					;contain the marker and is not indented
TOPY		= 4*(CHARHEIGHT+1)	;first line of the results

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_ciaa),a4		;A4 = ciaa
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = custom

	;init gfx
		lea	(_copper),a0
		lea	(_copshort),a1
		move.l	a1,(cop1lc,a6)
.n		move.l	(a0)+,(a1)+
		bpl	.n

		waitvb a6
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER,(dmacon,a6)

	;build the long copperlist, same display setup plus fillers
		lea	(_copper),a0
		lea	(_coplong),a1
.n2		move.l	(a0)+,(a1)+
		bpl	.n2
		subq.l	#4,a1			;overwrite the end marker
		move.w	#COPFILL-1,d0
.n3		move.l	#(color+2)<<16+$ddd,(a1)+
		dbf	d0,.n3
		move.l	#-2,(a1)

	;let cop2lc point to the end marker of the display list, so that the
	;strobe of copjmp2 only makes the copper wait and leaves the display,
	;which is set up at the begin of the list, untouched
		move.l	#_copshort+(_copper_end-_copper-4),(cop2lc,a6)

	;get informations, enable the copcon check to get that path snooped
		lea	(_tags),a0
		jsr	(resload_Control,a5)

	;build the arguments of the header line _top2
		move.l	(_time),a0
		lea	(_args2),a1
		moveq	#0,d0
		move.b	(whdlt_day,a0),d0
		move.w	d0,(a1)+
		move.b	(whdlt_month,a0),d0
		move.w	d0,(a1)+
		move.b	(whdlt_year,a0),d0
		move.w	d0,(a1)+
		move.b	(whdlt_hour,a0),d0
		move.w	d0,(a1)+
		move.b	(whdlt_min,a0),d0
		move.w	d0,(a1)+
		move.b	(whdlt_sec,a0),d0
		move.w	d0,(a1)+
		move.l	(_attn),(a1)+
		move.l	(_freq),(a1)+
		move.l	(_ver),(a1)+
		move.l	(_rev),(a1)+
		move.l	(_build),(a1)+

	;build the name of the text file, it contains only the date, so that
	;all runs of a day are appended to the same file
		move.b	(whdlt_day,a0),d0
		move	d0,-(a7)
		move.b	(whdlt_month,a0),d0
		move	d0,-(a7)
		move.b	(whdlt_year,a0),d0
		move	d0,-(a7)
		move.l	a7,a2				;args
		moveq	#_filename_end-_filename,d0	;buflen
		lea	(_filename),a0			;buffer
		lea	(_filename_fmt),a1		;format
		jsr	(resload_VSNPrintF,a5)
		add.w	#3*2,a7

	;init timers
		move.l	(_freq),d0
		divu	#11,d0
		move.b	d0,(ciatalo,a4)
		lsr.w	#8,d0
		move.b	d0,(ciatahi,a4)
		move.b	#CIACRAF_RUNMODE,(ciacra,a4)
		bset	#CIACRAB_LOAD,(ciacra,a4)
		move.b	#$7f,(ciaicr,a4)
		move.b	#CIAICRF_SETCLR|CIAICRF_TA,(ciaicr,a4)
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena,a6)
		tst.b	(ciaicr,a4)
		move.w	#INTF_PORTS,(intreq,a6)

	;set extra loops, _loops+1 periods of 1/11s are measured
		move.l	(_custom2),d0
		beq	.nc2
		moveq	#11-1,d1
		subq.l	#1,d0
		beq	.sc2
		moveq	#22-1,d1
		subq.l	#1,d0
		beq	.sc2
		moveq	#110-1,d1
		subq.l	#1,d0
		bne	.nc2
.sc2		move.l	d1,(_loops)
.nc2
	;microseconds*100 within the test period, used to get us per access
		move.l	(_loops),d0
		addq.l	#1,d0
		move.l	d0,(_args1)		;periods
		mulu.l	#100*1000000/11,d0
		move.l	d0,(_period)

	;the enabled options are named in the header line _top1, for a zero
	;pointer %s prints nothing
		sub.l	a0,a0
		tst.l	(_custom1)
		beq	.no1
		lea	(_o_usermode),a0
.no1		move.l	a0,(_args1+4)
		sub.l	a0,a0
		tst.l	(_custom3)
		beq	.no3
		lea	(_o_expmem),a0
.no3		move.l	a0,(_args1+8)

	;print header
		moveq	#0,d0			;x
		moveq	#0,d1			;y
		lea	(_top1),a0
		lea	(_args1),a1
		bsr	_ps

		moveq	#0,d0			;x
		add.w	#CHARHEIGHT+1,d1	;y
		lea	(_top2),a0
		lea	(_args2),a1
		bsr	_ps

		moveq	#0,d0			;x
		add.w	#2*(CHARHEIGHT+1),d1	;y, leaves one line empty
		lea	(_top3),a0
		bsr	_ps

	;print legend and quit line below the table
		moveq	#0,d0
		move.w	#SCREENHEIGHT-CHARHEIGHT-2*(CHARHEIGHT+1),d1
		lea	(_leg1),a0
		bsr	_ps

		moveq	#0,d0
		add.w	#CHARHEIGHT+1,d1
		lea	(_leg2),a0
		pea	COPLONG
		pea	COPSHORT
		move.l	a7,a1
		bsr	_ps
		addq.l	#8,a7

		moveq	#0,d0
		move.w	#SCREENHEIGHT-CHARHEIGHT,d1
		lea	(_quit),a0
		bsr	_ps

	;use the stack in expmem, basemem is mapped noncachable serialized
	;while expmem is mapped cachable copyback
		move.l	(_custom3),d0
		beq	.nc3
		move.l	(_expmem),a7
		add.l	#EXPMEMLEN-$200,a7	;because hrtmon
.nc3
	;switch to usermode
		move.l	(_custom1),d0
		beq	.nc1
		lea	(-$400,a7),a0
		move	a0,usp
		move	#0,sr
.nc1
	;run the tests until the left mouse button is held
.again		bsr	_tests
		btst	#6,($bfe001)
		bne	.again

	;the output is appended to the file of the day, if it does not exist
	;resload_GetFileSize returns zero
		lea	(_filename),a0
		jsr	(resload_GetFileSize,a5)
		move.l	d0,d3			;D3 = offset to write at

	;build the header, it is the same as on the screen followed by an
	;empty line, _hs appends one formatted line to it
		lea	(_hdr),a0
		lea	(_top1),a1		;format
		lea	(_args1),a2		;args
		bsr	_hs

		lea	(_args2),a2		;args
		lea	(_top2),a1		;format
		bsr	_hs

		move.b	#10,(a0)+		;an empty line

		lea	(_top3+LOGIND),a1	;format, without the indentation
		bsr	_hs

	;save the header
		move.l	a0,d0
		lea	(_hdr),a1		;data
		sub.l	a1,d0			;size
		move.l	d3,d1			;offset
		add.l	d0,d3
		lea	(_filename),a0		;name
		jsr	(resload_SaveFileOffset,a5)

	;save the measured lines plus an empty line
		move.l	(_logmax),a0
		move.b	#10,(a0)+
		lea	(_logbuf),a1		;data
		move.l	a0,d0
		sub.l	a1,d0			;size
		move.l	d3,d1			;offset
		lea	(_filename),a0		;name
		jsr	(resload_SaveFileOffset,a5)

	;end
		pea	TDREASON_OK
		jmp	(resload_Abort,a5)

;======================================================================
; measurement
;
; the loop is aborted by the cia timer a interrupt, which is vectored to
; the end of the loop, there CALC_E either restarts the timer for the next
; period or returns to the instruction after the loop
;
; d1.w	line
; d2.l	amount of performed accesses
; d4.w	remaining periods

CALC_S	MACRO
		move.l	(_loops),d4
		moveq	#0,d2
		pea	\1			;stop address
		move.l	(a7)+,$68
	CNOP 2,4
		bset	#CIACRAB_START,(ciacra,a4)
	ENDM

CALC_E	MACRO
		btst	#CIAICRB_TA,(ciaicr,a4)
		beq	_badint
		subq.w	#1,d4
		bmi	.quit\@
		move.w	#INTF_PORTS,(intreq,a6)
		bset	#CIACRAB_START,(ciacra,a4)
		rte
.quit\@		move.w	#INTF_PORTS,(intreq,a6)
		tst.w	(dmaconr,a6)		;delay for intack
		lea	.back\@,a1
		move.l	a1,(2,a7)
		rte
.back\@
	ENDM

; the gap between two groups of tests, in the text log the empty line is
; written in front of the next measured line, so that a round which is
; aborted here does not leave a separator at the end of the log

GAP	MACRO
		addq.w	#2,d1			;y, group separator
		st	(_loggap)
	ENDM

; \1 = name of the test
; \2 = the access to be measured, enclosed in <>

SNOOP	MACRO
		btst	#6,($bfe001)
		beq	.quit
		moveq	#0,d0			;x
		add.w	#CHARHEIGHT+1,d1	;y
		lea	\1,a0
		bsr	_psn
		CALC_S	.go\@
.loop\@		\2
		\2
		\2
		\2
		\2
		\2
		\2
		\2
		addq.l	#8,d2
		bra	.loop\@
.go\@		CALC_E
		bsr	_pr
	ENDM

;======================================================================

	;the log holds the measured lines only, every round overwrites them in
	;place, so a round which is aborted keeps the lines of the one before,
	;that works because all lines have the same length, _logmax is the end
	;of the longest round and therefore the end of the log
_tests		lea	(_logbuf),a0
		move.l	a0,(_logptr)
		clr.b	(_loggap)

		move.w	#TOPY-(CHARHEIGHT+1),d1
		move.w	#$1200,d7		;value written, harmless everywhere
		lea	(_memchip),a2		;not snooped reference in basemem
		lea	(_memslave,pc),a3	;not snooped reference in the slave

	;reads of custom, only snooped if the page is invalid
		SNOOP	_t_r_b_vposr,<move.b (vposr,a6),d5>
		SNOOP	_t_r_w_vposr,<move.w (vposr,a6),d5>
		SNOOP	_t_r_l_vposr,<move.l (vposr,a6),d5>
		SNOOP	_t_r_w_dmaconr,<move.w (dmaconr,a6),d5>
		SNOOP	_t_r_w_copjmp,<move.w (copjmp2,a6),d5>

	;writes of custom without a callback
		GAP
		SNOOP	_t_w_b_audvol,<move.b d7,(aud0+ac_vol+1,a6)>
		SNOOP	_t_w_w_color,<move.w d7,(color+4,a6)>
		SNOOP	_t_w_l_color,<move.l d7,(color+4,a6)>
		SNOOP	_t_w_m_color,<movem.l d7,(color+4,a6)>

	;writes of custom with a callback
		GAP
		SNOOP	_t_w_w_bplcon0,<move.w d7,(bplcon0,a6)>
		SNOOP	_t_w_l_bplpt,<move.l a2,(bplpt+4,a6)>
		SNOOP	_t_w_w_copjmp,<move.w d7,(copjmp2,a6)>
		SNOOP	_t_w_w_copcon,<move.w #0,(copcon,a6)>
		SNOOP	_t_w_w_dmacon,<move.w #DMAF_AUD0,(dmacon,a6)>
	;the copperlist walked on a dmacon write is the one of the last cop1lc
	;write, therefore the long list is measured first and the short one last,
	;that way every round walks the same list on the dmacon write
		SNOOP	_t_w_l_cop1lcl,<move.l #_coplong,(cop1lc,a6)>
		SNOOP	_t_w_l_cop1lc,<move.l #_copshort,(cop1lc,a6)>
		SNOOP	_t_w_w_dmacop,<move.w #DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)>

	;accesses of cia, snooped in every snoop mode
		GAP
		SNOOP	_t_w_b_ciatod,<move.b d7,(ciatodlow,a4)>
		SNOOP	_t_w_b_ciaicr,<move.b #0,(ciaicr,a4)>
		SNOOP	_t_r_b_ciapra,<move.b (ciapra,a4),d5>

	;not snooped reference, chip memory is mapped noncachable serialized
	;while the slave is cachable, so both show different speeds
		GAP
		SNOOP	_t_w_w_chip,<move.w d7,(a2)>
		SNOOP	_t_w_l_chip,<move.l d7,(a2)>
		SNOOP	_t_r_w_chip,<move.w (a2),d5>
		SNOOP	_t_r_l_chip,<move.l (a2),d5>

		GAP
		SNOOP	_t_w_w_slv,<move.w d7,(a3)>
		SNOOP	_t_w_l_slv,<move.l d7,(a3)>
		SNOOP	_t_r_w_slv,<move.w (a3),d5>
		SNOOP	_t_r_l_slv,<move.l (a3),d5>

	;keep the end of the longest round as the end of the log
.quit		move.l	(_logptr),d0
		cmp.l	(_logmax),d0
		bls	.q
		move.l	d0,(_logmax)
.q		rts

_badint		move.w	#INTF_PORTS,(intreq,a6)
		move.w	#$f00,(color,a6)	;signal unexpected int & delay for intack
		rte

;--------------------------------
; print one result, the amount of accesses and the time per access
; IN:	d1 = word y
;	d2 = long amount of accesses

_pr		movem.l	d0-d3/a0-a2,-(a7)
		moveq	#0,d0
		moveq	#0,d3
		tst.l	d2
		beq	.zero
		move.l	(_period),d0		;1/100 us of the test period
		divu.l	d2,d0			;1/100 us per access
		divul.l	#100,d3:d0		;D0 = us, D3 = 1/100 us
.zero		move.l	d3,-(a7)
		move.l	d0,-(a7)
		move.l	d2,-(a7)
		move.l	a7,a1			;args
		move.w	#RESX,d0
		lea	(_res),a0
		bsr	_ps

	;append the whole line to the text log, the name of the test is taken
	;without the indentation for the marker of the copperlist check
		move.l	(_logname),a0
		pea	(LOGIND,a0)		;1st argument
		move.l	a7,a2			;args
		lea	(_logline),a1		;format
		move.l	(_logptr),a0		;buffer
		tst.b	(_loggap)
		beq	.nogap
		clr.b	(_loggap)
		move.b	#10,(a0)+		;the pending group separator
.nogap		move.l	#_logend,d0
		sub.l	a0,d0			;buflen
		jsr	(resload_VSNPrintF,a5)
		move.b	#10,(a0)+		;replaces the terminating zero
		move.l	a0,(_logptr)

		add.w	#4*4,a7
		movem.l	(a7)+,d0-d3/a0-a2
		rts

;--------------------------------
; print a formatted string on the screen
; IN:	d0 = word x
;	d1 = word y
;	a0 = cptr format
;	a1 = aptr args
; OUT:	d0 = word new x

	;_psn additionally remembers the string for the text log
_psn		move.l	a0,(_logname)

_ps		movem.l	d0-d2/a2,-(a7)
		moveq	#100,d0			;buflen
		sub.l	d0,a7
		move.l	a1,a2			;args
		move.l	a0,a1			;fmt
		move.l	a7,a0			;buffer
		jsr	(resload_VSNPrintF,a5)
		movem.l	(100,a7),d0-d1
		move.l	a7,a0
		moveq	#0,d2
		bra	.in
.next		bsr	_pc
		add.w	#CHARWIDTH,d0
.in		move.b	(a0)+,d2
		bne	.next
		add.w	#104,a7
		movem.l	(a7)+,d1-d2/a2
		rts

;--------------------------------
; print char
; IN:	d0 = word x
;	d1 = word y
;	d2 = ascii char

_pc		movem.l	d0-d5/a0-a1,-(a7)
		lea	(_screen),a0
		mulu	#SCREENWIDTH/8,d1
		add.l	d1,a0
		sub.w	#32,d2				;starts at $20
		mulu	#CHARWIDTH,d2
		lea	(_font),a1
		moveq	#CHARHEIGHT-1,d3
.cp		bfextu	(a1){d2:CHARWIDTH},d1
		bfins	d1,(a0){d0:CHARWIDTH}
		add.l	#(_font_end-_font)*8/CHARHEIGHT,d2
		add.l	#SCREENWIDTH,d0
		dbf	d3,.cp
		movem.l	(a7)+,d0-d5/a0-a1
		rts

;--------------------------------
; append one formatted line to the header of the text file
; IN:	a0 = aptr write position
;	a1 = cptr format
;	a2 = aptr args
; OUT:	a0 = aptr behind the appended line feed

_hs		move.l	#_hdrend,d0
		sub.l	a0,d0				;buflen
		jsr	(resload_VSNPrintF,a5)
		move.b	#10,(a0)+			;replaces the terminating zero
		rts

;======================================================================

_tags		dc.l	WHDLTAG_CHKCOPCON	;to get the copcon path snooped
		dc.l	-1
		dc.l	WHDLTAG_ECLOCKFREQ_GET
_freq		dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attn		dc.l	0
		dc.l	WHDLTAG_VERSION_GET
_ver		dc.l	0
		dc.l	WHDLTAG_REVISION_GET
_rev		dc.l	0
		dc.l	WHDLTAG_BUILD_GET
_build		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_custom3	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
		dc.l	TAG_DONE

	;the field width of the name must match RESX/CHARWIDTH-LOGIND
_logline	dc.b	"%-32s"
_res		dc.b	"%9ld  %6ld.%02ld",0
_t_r_b_vposr	dc.b	"  read  byte  vposr",0
_t_r_w_vposr	dc.b	"  read  word  vposr",0
_t_r_l_vposr	dc.b	"  read  long  vposr",0
_t_r_w_dmaconr	dc.b	"  read  word  dmaconr",0
_t_r_w_copjmp	dc.b	"  read  word  copjmp2",0
_t_w_b_audvol	dc.b	"  write byte  aud0.vol",0
_t_w_w_color	dc.b	"  write word  color2",0
_t_w_l_color	dc.b	"  write long  color2",0
_t_w_m_color	dc.b	"  write long  color2 movem",0
_t_w_w_bplcon0	dc.b	"  write word  bplcon0",0
_t_w_l_bplpt	dc.b	"  write long  bpl2pt",0
_t_w_w_copjmp	dc.b	"  write word  copjmp2",0
_t_w_w_copcon	dc.b	"  write word  copcon",0
_t_w_w_dmacon	dc.b	"  write word  dmacon",0
_t_w_w_dmacop	dc.b	"* write word  dmacon copper short",0
_t_w_l_cop1lc	dc.b	"* write long  cop1lc short",0
_t_w_l_cop1lcl	dc.b	"* write long  cop1lc long",0
_t_w_b_ciatod	dc.b	"  write byte  ciaa.todlow (emul)",0
_t_w_b_ciaicr	dc.b	"  write byte  ciaa.icr (save+cb)",0
_t_r_b_ciapra	dc.b	"  read  byte  ciaa.pra",0
_t_w_w_chip	dc.b	"  write word  chipmem",0
_t_w_l_chip	dc.b	"  write long  chipmem",0
_t_r_w_chip	dc.b	"  read  word  chipmem",0
_t_r_l_chip	dc.b	"  read  long  chipmem",0
_t_w_w_slv	dc.b	"  write word  slave",0
_t_w_l_slv	dc.b	"  write long  slave",0
_t_r_w_slv	dc.b	"  read  word  slave",0
_t_r_l_slv	dc.b	"  read  long  slave",0
	EVEN

_font		INCBIN	pic_font_5x6_br.bin
_font_end

_copper		dc.w	diwstrt,$1a81
		dc.w	diwstop,$1ac1+((SCREENHEIGHT-256)*$100)
		dc.w	bplcon0,$1200
		dc.w	bplpt+0,_screen>>16
		dc.w	bplpt+2,_screen&$ffff
		dc.w	bpl1mod,0
		dc.w	color+0,0
		dc.w	color+2,$ddd
		dc.l	-2
_copper_end

_filename_fmt	dc.b	"snoopspeed-%02d%02d%02d.txt",0
	;the lines must stay below 64 chars to fit on the screen
_top1		dc.b	">>snoopspeed<< - us per access within %ld/11 s%s%s",0
_o_usermode	dc.b	" usermode",0
_o_expmem	dc.b	" expmem",0
_top2		dc.b	"%02d.%02d.%02d %02d:%02d:%02d  Attn=$%lx  Eclock=%ld  whdload=%ld.%ld.%ld",0
_top3		dc.b	"  path                             accesses  us/access",0
_leg1		dc.b	"* makes the copperlist check walk the list",0
_leg2		dc.b	"  short copperlist %ld instructions, long %ld",0
_quit		dc.b	"hold lmb to quit and save text  v1.0 wepl "
	INCBIN	.date
		dc.b	0
	EVEN

	CNOP 0,4
_memslave	dx.l	1		;accessed by the reference tests

;======================================================================

	END
