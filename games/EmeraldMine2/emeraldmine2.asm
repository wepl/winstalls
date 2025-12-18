;*---------------------------------------------------------------------------
;  :Program.	emeraldmine2.asm
;  :Contents.	Slave for "Emerald Mine 2"
;  :Author.	Harry, Wepl
;  :History.	09.06.2012 started
;		18.12.2025 imported to winstalls
;			   add Config to start editor
;			   fix MANX stack check
;			   replace random
;			   use dos assign
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

; game exe checksum is $2b90 - IPF1520 and EMCD:_OLD_EM/2/
; editor exe checksum is $5368
;hunklist game exe v1
;hunknumber offset_in_exe length
;0 $28 $785c
;1 $7904 $4fc
;etc.

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;============================================================================

CHIPMEMSIZE	= $E0000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

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
DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
IOCACHE	= 4096			;cache for the filesystem handler (per fh)
;MEMFREE	= $100		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 20
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Emerald Mine 2",0
slv_copy	dc.b	"1988 Kingsoft",0
slv_info	dc.b	"adapted by Harry, Wepl",10
		dc.b	"Version 1.0 "
		INCBIN	.date
		dc.b	0
slv_config	dc.b	"C1:B:Start Editor",0
slv_MemConfig	= slv_base
_program	dc.b	"em2",0
_editor		dc.b	"newdef",0
_args		dc.b	10
_args_end	dc.b	0
_disk1		db	"playfielddisk",0
	EVEN

;============================================================================
; D0 = ULONG argument line length, including LF
; D2 = ULONG stack size
; D4 = D0
; A0 = CPTR  argument line
; A1 = APTR  BCPL stack, low end
; A2 = APTR  BCPL
; A4 = APTR  return address, frame (A7+4)
; A5 = BPTR  BCPL
; A6 = BPTR  BCPL
; (SP)       return address
; (4,SP)     stack size
; (8,SP)     previous stack frame -> +4 = A1,A2,A5,A6

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;check if editor should run
		lea	_program,a3		;A3 = executable name
		lea	_pl_program,a4		;A4 = patchlist
		clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add	#4,a7
		tst.l	(a7)+
		beq	.noeditor
		lea	_editor,a3		;A3 = executable name
		lea	_pl_editor,a4		;A4 = patchlist
.noeditor	add	#4,a7

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	(_disk1,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;check version
		move.l	a3,a0			;name
		move.l	#300,d3			;maybe 300 byte aren't enough for version compare...
		move.l	d3,d0			;length
		moveq	#0,d1			;offset
		sub.l	d3,a7
		move.l	a7,a1			;buffer
		jsr	(resload_LoadFileOffset,a2)
		move.l	d3,d0
		move.l	a7,a0
		jsr	(resload_CRC16,a2)
		add.l	d3,a7

		cmp.w	#$5368,d0		;game
		beq	.versionok
		cmp.w	#$2b90,d0		;editor
		beq	.versionok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		move.l	a3,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

		move.b	#2,$80.W	;no of drives: 2 (both disks inserted)

	;patch
		move.l	a4,a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

	;call
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		move.l	d7,d1
		lsl.l	#2,d1
		move.l	d1,a3
		add	#4,a7			;drop os return address to fix MANX stack check
		jsr	(4,a3)
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.program_err	jsr	(_LVOIoErr,a6)
		pea	(a4)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

_pl_program	PL_START
		PL_PS	$8a8,_remdiskaccess
		PL_P	$25a,_loopbne
		PL_PS	$4db0,_loopdbf
		PL_W	$2ee,$70		;correct int ack
		PL_VL	$8be,_expmem		;set init rand to _expmem instead of $fc0000
		PL_P	$5998,_rndwrap		;let random area wrap
	;fix weird accesses (probably wrong programmed)
		PL_DATA	$4e16,6
		move.w	$3c6.w,$f8.w
		PL_DATA	$4e22,6
		move.w	$3ce.w,$fa.w
		PL_DATA	$4e2c,4
		move.w	$fa.w,d0
		PL_DATA	$4e48,4
		mulu.w	$f8.w,d0
	;correct stone shifting time due new random generator
		PL_PS	$55e4,_corrstoneshift
		PL_PS	$55aa,_corrstoneshift
		PL_END

_pl_editor	PL_START
		PL_END

_corrstoneshift
	move.b	(a6),d1	;orig instructions
	cmp.b	#$80,d1
	bhs.s	.1
	move.b	#0,d1
.1	rts

_loopdbf
	move	#-1,d0
	divu.w	#$2d,d0
.2	movem.l	d0/d1,-(a7)
	move.l	$dff004,d0
	and.l	#$ffff00,d0
.1	move.l	$dff004,d1
	and.l	#$ffff00,d1
	cmp.l	d0,d1
	beq.s	.1
	movem.l	(a7)+,d0/d1
	dbf	d0,.2
	add.l	#2,(a7)
	rts

_loopbne
	divu.w	#$19,d0
	and.l	#$ffff,d0
.2	movem.l	d0/d1,-(a7)
	move.l	$dff004,d0
	and.l	#$ffff00,d0
.1	move.l	$dff004,d1
	and.l	#$ffff00,d1
	cmp.l	d0,d1
	beq.s	.1
	movem.l	(a7)+,d0/d1
	subq.l	#1,d0
	bne.s	.2
	rts

_remdiskaccess
	move.l	#$4e714e71,0-$7faa(a4)	;visible only at this program state
	move.w	#$6028,0-$7fa4(a4)	;thus patch here
	add.l	#$2422c,d0		;orig instruction
	rts

	;reset random address if above kickstart end
_rndwrap	sub.l	#KICKSIZE,a2
		cmp.l	(_expmem),a2
		bhs	.write
		add.l	#KICKSIZE,a2
.write		move.l	a2,$330
		rts

;============================================================================

	END

