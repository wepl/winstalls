;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.3 2001/11/28 22:57:29 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
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
	OUTPUT	"wart:.debug/Kick13.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %1111

DEBUG
;DISKSONBOOT
;DOSASSIGN
HDINIT
IOCACHE		= 1024
;HRTMON
;MEMFREE	= $100
;NEEDFPU
SETPATCH

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_dir		dc.b	"wb13",0
_name		dc.b	"Kickstarter for 34.005",0
_copy		dc.b	"1987 Amiga Inc.",0
_info		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.3 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	IFEQ 1
		move.l	a0,a2
		move.l	#WCPUF_Exp_WT,d0
		move.l	#WCPUF_Exp,d1
		jsr	(resload_SetCPU,a2)
		move.l	a2,a0
	ENDC

	;initialize kickstart and environment
		bra	_boot

	IFEQ 1
_bootdos	blitz
		rts

_cb_dosLoadSeg	lsl.l	#2,d0
		move.l	d0,a0
		move.b	(a0)+,d0
		lea	(.ptr),a2
		move.l	(a2),a1
.cp		move.b	(a0)+,(a1)+
		sub.b	#1,d0
		bgt	.cp
		clr.b	(a1)+
		move.l	a1,(a2)
		rts

.ptr		dc.l	$70000
	ENDC

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

