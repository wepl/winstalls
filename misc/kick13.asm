;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.s 0.3 1999/12/22 11:13:14 jah Exp jah $
;  :History.	19.10.99 started
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

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=0

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
NOFPU

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
HRTMON

; amount of memory available for the system
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $10000

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
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

_name		dc.b	"Kickstarter for 34.005",0
_copy		dc.b	"1987 Amiga Inc.",0
_info		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.2 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

	IFEQ 1

	;a1 = ioreq ($2c+a5)
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock
	;set caches
		move.l	#0,d0
		move.l	#WCPUF_All,d1
		move.l	(_resload,pc),a0
		jsr	(resload_SetCPU,a0)
	;setup hook
		patch	$xx(a4),_xx
	;call bootblock
		jmp	(12,a4)

_xx

	ENDC

	IFEQ 1
;not implemented yet!
	;a6 = dosbase
_dos
	ENDC

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

