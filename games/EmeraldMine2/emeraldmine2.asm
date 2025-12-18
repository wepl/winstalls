;*---------------------------------------------------------------------------
;  :Program.	emeraldmine2.asm
;  :Contents.	Slave for "Emerald Mine 2"
;  :Author.	Harry
;  :History.	09.06.2012 started
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

CHIPMEMSIZE	= $E0000
FASTMEMSIZE	= $0000
NUMDRIVES	= 2
WPDRIVES	= %0000

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
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
slv_name	dc.b	"Emerald Mine 2",0
slv_copy	dc.b	"1988 Kingsoft",0
slv_info	dc.b	"adapted by Harry",10
		dc.b	"Version 0.9beta "
;	IFD BARFLY
;		INCBIN	"T:date"
;	ENDC
		dc.b	0
_program	dc.b	"em2",0
_program2	dc.b	"newdef",0
_args		dc.b	10
_args_end
		dc.b	0
	EVEN
_prognamtab	dc.w	0,_program2-_program

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

	lea	_whtags(pc),a0
	jsr	(resload_Control,a2)
	move.l	_whtags+4(pc),d0
	tst.l	d0
	beq.s	.noeditor
	cmp.l	#1,d0
	bne.s	.nover
	lea	_editoractive(pc),a0
	move.b	#1,(a0)

.noeditor

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;check version
		lea	(_program,pc),a0
		moveq.l	#0,d0
		move.b	_editoractive(pc),d0
		lsl.l	#1,d0
		add.w	_prognamtab-_program(a0,d0.w),a0
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d6
		beq	.program_err
		move.l	d6,d1
		move.l	#300,d3
		sub.l	d3,a7
		move.l	a7,d2
		jsr	(_LVORead,a6)
		move.l	d6,d1
		jsr	(_LVOClose,a6)
		move.l	d3,d0
		move.l	a7,a0
		jsr	(resload_CRC16,a2)
		add.l	d3,a7

;	illegal

		cmp.w	#$5368,d0
		beq	.versionok
		
		cmp.w	#$2b90,d0
		beq	.versionokgame
.nover		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.illegal	illegal

.versionokgame
		;prepare random number area
		move.l	#$41000,d0	;len
		move.l	#$80000,a1	;place
		move.l	a6,-(a7)
		move.l	$4.w,a6
		jsr	_LVOAllocAbs(a6)
		move.l	(a7)+,a6
		tst.l	d0
		beq.s	.illegal
		move.l	#$41000/4,d1
		lea	$80000,a1
.randinit
		bsr	_random
		move.l	d0,(a1)+
		subq.l	#1,d1
		bne.s	.randinit

.versionok


	;load exe
		lea	(_program,pc),a0
		moveq.l	#0,d0
		move.b	_editoractive(pc),d0
		lsl.l	#1,d0
		add.w	_prognamtab-_program(a0,d0.w),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err
		move.l	d7,d0
		lsl.l	#2,d0
		move.l	d0,$F0.W	;start of exe just for my debugger

		move.b	_editoractive(pc),d0
		beq.s	.gameem2
.editorem2
	;patch dos-open to allow skipping disk name ("playfielddisk:")
	move.w	-$1e+4(a6),d0
	ext.l	d0
	lea	-$1e+4(a6,d0.l),a0
	lea	_doslibmainrout(pc),a1
	move.l	a0,(a1)
	move.w	#$4ef9,-$1e(a6)
	pea	_patchdosopen(pc)
	move.l	(a7)+,-$1e+2(a6)
	bra.s	.callprg



;	illegal


.gameem2	move.b	#2,$80.W	;no of drives: 2 (both disks inserted)

		move.w	#$4ef9,$88.w
		lea	_loopdbf(pc),a0
		move.l	a0,$8a.w


	;patch
		lea	(_pl_program,pc),a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

;	move.l	#4,d0
;	lea	$4,a0
;	jsr	(resload_ProtectWrite,a2)

;	ifeq	1
;	move.l	d7,d1
;	lsl.l	#2,d1
;	move.l	#$B,d2
;	bsr	_get_section

;	move.w	#$4ef9,$a4(a0)
;	lea	_checkcopymem(pc),a1
;	move.l	a1,$a6(a0)
;	endc



	IFD DEBUG1
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
.callprg
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

	IFEQ	0
_pl_program	PL_START
		PL_PS	$8a8,_remdiskaccess
		PL_P	$25a,_loopbne
		PL_P	$7726,_patchdoscall	;patch dosopen for skip ":"
		PL_DATA	$4db4,.loopdbfend-.loopdbfstart	;corr dbf delay
.loopdbfstart
		jsr	$88.W
.loopdbfend
		PL_DATA	$2ee,.intcorrend-.intcorr	;correct int ack
.intcorr
		dc.w	$70
.intcorrend	
				;set init rand to $80000 instead of $fc0000
		PL_DATA	$8be,.initrandplaceend-.initrandplace
.initrandplace	dc.w	$0008
.initrandplaceend
				;let random area wrap at $c0000
		PL_DATA	$5998,.wraprandplaceend-.wraprandplace
.wraprandplace	BTST	#2,$361.W
.wraprandplaceend
			;fix weird accesses (probably wrong programmed)
		PL_DATA	$4e16,.fix1end-.fix1
.fix1
		move.w	$3c6.w,$f8.w
.fix1end
		PL_DATA	$4e22,.fix2end-.fix2
.fix2
		move.w	$3ce.w,$fa.w
.fix2end
		PL_DATA	$4e2c,.fix3end-.fix3
.fix3
		move.w	$fa.w,d0
.fix3end
		PL_DATA	$4e48,.fix4end-.fix4
.fix4
		mulu.w	$f8.w,d0
.fix4end
		PL_END
	ENDC

; < d1 seglist
; < d2 section #
; > a0 segment
_get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts

_loopdbf
	divu.w	#$2d,d0
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

_patchdoscall
	bsr	_searchforcolon

	move.l	-$7aec(a4),a6		;orig instructions
	jmp	-$1e(a6)

_random	lea	RANDOM1(PC),A0
	MOVE.L	RANDOM1(PC),D0
	ADD.L	RANDOM2(PC),D0
	MOVE.L	D0,(A0)
	ROR.L	#$04,D0
	SUB.W	RANDOM2(PC),D0
	MOVE.L	D0,-(A7)
	MOVE.W	$DFF014,D0
	SWAP	D0
	MOVE.W	$DFF014,D0
	EOR.L	D0,(A7)
	MOVE.L	(A7)+,D0
	EOR.L	D0,RANDOM2-RANDOM1(A0)
	ADD.L	#$56565311,(A0)
	RTS

RANDOM1	DC.L	$3F3F751F
RANDOM2	DC.L	$17179834


;============================================================================


_editoractive
	dc.b	0
_traineractive
	dc.b	0
	EVEN

_whtags
	dc.l	WHDLTAG_CUSTOM1_GET
	dc.l	0
	dc.l	0

	END

