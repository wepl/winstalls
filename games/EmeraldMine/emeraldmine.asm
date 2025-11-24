;*---------------------------------------------------------------------------
;  :Program.	emeraldmine.asm
;  :Contents.	Slave for "Emerald Mine"
;  :Author.	Harry
;  :History.	24.11.2012 V1.0
;		30.03.2025 repo import
;		24.11.2025 use kickrom for random
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

; game exe checksum is $6efd for IPF1525 and $375f for EMCD:_OLD_EM/1/
;hunklist game exe IPF1525
;hunknumber offset_in_exe length
;0 $28 $7278
;1 $7324 $470
;2 $77a0 0
;hunklist game exe EMCD
;hunknumber offset_in_exe length
;0 $28 $71bc
;1 $7268 $470
;2 $76e0 0

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;============================================================================

CHIPMEMSIZE	= $E0000
FASTMEMSIZE	= $0000
NUMDRIVES	= 2
WPDRIVES	= %0000

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
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
;MEMFREE	= $200		;location to store free memory counter
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
slv_name	dc.b	"Emerald Mine",0
slv_copy	dc.b	"1987 Kingsoft",0
slv_info	dc.b	"adapted by Harry, Wepl",10
		dc.b	"Version 1.1 "
		INCBIN	.date
		dc.b	0
slv_config	= slv_base
slv_MemConfig	= slv_base
_program	dc.b	"em",0
_args		dc.b	10
_args_end	dc.b	0
_disk1		db	"Emerald Mine",0
	EVEN

;d0 BSTR Filename
;d1 BPTR SegList

_cb_dosLoadSeg

	movem.l a0-a2/d0-d2,-(a7)
	move.l	d0,d2
	lsl.l	#2,d2
	move.l	d2,a0
	move.l	(a0),d2
	and.l	#$ffdfdfdf,d2
	cmp.l	#$03454d53,d2
	bne.s	.1
	move.l	d1,d2
	lsl.l	#2,d2
	addq.l	#4,d2
	move.l	d2,a0
	cmp.l	#$51cffffc,$f38(a0)
	bne.s	.1
	move.w	#$4eb9,$f36(a0)
	pea	_loopdbf7(pc)
	move.l	(a7)+,$f38(a0)
.1	movem.l	(a7)+,a0-a2/d0-d2
	rts

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

_bootdos	move.l  (_resload,pc),a2        ;A2 = resload

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
		lea	(_program,pc),a0	;name
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

		lea	(_pl_program_emcd,pc),a3
		cmp.w	#$375f,d0		;EMCD
		beq	.versionok

		lea	(_pl_program,pc),a3
		cmp.w	#$6efd,d0		;SPS #1525
		beq	.versionok
.nover		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		lea	(_program,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err
	;	move.l	d7,d0
	;	lsl.l	#2,d0
	;	move.l	d0,$F0.W		;start of exe just for my debugger

		move.w	#$4ef9,$88.w
		lea	_loopdbf(pc),a0
		move.l	a0,$8a.w

	;patch
		move.l	a3,a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

	;call
		move.l	d7,d1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		bsr	.call
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.program_err	jsr	(_LVOIoErr,a6)
		pea	(_program,pc)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

; D0 = ULONG arg length
; D1 = BPTR  segment
; A0 = CPTR  arg string

.call		lsl.l	#2,d1
		move.l	d1,a3
		jmp	(4,a3)

;PL IPF1525
_pl_program	PL_START
		;PL_I	$1a2			;after 'pic' loaded
		PL_PS	$456,_remdiskaccess
		PL_VL	$46c,_expmem		;set init rand to _expmem instead of $fc0000
		PL_P	$558e,_rndwrap		;let random area wrap

		PL_DATA	$498a,4			;corr dbf delay
		jsr	$88.W

	;fix weird accesses (probably wrong programmed)
		PL_DATA	$49ec,6
		move.w	$3c6.w,$f8.w
		PL_DATA	$49f8,6
		move.w	$3ce.w,$fa.w
		PL_DATA	$4a02,4
		move.w	$fa.w,d0
		PL_DATA	$4a1e,4
		mulu.w	$f8.w,d0

	;correct stone shifting time due new random generator
	;maybe now obsolete because we are using kickrom again?
		PL_PS	$51d8,_corrstoneshift
		PL_PS	$519e,_corrstoneshift
		PL_END

;PL EMCD
_pl_program_emcd
		PL_START
		PL_I	0
		PL_PS	$45A,_remdiskaccess
		PL_VL	$470,_expmem		;set init rand to _expmem instead of $fc0000
		PL_P	$54d0,_rndwrap		;let random area wrap

		PL_DATA	$48CC,4			;corr dbf delay
		jsr	$88.W

	;fix weird accesses (probably wrong programmed)
		PL_DATA	$492e,6
		move.w	$3c6.w,$f8.w
		PL_DATA	$493a,6
		move.w	$3ce.w,$fa.w
		PL_DATA	$4944,4
		move.w	$fa.w,d0
		PL_DATA	$4960,4
		mulu.w	$f8.w,d0

	;correct stone shifting time due new random generator
		PL_PS	$511a,_corrstoneshift
		PL_PS	$50e0,_corrstoneshift
		PL_END

_corrstoneshift
	move.b	(a6),d1	;orig instructions
	;and.b	#$3,d1
	;;beq.s	+4

	cmp.b	#$80,d1
	bhs.s	.1
	move.b	#0,d1
.1	rts

_loopdbf7
	move.l	d0,-(a7)
	move.l	d7,d0
	divu.w	#$20,d0
	bsr.s	_loopdbfinner
	move.l	(a7)+,d0
	rts

_loopdbf
	divu.w	#$2d,d0
_loopdbfinner
	and.l	#$ffff,d0
.2	movem.l	d0/d1,-(a7)
	move.l	$dff004,d0
	and.l	#$ffff00,d0
.1	move.l	$dff004,d1
	and.l	#$ffff00,d1
	cmp.l	d0,d1
	beq.s	.1
	movem.l	(a7)+,d0/d1
	dbf	d0,.2
	rts

_remdiskaccess
	move.l	#$4e714e71,0-$7faa(a4)	;visible only at this program state
	move.w	#$6028,0-$7fa4(a4)	;thus patch here
	add.l	#$2422c,d3		;orig instruction
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

