;*---------------------------------------------------------------------------
;  :Modul.	kick12.asm
;  :Contents.	kickstart 1.2 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick12.asm 1.1 2003/03/30 18:26:15 wepl Exp wepl $
;  :History.	25.04.02 created
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
	OUTPUT	"wart:.debug/Kick12.Slave"
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

;BLACKSCREEN
CACHE
DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
IOCACHE		= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

KICKSIZE	= $40000			;33.192
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-_base		;ws_GameLoader
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

_dir		dc.b	"wb12",0
_name		dc.b	"Kickstarter for 33.192",0
_copy		dc.b	"1986 Amiga Inc.",0
_info		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.1 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================

	IFEQ 1
_bootearly	blitz
		rts
	ENDC

	IFEQ 1
; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	blitz
		jmp	(12,a4)
	ENDC

;============================================================================

	INCLUDE	Sources:whdload/kick12.s

;============================================================================

	END

