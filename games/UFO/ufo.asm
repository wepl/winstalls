;*---------------------------------------------------------------------------
;  :Modul.	ufo.asm
;  :Contents.	UFO Enemy Unknown
;  :Author.	Wepl
;  :Version.	$Id: kick13.asm 1.17 2014/06/09 13:54:51 wepl Exp wepl $
;  :History.	12.07.15 started
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
	OUTPUT	"wart:u/ufo/UFO.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $90000
FASTMEMSIZE	= $100000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CBKEYBOARD
CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
IOCACHE		= 45300
;MEMFREE	= $200
;NEEDFPU
POINTERTICKS	= 1
SETPATCH
;SNOOPFS
;STACKSIZE	= 6000
;TRDCHANGEDISK

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
slv_name	dc.b	"UFO Enemy Unknown",0
slv_copy	dc.b	"1994 Microprose",0
slv_info	dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"OCS Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Skip Intro",0
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
;
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
		lea	(_ufotemp,pc),a0
		move.l	a0,a1
		bsr	_dos_assign

	;run
		lea	(_geo,pc),a0		;name
		move.w	#$8ded,d0
		lea	(_args00,pc),a1
		lea	(_pl_geo,pc),a3
		bsr	.exec
		tst.l	d0
		beq	.quit

.loop		lea	(_tactical,pc),a0	;name
		move.w	#$8cf3,d0
		lea	(_args10,pc),a1
		lea	(_pl_tactical,pc),a3
		bsr	.exec

		lea	(_geo,pc),a0		;name
		move.w	#$8ded,d0
		lea	(_args10,pc),a1
		lea	(_pl_geo,pc),a3
		bsr	.exec
		tst.l	d0
		bne	.loop

.quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.exec		movem.l	d0/a0-a1/a3,-(a7)

	;check version
		move.l	(4,a7),a0		;name
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

		cmp.w	(2,a7),d0
		beq	.versionok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		move.l	(4,a7),d1		;name
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
		move.l	(12,a7),a0
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
		moveq	#8,d0
		move.l	(8,a7),a0
		lsl.l	#2,d1
		move.l	d1,a3
		movem.l	d7/a2/a6,-(a7)
		jsr	(4,a3)
		movem.l	(a7)+,d7/a2/a6
		move.l	d0,(a7)

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		movem.l	(a7)+,d0/a0-a1/a3
		rts

.program_err	jsr	(_LVOIoErr,a6)
		move.l	(4,a7),-(a7)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

_pl_geo		PL_START
		PL_B	$39a82,$60	;beq -> bra vbr
		PL_PS	$39aaa,_intoff	;smc
		PL_P	$39ac2,_flush	;smc
		PL_P	$39c2e,_intack
		PL_B	$3b75c+3,9	;aud.vol
		PL_CB	$4a8e2+7	;DEUTSCHE
		PL_END

_pl_tactical	PL_START
		PL_B	$3e76e,$60	;beq -> bra vbr
		PL_PS	$3e796,_intoff	;smc
		PL_P	$3e7ae,_flush	;smc
		PL_P	$3e91a,_intack
		PL_B	$40448+3,9	;aud.vol
		PL_END

_intoff		move.w	#INTF_INTEN,$dff09a
		tst.w	_custom+intreqr
		addq.l	#2,(a7)
		rts

_flush		move.l	_resload,a0
		jsr	(resload_FlushCache,a0)
		move.w	#$c000,$dff09a
		movem.l	(a7)+,d0-a6
		rts

_intack		move.w	#$10,_custom+intreq
		tst.w	_custom+intreqr
		rte

_ufotemp	dc.b	"ufotemp",0
_geo		dc.b	"geo",0
_tactical	dc.b	"tactical",0
_args00		dc.b	'"0" "0"',10	;must be LF terminated
_args00_end
_args10		dc.b	'"1" "0"',10	;must be LF terminated
_args10_end
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
; can also be used instead of _bootdos
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

