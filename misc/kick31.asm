;*---------------------------------------------------------------------------
;  :Modul.	kick31.asm
;  :Contents.	kickstart 3.1 booter
;  :Author.	Wepl
;  :Version.	$Id: kick13.asm 1.4 2002/05/09 13:43:24 wepl Exp wepl $
;  :History.	04.03.03 started
;  :Requires.	kick31.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:.debug/Kick31.Slave"
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
NUMDRIVES	= 4
WPDRIVES	= %1111

;BLACKSCREEN
DEBUG
;DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
;FSSM
;HDINIT
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_MATHFFP
HRTMON
;IOCACHE		= 1024
;MEMFREE	= $200
;NEEDFPU
;POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

KICKSIZE	= $80000			;40.068
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_bootpre-_base		;ws_GameLoader
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

_dir		dc.b	"wb31",0
_name		dc.b	"Kickstarter for 40.068",0
_copy		dc.b	"1985-93 Commodore-Amiga Inc.",0
_info		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.1 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================

_bootpre	move.l	a0,a2
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
	;kickstart
		move.l	a2,a0
		bra	_boot

	IFEQ 1
_bootearly	blitz
		rts
	ENDC

	;a0 = buffer (1024 bytes)
	;a1 = ioreq ($2c+a5)
	;a6 = execbase
	IFEQ 1
_bootblock	blitz
		jmp	(12,a0)
	ENDC

;============================================================================

	INCLUDE	Sources:whdload/kick31.s

;============================================================================

	END

