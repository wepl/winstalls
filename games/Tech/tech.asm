;*---------------------------------------------------------------------------
;  :Program.	tech.asm
;  :Contents.	Slave for "Tech" by Gainstar
;  :Author.	Wepl
;  :History.	08.03.97
;		01.11.01 finished
;		27.08.24 new kickemu interface, use "data" directory
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;============================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= $0		;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
;HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Tech",0
slv_copy	dc.b	"1989 Gainstar/The Omega Team",0
slv_info	dc.b	"adapted by Wepl",10
		dc.b	"Version 1.1 "
		INCBIN	.date
		dc.b	0
_tech		dc.b	"Tech.00",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

_bootearly
		moveq	#10,d0
		bsr	_poscyl
		lea	$21b10+$3e8,a0
		move.l	a0,-(a7)
		bsr	_read
		
		move.l	(a7),a0
		lea	(a0,d0.l),a1
		bsr	_dbffix
		
		clr.l	-(a7)
		move.l	(4,a7),-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		move.l	_resload,a2
		jsr	(resload_Control,a2)
		add.w	#12,a7

		lea	.pl,a0
		move.l	(a7),a1
		move.l	_resload,a2
		jmp	(resload_Patch,a2)
		
.pl		PL_START
		PL_R	$9416		;initdrive
		PL_P	$9464,_poscyl
		PL_P	$9150,_read
		PL_R	$9510		;motor off
		PL_R	$94e8		;motor on
		PL_P	$93dc,_posinc
		PL_P	$924e,_write
		PL_PS	$3db4,_b1
		PL_S	$3de6,10	;obsolete blitwait
		PL_PS	$3ac,_wait
		PL_END

;---------------

_b1		BLITWAIT
		move.l	a1,$dff050
		rts

;---------------

_wait		add.l	#$32,a0		;original
		move.l	#1000,d0
		move.l	_resload,a1
		jmp	(resload_Delay,a1)

_poscyl		move.b	d0,$101
		rts

_posinc		addq.b	#1,$101
		rts

_read		bsr	_mkname
		add.l	#$1770-1,d0
		divu	#$1770,d0
		add.b	d0,$101
		move.l	a0,a1
		lea	_tech,a0
		move.l	_resload,a2
		jmp	(resload_LoadFileDecrunch,a2)

_write		bsr	_mkname
		move.l	a0,a1
		lea	_tech,a0
		move.l	_resload,a2
		jmp	(resload_SaveFile,a2)

_mkname		movem.l	d0/a0,-(a7)
		lea	_tech+5,a0
		moveq	#0,d0
		move.b	$101,d0
		ror.l	#4,d0
		move.b	(.list,pc,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	(.list,pc,d0.w),(a0)
		movem.l	(a7)+,d0/a0
		rts

.list		dc.b	"0123456789abcdef"

;======================================================================

	IFEQ 1

		move.l	a0,a3			;A3 = resload

	;load the loader
		move.l	#$1000,a0		;adr
		move.l	#$400,d1		;size
		move.l	#0,d0			;offset
		sub.l	a1,a1			;taglist
		jsr	(resload_DiskLoadDev,a3)
		
		patch	$12e4,_1
		nops	4,$121e
		jmp	$100c

_1		patch	$21b10+$28,_2
		patch	$21b10+$116,.f1
		move.b	#$60,$21b10+$ca
		patchs	$21b10+$12e,.f4
		jmp	$21b10

.f1		movem.l	d0-d1,-(a7)
		move.l	$102,d0
		divu	#34,d0
.f2		move.b	($dff006),d1
.f3		cmp.b	($dff006),d1
		beq	.f3
		dbf	d0,.f2
		movem.l	(a7)+,d0-d1
		rts

.f4		tst	$bfd100
		tst	$bfd100
		bset	#0,$bfd100
		waitvb
		waitvb
		waitvb
		rts

_2		illegal
		jmp	$21b10+$3e8

	ENDC

;============================================================================

	INCLUDE	whdload/dbffix.s

;======================================================================

	END
