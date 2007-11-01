;*---------------------------------------------------------------------------
;  :Program.	GenericKick.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DEBUG
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH

;============================================================================

BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Generic KickStarter "
	IFEQ	KICKSIZE-$40000
	dc.b	"34.005"
	ELSE
	dc.b	"40.068"
	ENDC
		dc.b	0
_copy		dc.b	"19xx Any Company",0
_info		dc.b	"by JOTD using Wepl kick13 sources",10,10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data:
	dc.b	"data",0

STR_BUF_SIZE = 54

_custom_buffer
	blk.b	STR_BUF_SIZE*2,0
_program:
	blk.b	STR_BUF_SIZE,0
_args
	blk.b	STR_BUF_SIZE,0
	even
_arglen
	dc.l	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

_bootdos
	clr.l	$0.W

	IFEQ	KICKSIZE-$40000
	bsr	_patchkb
	ENDC

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

		lea	_custom_buffer(pc),a0

		move.l	#STR_BUF_SIZE*2,d0
		moveq.l	#0,d1
		jsr	(resload_GetCustom,a2)

	;copy program

		lea	_custom_buffer(pc),a0
		tst.b	(a0)
		beq	_quit

		lea	_program(pc),a1
.copyprog
		move.b	(a0)+,(a1)+
		beq.b	.argsdone
		cmp.b	#' ',(-1,a0)
		beq.b	.progdone
		bra.b	.copyprog
.progdone
		; space found, there are arguments

		clr.b	(-1,a0)

.skipspc
		cmp.b	#' ',(a0)+
		beq.b	.skipspc
		subq.l	#1,a0

		lea	_args(pc),a1
.copyargs
		move.b	(a0)+,(a1)+
		bne.b	.copyargs

.argsdone
	;get arg length
		lea	_args(pc),a0
		move.l	a0,a1
.loop
		tst.b	(a0)+
		bne.b	.loop
		move.b	#10,-1(a0)
		sub.l	a1,a0
		lea	_arglen(pc),a1
		move.l	a0,(a1)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		move.l	_arglen(pc),d0
		moveq	#0,D1
		move.l	#4000,D2
		move.l	#4008,D3
		moveq	#1,D4
		moveq	#0,D5
		moveq	#0,D6
		moveq	#0,D7
		sub.l	A2,A2
		sub.l	A3,A3
		sub.l	A4,A4
		sub.l	A5,A5
		sub.l	A6,A6
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

_quit
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
		pea	_program(pc)
		pea	205			; file not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

	IFEQ	KICKSIZE-$40000
_patchkb
	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	ENDC

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

	IFEQ	1
_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts
	ENDC


;============================================================================


	IFEQ	KICKSIZE-$40000
	INCLUDE	kick13.s
	ELSE
	INCLUDE	kick31.s
	ENDC

;============================================================================

	END
