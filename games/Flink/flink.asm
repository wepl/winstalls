;*---------------------------------------------------------------------------
;  :Program.	Flink.asm
;  :Contents.	Slave for "Flink" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team, Harry, Wepl
;  :Version.	$Id: kick31.asm 1.4 2004/03/05 07:44:16 wepl Exp wepl $
;  :History.	22.03.99/2.7.2000
;		08.04.04 rework for kickemu
;  :Requires.	kick31.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

Trainer		=	0	; 0-off, 1-on

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:fl/flink/Flink.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	MC68020
	ENDC

;============================================================================

CHIPMEMSIZE	= $200000-$55000
FASTMEMSIZE	= $80000-$33000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
CACHE
DEBUG
;DOSASSIGN
;DISKSONBOOT
;FONTHEIGHT	= 8
HDINIT
;INITAGA
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_MATHFFP
INIT_LOWLEVEL
;HRTMON
;IOCACHE	= 1024
;MEMFREE	= $200
;NEEDFPU
;POINTERTICKS	= 1
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA|WHDLF_Req68020
slv_keyexit	= $5d

;============================================================================

	INCLUDE	Sources:whdload/kick31.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Flink",0
slv_copy	dc.b	"1994 Psygnosis",0
slv_info	dc.b	"adapted by Mr.Larmer, Harry, Wepl",10
		dc.b	"Version 2.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_programreq	dc.b	"cannot loadseg "
_program	dc.b	"flink",0
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

	IFD BOOTDOS

_bootdos	move.l	(_resload),a2		;A2 = _resload

	;alloc mem for blitter faults
		move.l	4,a6
		move.l	#$10000,d0
		moveq	#MEMF_CHIP,d1
		jsr	(_LVOAllocMem,a6)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	(_program,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		bne	.programok
		pea	_program
		pea	ERROR_OBJECT_NOT_FOUND
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)
.programok

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
		sub.l	a0,a0			;basm bug
		jmp	(4,d7.l*4)		;will be (4,a0,d7.l*4)

_pl_program	PL_START
		PL_S	$11a,$15e-$11a		;dont open cd.device
		PL_S	$1d6,4			;skip reading vbr
		PL_L	$40c,-1			;simulate error on opening cd.device to avoid further acesses
		PL_S	$af2,$b0e-$af2		; dont force lowlevel port0 to GAMECTLR
		PL_S	$b72,6			; skip set NTSC mode
		PL_S	$c6c,6			; skip read DSKDATR
		PL_R	$21ec0			; skip init disk drive (motor off)
		PL_W	$221fe,$207B		; REMOVE CRASH IN SEVERAL SPELLS
		PL_S	$21dba,$21f00-$21dba
		PL_P	$21f26,.load
	ifne	Trainer
		PL_S	$78AE,6
		PL_B	$7956,$4a
		PL_B	$18144,$4a
		PL_B	$19536,$4a
		PL_B	$1BCD4,$4a
		PL_B	$1BE62,$4a
		PL_B	$1C35A,$4a
		PL_B	$1C624,12
		PL_B	$1C898,12
		PL_B	$1C950,$4a
		PL_B	$1CC0E,12
		PL_B	$1CDD4,$4a
		PL_B	$1CEE2,$4a
		PL_B	$1D16E,$4a
		PL_W	$20B56,$4e71
	endc
		PL_END

.load		movem.l	d0-d1/a0-a2,-(a7)
		move.l	d1,a0			;name
		move.l	d4,a1			;destination
		move.l	_resload,a2
		jsr	(resload_LoadFileDecrunch,a2)
		movem.l	(a7)+,_MOVEMREGS
		rts

	IFEQ 1
;		move.l	#$70004E71,$154(A1)	; open cd device
		move.l	#$91C84E71,$37A(A1)	; skip read VBR

		move.w	#$6004,$B72(A1)		; skip set NTSC mode

		move.w	#$6002,$C6C(A1)		; skip read DSKDATR

;		add.l	#$21C3A,A1
;		move.l	#$70004E71,(A1)		; skip SendIO for cd.device
;		sub.l	#$21C3A,A1

		add.l	#$21EC0,A1
		move.w	#$4E75,(A1)		; skip init disk drive
		sub.l	#$21EC0,A1
	MOVE.L	A1,A0			;REMOVE CRASH IN  SEVERAL SPELLS
	ADD.L	#$3C106-$19F08,A0
	MOVE.W	#$207B,(A0)
	ENDC

	ENDC

;============================================================================

	END
