;*---------------------------------------------------------------------------
;  :Modul.	workbench13.asm
;  :Contents.	Workbench 1.3
;  :Author.	Wepl
;  :Version.	$Id: workbench13.asm 1.6 2017/10/07 17:13:09 wepl Exp wepl $
;  :History.	18.12.06 derived from kick13.asm
;		18.01.07 chip & fast mem increased
;		08.01.12 v17 config stuff added
;		10.11.13 possible endless loop in _cb_dosLoadSeg fixed
;		03.10.17 new options CACHECHIP/CACHECHIPDATA
;  :Requires.	kick13.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"awart:workbench13/Workbench13.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $ff000	;size of chip memory
FASTMEMSIZE	= $100000	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
HRTMON				;add support for HrtMON
IOCACHE		= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Workbench 1.3 Kickstarter 34.005",0
slv_copy	dc.b	"1987 Amiga Inc.",0
slv_info	dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 1.3 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Trainer",0
	ENDC
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
; A1 = APTR  BCPL stack, low end
; A2 = APTR  BCPL
; A4 = APTR  return address, frame (A7+4)
; A5 = BPTR  BCPL
; A6 = BPTR  BCPL
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

		cmp.w	#$0ac4,d0
		beq	.versionok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		lea	(_program,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
		lea	(_pl_program,pc),a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

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

	IFD QUIT_AFTER_PROGRAM_EXIT
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
	ELSE
	;remove exe
		move.l	d7,d1
		move.l	(_dosbase,pc),a6
		jsr	(_LVOUnLoadSeg,a6)

	;return to CLI
		moveq	#0,d0
		move.l	(_saverts,pc),-(a7)
		rts
	ENDC

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

_disk1		dc.b	"DF0",0		;for Assign
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
; callback/hook which gets executed after each successful call to dos.LoadSeg
; can also be used instead of _bootdos, requires the presence of
; "startup-sequence"
; if you use diskimages that is the way to patch the executables

; the following example uses a parameter table to patch different executables
; after they get loaded

	IFD CBDOSLOADSEG

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg	lsl.l	#2,d0		;-> APTR
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

_cbls_patch	LSPATCH	2516,.n_run,_p_run2568
		LSPATCH	7080,.n_shellseg,_p_shellseg7080
		LSPATCH	2956,.n_assign,_p_assign3008
		dc.l	0

	;all upper case!
.n_run		dc.b	"RUN",0
.n_shellseg	dc.b	"SHELL-SEG",0
.n_assign	dc.b	"ASSIGN",0
	EVEN

_p_assign3008	PL_START
	;	PL_BKPT	$542			;access fault follows
		PL_B	$546,$60		;beq -> bra
		PL_END
_p_run2568	PL_START
		PL_END
_p_shellseg7080	PL_START
		PL_AW	$1990,$1a4c-$19ae	;dereferences NULL (maybe dirlock because actual directory is broken)
		PL_END

	ENDC

;============================================================================
; callback/hook which gets executed after each successful call to
; dos.LoadRead
; it only works for files loaded via the virtual filesystem of HDINIT not
; for files loaded from diskimages

; the following example uses a parameter table to patch different files
; after they get loaded

	IFD CBDOSREAD

; D0 = ULONG bytes read
; D1 = ULONG offset in file
; A0 = CPTR name of file
; A1 = APTR memory buffer

_cb_dosRead
		move.l	a0,a2
.1		tst.b	(a2)+
		bne	.1
		lea	(.name,pc),a3
		move.l	a3,a4
.2		tst.b	(a4)+
		bne	.2
		sub.l	a4,a2
		add.l	a3,a2		;first char to check
.4		move.b	(a2)+,d2
		cmp.b	#"A",d2
		blo	.3
		cmp.b	#"Z",d2
		bhi	.3
		add.b	#$20,d2
.3		cmp.b	(a3)+,d2
		bne	.no
		tst.b	d2
		bne	.4

	;check position
		move.l	d0,d2
		add.l	d1,d2
		lea	(.data,pc),a2
		moveq	#0,d3
.next		movem.w	(a2)+,d3-d4
		tst.w	d3
		beq	.no
		cmp.l	d1,d3
		blo	.next
		cmp.l	d2,d3
		bhs	.next
		sub.l	d1,d3
		move.b	d4,(a1,d3.l)
		bra	.next

.no		rts

.name		dc.b	"tables01",0	;lower case!
	EVEN
	;offset, new data
.data		dc.w	$4278,$c	;original = 0b
		dc.w	$45b4,$c	;original = 0b
		dc.w	0

	ENDC

;============================================================================
; callback/hook which gets executed on each keypress

	IFD CBKEYBOARD

; D0 = UBYTE rawkey code

_cb_keyboard
		cmp.b	#$40,d0		;space
		bne	.ok
		illegal
.ok
		rts

	ENDC

;============================================================================

	END

