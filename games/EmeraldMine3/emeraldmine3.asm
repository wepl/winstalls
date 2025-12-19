;*---------------------------------------------------------------------------
;  :Program.	emeraldmine3.asm
;  :Contents.	Slave for "Emerald Mine 3"
;  :Author.	Harry
;  :History.	14.07.2012 started
;               21.07.2012 EMCD added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*


; game exe checksum is $6efd for IPF2707 and $375f for EMCD:_OLD_EM/3/
;hunklist game exe IPF2707
;hunknumber offset_in_exe length
;0 $28 $7278
;1 $7324 $470
;2 $77a0 0
;hunklist game exe EMCD
;hunknumber offset_in_exe length
;0 $28 $71bc
;1 $7268 $470
;2 $76e0 0



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
slv_name	dc.b	"Emerald Mine 3 Professional",0
slv_copy	dc.b	"1990 Kingsoft",0
slv_info	dc.b	"adapted by Harry",10
		dc.b	"Version 1.1 "
;	IFD BARFLY
;		INCBIN	"T:date"
;	ENDC
		dc.b	0
_program	dc.b	"em3",0
;_program2	dc.b	"newdef",0
_args		dc.b	10
_args_end
		dc.b	0
	EVEN

;d0 BSTR Filename
;d1 BPTR SegList

_cb_dosLoadSeg
;.2	bra.s	.2

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


_bootdos        move.l  (_resload,pc),a2        ;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;check version
		lea	(_program,pc),a0
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

		cmp.w	#$375f,d0
		beq	.versionokgameEMCD

		cmp.w	#$6efd,d0
		beq	.versionokgame2707
.nover		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.illegal	illegal

.versionokgame2707
		moveq.l	#0,d0
		bra.s	.versionok

.versionokgameEMCD
		moveq.l	#1,d0
.versionok
		lea	version(pc),a0
		move.b	d0,(a0)
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


;	illegal


		move.w	#$4ef9,$88.w
		lea	_loopdbf(pc),a0
		move.l	a0,$8a.w


	;patch
		move.b	version(pc),d0
		beq.s	.111
		lea	(_pl_program_emcd,pc),a0
		bra.s	.112
.111		lea	(_pl_program,pc),a0
.112		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

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

	IFEQ	0
;PL IPF2707
_pl_program	PL_START
		PL_PS	$456,_remdiskaccess
		PL_DATA	$498a,.loopdbfend-.loopdbfstart	;corr dbf delay
.loopdbfstart
		jsr	$88.W
.loopdbfend
				;set init rand to $80000 instead of $fc0000
		PL_DATA	$46c,.initrandplaceend-.initrandplace
.initrandplace	dc.w	$0008
.initrandplaceend
				;let random area wrap at $c0000
		PL_DATA	$558e,.wraprandplaceend-.wraprandplace
.wraprandplace	BTST	#2,$361.W
.wraprandplaceend
			;fix weird accesses (probably wrong programmed)
		PL_DATA	$49ec,.fix1end-.fix1
.fix1
		move.w	$3c6.w,$f8.w
.fix1end
		PL_DATA	$49f8,.fix2end-.fix2
.fix2
		move.w	$3ce.w,$fa.w
.fix2end
		PL_DATA	$4a02,.fix3end-.fix3
.fix3
		move.w	$fa.w,d0
.fix3end
		PL_DATA	$4a1e,.fix4end-.fix4
.fix4
		mulu.w	$f8.w,d0
.fix4end
			;correct stone shifting time due new random generator
.corrstoneshiftleft
		PL_PS	$51d8,_corrstoneshift
.corrstoneshiftleftend
.corrstoneshiftright
		PL_PS	$519e,_corrstoneshift
.corrstoneshiftrightend

		PL_END
;PL EMCD
_pl_program_emcd
		PL_START
		PL_PS	$45A,_remdiskaccess
		PL_DATA	$48CC,.loopdbfend-.loopdbfstart	;corr dbf delay
.loopdbfstart
		jsr	$88.W
.loopdbfend
				;set init rand to $80000 instead of $fc0000
		PL_DATA	$470,.initrandplaceend-.initrandplace
.initrandplace	dc.w	$0008
.initrandplaceend
				;let random area wrap at $c0000
		PL_DATA	$54D0,.wraprandplaceend-.wraprandplace
.wraprandplace	BTST	#2,$361.W
.wraprandplaceend
			;fix weird accesses (probably wrong programmed)
		PL_DATA	$492e,.fix1end-.fix1
.fix1
		move.w	$3c6.w,$f8.w
.fix1end
		PL_DATA	$493a,.fix2end-.fix2
.fix2
		move.w	$3ce.w,$fa.w
.fix2end
		PL_DATA	$4944,.fix3end-.fix3
.fix3
		move.w	$fa.w,d0
.fix3end
		PL_DATA	$4960,.fix4end-.fix4
.fix4
		mulu.w	$f8.w,d0
.fix4end
			;correct stone shifting time due new random generator
.corrstoneshiftleft
		PL_PS	$511a,_corrstoneshift
.corrstoneshiftleftend
.corrstoneshiftright
		PL_PS	$50e0,_corrstoneshift
.corrstoneshiftrightend

		PL_END
	ENDC

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

version	dc.b	0
	EVEN

	END

