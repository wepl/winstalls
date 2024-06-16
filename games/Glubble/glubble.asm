;*---------------------------------------------------------------------------
;  :Program.	glubble.asm
;  :Contents.	Slave for "Glubble" from XYMOX Project
;  :Author.	wepl <wepl@whdload.de>
;  :Version.	$Id: winditup.asm 1.7 2002/02/19 21:09:47 wepl Exp wepl $
;  :History.	2024-06-14 start (at Flashback Symposium #1)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ctemp:daten/games/glubble/Glubble.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER					;disable supervisor warnings
	ENDC

CHIPSIZE = $100000
FASTSIZE = $80000
DISKSIZE = 540672

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap ;ws_flags
		dc.l	CHIPSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	FASTSIZE+DISKSIZE	;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD	BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

_name		dc.b	"Glubble",0
_copy		dc.b	"2024 Oxygene",0
_info		dc.b	"installed by Wepl",10
		db	"during Flash<<Back Symposium #1",10
		dc.b	"Version 1.0 "
	IFD	BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later use

	;install keyboard quitter
		bsr	_SetupKeyboard

		move	#0,sr		;kernel fails if started from supervisor

	;load kernel
	;args on stack
	;0	chip ptr
	;4	chip free largest
	;8	fast/exp ptr
	;12	fast free largest
	;$10	bb ioreq
	;$14	= chip ptr
	;$18	loaded adf-image	-> $f2
	;$1c	0			-> $f6
	;$22.w	?			-> ($16,a6)
	;d6 = start arg
		lea	(-$22,a7),a7
		move.l	#$400,(a7)		;mem chip
		move.l	#CHIPSIZE-$400,(4,a7)	;free chip
		move.l	_expmem,(8,a7)		;mem fast
		move.l	#FASTSIZE,(12,a7)	;free fast
		clr.l	(16,a7)			;ioreq
		move.l	(a7),($14,a7)
		clr.l	($18,sp)		;loaded adf

		moveq	#0,d0			;offset
		move.l	#$1e00,d1		;size
		moveq	#1,d2			;disk
		move.l	(a7),a0			;destination
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)

	;preload complete disk image
		moveq	#0,d0			;offset
		move.l	#DISKSIZE,d1		;size
		moveq	#1,d2			;disk
		move.l	_expmem,a0		;destination
		add.l	#FASTSIZE,a0
		move.l	a0,($18,sp)		;loaded adf
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)

	movea.l	($14,sp),a1	;mem chip 2
	lea	($7C00,a1),a0	;offset for unpacked data
	lea	($11A,a1),a1	;data start
	pea	(a0)		;remember
	move.w	(a1)+,d0	;unpacked size
	lea	(a0,d0.w),a3
	moveq	#0,d7
	move.w	(a1),d6
lbC0000AE	move.w	d6,d1
	bmi.b	lbC0000C4
	moveq	#9,d3
	bsr.b	lbC000100
	move.b	d2,(a0)+
lbC0000B8	cmpa.l	a3,a0
	bls.b	lbC0000AE
	bra	_kernel

lbC0000C4	moveq	#6,d4
	moveq	#6,d2
	bsr.b	lbC0000EA
	add.w	d2,d5
	move.w	d6,d1
	move.w	d5,d0
	moveq	#3,d4
	moveq	#12,d2
	bsr.b	lbC0000EA
	ror.w	#7,d5
	add.w	d5,d2
	neg.w	d2
	lea	(-1,a0,d2.w),a2
	move.b	(a2)+,(a0)+
lbC0000E2	move.b	(a2)+,(a0)+
	dbra	d0,lbC0000E2
	bra.b	lbC0000B8

lbC0000EA	moveq	#0,d3
	moveq	#0,d5
lbC0000EE	addq.w	#1,d3
	add.w	d1,d1
	bcc.b	lbC0000FA
	addx.w	d5,d5
	dbra	d4,lbC0000EE
lbC0000FA	sub.w	d4,d2
	bsr.b	lbC000106
	move.w	d2,d3
lbC000100	move.w	d6,d2
	swap	d2
	rol.l	d3,d2
lbC000106	sub.b	d3,d7
	bcs.b	lbC00010E
	rol.l	d3,d6
	rts

lbC00010E	add.b	#$10,d7
	move.l	(a1),d6
	addq.l	#2,a1
	ror.l	d7,d6
	rts

_kernel		lea	_pl_kernel,a0
		move.l	(a7),a1
		move.l	(_resload),a2
		jsr	(resload_Patch,a2)

	;before kernel is moved
		clr.l	-(a7)
		move.l	(4,a7),-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add	#12,a7

	;after kernel has moved
		clr.l	-(a7)
		pea	$80000-$1f2
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add	#12,a7

		move.l	#$1D780060,d6
		rts

_pl_kernel	PL_START
		PL_S	$10,$5c-$10	;skip os stuff
		PL_W	$25e4,$1fe	;fmode -> noop
		PL_END

;--------------------------------

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	INCLUDE	Sources:whdload/keyboard.s

;======================================================================

_resload	dx.l	0		;address of resident loader

;======================================================================

	END
