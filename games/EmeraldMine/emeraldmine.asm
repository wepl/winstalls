;*---------------------------------------------------------------------------
;  :Program.	emeraldmine.asm
;  :Contents.	Slave for "Emerald Mine"
;  :Author.	Harry
;  :History.	24.11.2012 V1.0
;		30.03.2025 repo import
;		24.11.2025 use kickrom for random
;		13.12.2025 uses fast memory and less chip
;			   access faults calling ems fixed, blitwaits added
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

CHIPMEMSIZE	= $72000
FASTMEMSIZE	= $e000
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

;============================================================================
; callback/hook which gets executed after each successful call to dos.LoadSeg
; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg	lsl.l	#2,d0		;-> APTR
		beq	.end		;ignore if name is unset
		move.l	d0,a0
		moveq	#0,d0
		move.b	(a0)+,d0	;D0 = name length
	;remove leading path
		move.l	a0,a1
		move.l	d0,d2
.path		move.b	(a1)+,d3
		subq.l	#1,d2
		cmp.b	#":",d3
		beq	.skip
		cmp.b	#"/",d3
		bne	.chk
.skip		move.l	a1,a0		;A0 = name
		move.l	d2,d0		;D0 = name length
.chk		tst.l	d2
		bne	.path
	;get hunk length sum
		move.l	d1,a1		;D1 = segment
		moveq	#0,d2
.add		add.l	a1,a1
		add.l	a1,a1
		add.l	(-4,a1),d2	;D2 = hunks length
		subq.l	#8,d2		;hunk header
		move.l	(a1),a1
		move.l	a1,d7
		bne	.add
	;search patch
		lea	(_cbls_patch,pc),a1
.next		move.l	(a1)+,d3
		movem.w	(a1)+,d4-d5
		beq	.end
		cmp.l	d2,d3		;length match?
		bne	.next
	;compare name
		lea	(_cbls_patch,pc,d4.w),a2
		move.l	a0,a3
		move.l	d0,d6
.cmp		move.b	(a3)+,d7
		cmp.b	#"a",d7
		blo	.l
		cmp.b	#"z",d7
		bhi	.l
		sub.b	#$20,d7
.l		cmp.b	(a2)+,d7
		bne	.next
		subq.l	#1,d6
		bne	.cmp
		tst.b	(a2)
		bne	.next
	;set debug
	IFD DEBUG
		clr.l	-(a7)
		move.l	d1,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		move.l	(_resload,pc),a2
		jsr	(resload_Control,a2)
		move.l	(4,a7),d1
		add.w	#12,a7
	ENDC
	;patch
		lea	(_cbls_patch,pc,d5.w),a0
		move.l	d1,a1
		move.l	(_resload,pc),a2
		jsr	(resload_PatchSeg,a2)
	;end
.end		rts

LSPATCH	MACRO
		dc.l	\1		;cumulated size of hunks (not filesize!)
		dc.w	\2-_cbls_patch	;name
		dc.w	\3-_cbls_patch	;patch list
	ENDM

_cbls_patch	LSPATCH	$12dc,.n_ems,_p_ems
		dc.l	0

	;all upper case!
.n_ems		dc.b	"EMS",0
	EVEN

_p_ems		PL_START
		PL_PS	$f36,_loopdbf7
		PL_END

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
	;	PL_I	$1a2			;after 'pic' loaded
	;	PL_BKPT	$368			;calling ems
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

		PL_PS	$4ab0,_bw2
		PL_PS	$4dac,_bw3
		PL_PS	$56ce,_bw1
		PL_P	$6216,_callems
		PL_W	$6228,4+6		;wrong calling ems: jsr (6,a1)
		PL_W	$623a,4+12		;wrong calling ems: jsr (10,a1)
		PL_END

;PL EMCD
_pl_program_emcd
		PL_START
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

		PL_PS	$49f2,_bw2
		PL_PS	$4cee,_bw3
		PL_PS	$5610,_bw1
		PL_P	$6158,_callems
		PL_W	$616a,4+6		;wrong calling ems: jsr (6,a1)
		PL_W	$617c,4+12		;wrong calling ems: jsr (10,a1)
		PL_END

_callems	jsr	(4,a1)
		movem.l	(a7)+,d0-a6
		rts

_bw1		bsr	_bw
		move	#-1,_custom+bltafwm
		add.l	#2,(a7)
		rts

_bw2		lsl.l	#2,d2
		add.l	$320,d2

_bw3		lsl.l	#7,d4
		add.l	$320,d4

_bw		BLITWAIT
		rts

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

