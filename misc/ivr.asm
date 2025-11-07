;*---------------------------------------------------------------------------
;  :Modul.	ivr.asm
;  :Contents.	slave to test interrupt vector redirect functionality
;	Custom1=0 no interrupts active
;	Custom1=1 only vbi active performing color cycling
;	Custom1=2 also ports interrupt active, quitting on esc
;  :Author.	Wepl
;  :Version.	$Id: zeus.asm 1.1 2012/10/12 20:51:35 wepl Exp wepl $
;  :History.	26.09.12 started
;		13.11.13 refresh for aca500
;  :Requires.
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:.debug/IVR.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Interrupt Vector Redirect Test Slave",0
_copy		dc.b	"Wepl",0
_info		dc.b	"for testing interrupt hook with Zeus/ACA500 boards",10
		dc.b	"build "
	DOSCMD	"WDate  >T:date"
	INCBIN	"T:date"
		dc.b	-1
		dc.b	"can be quit always using LMB",10
		dc.b	"no ints: no keyboard quit possible",10
		dc.b	"vbi: quitkey possible",10
		dc.b	"vbi+ports: esc + quitkey possible",0
_config		dc.b	"C1:L:mode:no ints,vbi,vbi+ports",0
_badc1		dc.b	"unsupported Custom1 value",0
_quitlmb	dc.b	"Exit because LMB pressed",0
_quitesc	dc.b	"Exit because Esc pressed",0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	_resload,a1
		move.l	a0,(a1)
		lea	(_ciaa),a4		;A4 = ciaa
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = custom

		clr.l	-(a7)
		clr.l	-(a7)
		move.l	#WHDLTAG_CUSTOM1_GET,-(a7)
		move.l	a7,a0
		jsr	(resload_Control,a5)
		move.l	(4,a7),d0		;custom1
		beq	_0
		subq.l	#1,d0
		beq	_1
		subq.l	#1,d0
		beq	_2
		pea	_badc1
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a5)

_0		move	#$f00,(color,a6)
_wait_lmb	btst	#6,$bfe001
		bne	_wait_lmb
		pea	_quitlmb
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a5)

_2		bsr	_SetupKeyboard

_1		move	.col,(color,a6)
		lea	.6c,a0
		move.l	a0,$6c
		move	#INTF_SETCLR!INTF_INTEN!INTF_VERTB,(intena,a6)
		bra	_wait_lmb

.col		dc.w	$00f			;blue

.6c		movem.l	d0/a0,-(a7)
		lea	.col,a0
		addq.w	#1,(a0)
		move.w	(a0),(color,a6)
		move.w	#INTF_VERTB,(intreq,a6)
		tst.w	(intreqr,a6)
		movem.l	(a7)+,_MOVEMREGS
		rte

_key_check	cmp.b	#$45,d0
		beq	.esc
		rts

.esc		pea	_quitesc
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a5)


;======================================================================

	INCLUDE	Sources:whdload/keyboard.s

;======================================================================

_resload	dc.l	0

;======================================================================

	END
