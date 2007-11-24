;*---------------------------------------------------------------------------
;  :Modul.	kick12.asm
;  :Contents.	kickstart 1.2 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick12.asm 1.6 2007/07/26 18:57:18 wepl Exp wepl $
;  :History.	25.04.02 created
;		20.06.03 rework for whdload v16
;		18.12.06 adapted for eab release
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
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN
;BOOTBLOCK
;BOOTEARLY
CACHE
DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
;HDINIT
;HRTMON
IOCACHE		= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	Sources:whdload/kick12.s

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Kickstarter for 33.180",0
slv_copy	dc.b	"1986 Amiga Inc.",0
slv_info	dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.3 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
; entry before any diskaccess is performed, no dos.library available

	IFD BOOTEARLY

_bootearly	blitz
		rts

	ENDC

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

	IFD BOOTBLOCK

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	blitz
		jmp	(12,a4)

	ENDC

;============================================================================

	END

