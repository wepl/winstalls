;*---------------------------------------------------------------------------
;  :Program.	tech.asm
;  :Contents.	Slave for "Tech" by Gainstar
;  :Author.	Wepl
;  :Version.	$Id: tech.asm 1.1 1998/03/16 16:58:59 jah Exp $
;  :History.	08.03.97
;		01.11.01 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	OUTPUT	"wart:t/tech/Tech.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $000
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	14			;ws_Version
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

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Tech",0
_copy		dc.b	"1989 Gainstar/The Omega Team",0
_info		dc.b	"adapted by Wepl",10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_tech		dc.b	"Tech.00",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

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
		jsr	(resload_Patch,a2)
		
		nop
		rts

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

	INCLUDE	Sources:whdload/kick13.s
	INCLUDE	Sources:whdload/dbffix.s

;======================================================================

	END
