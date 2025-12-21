;*---------------------------------------------------------------------------
;  :Program.	forgottenmine1.asm
;  :Contents.	Slave for "Ace Mine 1 (Emerald Mine CD)"
;  :Author.	Harry
;  :History.	25.11.2012 V1.0
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*


		INCDIR	"asm-one:include/"
		INCLUDE	whdload/whdload.i
		INCLUDE	whdload/whdmacros.i
		INCLUDE	dos/dos_lib.i
		INCLUDE	exec/exec.i
		INCLUDE exec/exec_lib.i
		INCLUDE	libraries/expansion_lib.i

	IFNE	0
	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:li/lordsofwar/LordsOfWar.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
	ENDC

;============================================================================

CHIPMEMSIZE	= $F8000
FASTMEMSIZE	= $0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
CBDOSLOADSEG
;CBDOSREAD
;CACHE
DEBUG
;DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
;HRTMON
IOCACHE		= 1024
;MEMFREE        = $100
;NEEDFPU
;POINTERTICKS	= 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK


;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

;	INCLUDE	Sources:whdload/kick13.s
	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Emerald Mines CD",0
slv_copy	dc.b	"1994 Almathera",0
slv_info	dc.b	"adapted by Harry",10
		dc.b	"Version 1.0 "
;	IFD BARFLY
;		INCBIN	"T:date"
;	ENDC
		dc.b	0
_program	dc.b	"crystalcaverns",0
_args		dc.b	10
_args_end
		dc.b	0
	EVEN

;d0 BSTR Filename
;d1 BPTR SegList

_cb_dosLoadSeg
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


_bootdos        move.l  (_resload,pc),a2        ;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		moveq.l	#0,d0
		lea	version(pc),a0
		move.b	d0,(a0)

	;load exe
		lea	(_program,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err
		move.l	d7,d0
		lsl.l	#2,d0
		move.l	d0,$F0.W	;start of exe just for my debugger

	;patch dos-open to allow skipping disk name ("playfielddisk:")
	move.w	-$1e+4(a6),d0
	ext.l	d0
	lea	-$1e+4(a6,d0.l),a0
	lea	_doslibmainrout(pc),a1
	move.l	a0,(a1)
	move.w	#$4ef9,-$1e(a6)
	pea	_patchdosopen(pc)
	move.l	(a7)+,-$1e+2(a6)

	;call
		move.l	d7,d1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		bsr	.call
;	illegal
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


_patchdosopen
	bsr	_searchforcolon
	moveq	#-1,d0			;orig instruction
	jmp	$00000000
_doslibmainrout	EQU	*-4

_searchforcolon				;search for colon in filename
					;skip part before it if found 
					;used just before dos-open
	movem.l	d0/a0,-(a7)
	move.l	d1,a0
.3	move.b	(a0),d0
	beq.s	.2
	add.w	#1,a0
	cmp.b	#':',d0
	bne.s	.3
	move.l	a0,d1
.2	movem.l	(a7)+,d0/a0
	rts


;============================================================================

version	dc.b	0
	EVEN

	END

