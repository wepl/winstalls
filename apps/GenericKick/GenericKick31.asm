;*---------------------------------------------------------------------------
;  :Program.	GenericKickHD.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Version.	$Id: GenericKick31HD.asm 1.4 2021/11/15 21:51:50 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;		01.11.07 reworked for v16+ (Wepl)
;		24.04.16 version bump
;		15.11.21 updated for new kickemu
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"GenericKick31.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $1ff000	;size of chip memory
FASTMEMSIZE	= $00000	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
DEBUG				;enable additional internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
HRTMON				;add support for HrtMON
;INITAGA			;enable AGA features
;INIT_AUDIO			;enable audio.device
;INIT_GADTOOLS			;enable gadtools.library
;INIT_LOWLEVEL			;load lowlevel.library
;INIT_MATHFFP			;enable mathffp.library
;INIT_NONVOLATILE		;init nonvolatile.library
;INIT_RESOURCE			;init whdload.resource
IOCACHE		= 10000		;cache for the filesystem handler (per fh)
;JOYPADEMU			;use keyboard for joypad buttons
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
NO68020				;remain 68000 compatible
POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
SEGTRACKER			;add segment tracker
SETKEYBOARD			;activate host keymap
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
WHDCTRL				;add WHDCtrl resident command

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D

;============================================================================

	INCLUDE	whdload/kick31.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Generic KickStarter 40.068",0
slv_copy	dc.b	"1985-93 Commodore-Amiga Inc.",0
slv_info	dc.b	"by JOTD, Wepl",10
		dc.b	"Version 1.6 "
		INCBIN	".date"
		dc.b	0
	EVEN

;============================================================================

	INCLUDE	GenericKick.s

