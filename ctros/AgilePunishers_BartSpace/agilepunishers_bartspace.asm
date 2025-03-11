;*---------------------------------------------------------------------------
;  :Modul.	agile_thesimpsons.asm
;  :Contents.	ctro
;  :Author.	Wepl
;  :History.	2025-03-10 created
;  :Requires.	kick13.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;============================================================================

CHIPMEMSIZE	= $7f000	;size of chip memory
FASTMEMSIZE	= 0		;size of fast memory
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
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
IOCACHE		= 1024		;cache for the filesystem handler (per fh)
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
;slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	0
slv_name	dc.b	"The Simpsons: Bart vs. The Space Mutants",0
slv_copy	dc.b	"Agile / Punishers",0
slv_info	db	"press LMB to enter trainer",-1
		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 1.0 "
		INCBIN	".date"
		dc.b	0
	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Trainer",0
	ENDC
_agile		db	"agile",0
_pns91		db	"pns91",0
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required, this will never called if booted from a diskimage, only
; works in conjunction with the virtual filesystem of HDINIT
; this routine replaces the loading and executing of the startup-sequence

; the following example is extensive because it preserves all registers and
; is able to start BCPL programs and programs build by MANX Aztec-C
;
; usually a simpler routine is sufficient, check kick31.asm for an simpler one
;
; D0 = ULONG argument line length, including LF
; D2 = ULONG stack size
; D4 = D0
; A0 = CPTR  argument line
; A1 = APTR  BCPL stack, low end = tc_SPLower
; A2 = APTR  BCPL global vector
; A4 = APTR  return address, frame (A7+4)
; A5 = BPTR  BCPL service in
; A6 = BPTR  BCPL service out
; (SP)       return address
; (4,SP)     stack size
; (8,SP)     previous stack frame -> +4 = A1,A2,A5,A6

	IFD BOOTDOS

_bootdos	lea	(_saveregs,pc),a0
		movem.l	d1-d3/d5-d7/a1-a2/a4-a6,(a0)
		move.l	(a7)+,(11*4,a0)
		move.l	(_resload,pc),a2	;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	(_agile,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
	;	lea	(_pl_program,pc),a0
	;	move.l	d7,a1
	;	jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
		move.l	d7,d1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		bsr	.call

	;remove exe
		move.l	d7,d1
		move.l	(_dosbase,pc),a6
		jsr	(_LVOUnLoadSeg,a6)

	;load exe
		lea	(_pns91,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
	;	lea	(_pl_program,pc),a0
	;	move.l	d7,a1
	;	jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
		move.l	d7,d1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		bsr	.call

	;remove exe
		move.l	d7,d1
		move.l	(_dosbase,pc),a6
		jsr	(_LVOUnLoadSeg,a6)

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

.call		lea	(_callregs,pc),a1
		movem.l	d2-d7/a2-a6,(a1)
		move.l	(a7)+,(11*4,a1)
		move.l	d0,d4
		lsl.l	#2,d1
		move.l	d1,a3
		move.l	a0,a4
	;create longword aligend copy of args
		lea	(_callargs,pc),a1
		move.l	a1,d2
.callca		move.b	(a0)+,(a1)+
		subq.w	#1,d0
		bne	.callca
	;set args
		move.l	(_dosbase,pc),a6
		jsr	(_LVOInput,a6)
		lsl.l	#2,d0		;BPTR -> APTR
		move.l	d0,a0
		lsr.l	#2,d2		;APTR -> BPTR
		move.l	d2,(fh_Buf,a0)
		clr.l	(fh_Pos,a0)
		move.l	d4,(fh_End,a0)
	;call
		move.l	d4,d0
		move.l	a4,a0
		movem.l	(_saveregs,pc),d1-d3/d5-d7/a1-a2/a4-a6
		jsr	(4,a3)
	;return
		movem.l	(_callregs,pc),d2-d7/a2-a6
		move.l	(_callrts,pc),a0
		jmp	(a0)

	IFD SIMPLE_CALL
.call		lsl.l	#2,d1
		move.l	d1,a3
		jmp	(4,a3)
	ENDC

_pl_program	PL_START
		PL_END

_program	dc.b	"C/Echo",0
_args		dc.b	"Test!",10	;must be LF terminated
_args_end
	EVEN

	CNOP 0,4
_saveregs	ds.l	11
_saverts	dc.l	0
_dosbase	dc.l	0
_callregs	ds.l	11
_callrts	dc.l	0
_callargs	ds.b	208

	ENDC

;============================================================================

	END

