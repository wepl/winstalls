;*---------------------------------------------------------------------------
;  :Program.	powermonger.asm
;  :Contents.	Slave for "PowerMonger"
;  :Author.	BJ
;  :Version.	$Id$
;  :History.	20.05.96
;		09.12.96 reworked for diskimages and clean media
;		30.12.96 ws_DontCache removed (WARNING ws_Version is only 1)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	OUTPUT	wart:powermonger/powermonger.slave
	BOPT	O+ OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	SUPER

;======================================================================

	IFD FILES
.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	1		;ws_Version
		dc.w	0		;ws_flags
		dc.l	$80000		;size of mem required by game
		dc.l	$48e00		;address in BaseMem where space is for a fake ExecLibrary
					;installed by the Loader to survive a RESET
					;for example $400, required are 84 Bytes
		dc.w	_Start-.base	;start of resident loader
					;must 100% pc-relative (HD-Loader will move this
					;outside BaseMem)
					;will called in SuperVisor mode
		dc.w	_data-.base	;directory in which the mainloader should search for files
		dc.w	0		;pattern file without caching

_data		dc.b	"data",0
	EVEN
	ELSE
.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	1		;ws_Version
		dc.w	WHDLF_Disk	;ws_flags
		dc.l	$80000		;size of mem required by game
		dc.l	$48e00		;address in BaseMem where space is for a fake ExecLibrary
		dc.w	_Start-.base	;start of resident loader
		dc.w	0		;directory in which the mainloader should search for files
		dc.w	0		;pattern file without caching
	ENDC

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)

		move.l	#CACRF_EnableI,d0
		move.l	d0,d1
		jsr	(resload_SetCACR,a0)
		
DIR = $400
		move.l	#$1600,d0
		move.l	#512,d1
		moveq	#1,d2
		lea	DIR,a0
		bsr	_LoadDisk

		LEA	$00DFF000.L,A6
		MOVE	#$2000,SR
		MOVEA.L	#$0007FFFC,A7
		LEA	L_398(PC),A0
		MOVEA.L	#$00022674,A1
		JSR	_Loader
		LEA	L_3A0(PC),A0
		MOVEA.L	#$00001000,A1
		JSR	_Loader
		JSR	$1000.W

		lea	_custom,a6
		moveq	#-2,d0
		lea	$300,a0
		move.l	d0,(a0)
		move.l	a0,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		move	#$7fff,(intena,a6)
		move	#$7fff,(dmacon,a6)
		
		LEA	L_3A8(PC),A0
	;	MOVEA.L	#$00001400,A1
		MOVEA.L	#$00001000,A1
		JSR	_Loader

		cmp.l	#$227c0000,(4,a1)
		beq	.o
		cmp.l	#$61064cdf,(4,a1)
		bne	_exit

		patch	$b6(a1),.ad
		jmp	(4,a1)			;decrunch the shit
.o
		ret	$14(a1)
		jsr	(4,a1)			;decrunch the shit
.ad

	move.w	#$7000,$1400+$aca0
;	lea	$1440+$b36c,a0

	nops	3,$1474			;check for exp mem

;	patch	$582+$1400,_keyboard
	
	patch	$dd94,_load_dd94
	
;	ill	$e148		;endlos loop wenn error in decrunching
;	bad because will entered in extro

	patch	$1a2d0+$1400,$1a36e+$1400	;insert powermonger-disk

	ret	$1bdfa				;format save-disk
	ill	$1ac02+$1400
	
	patch	$1bf2e,_loadsavegame
	patch	$1ac54+$1400,_savesavegame
	
;	nops	5,$1a3ca+$1400			;btst #4,bfdd00, beq again
;	ret	$1ba7e		;loader ??
;	ret	$1b910		;init bfd100
;	ret	$1a67e+$1400	;check dirlist
	
		Jsr	$1400.W
		bra	_exit
		
;--------------------------------

 IFEQ 1
	MOVEM.L	D1-D5/D7-A2,-(A7)
L_1AB32	MOVE.W	#$0090,$00001FF4.L
	JSR	$0001C1EA.L		;REQ insert savedisk
	TST.W	D0
	BNE.W	L_1AC2E
	JSR	$0001BADE.L		;load bootblock
	TST.W	D0
	BNE.B	L_1AB5A
	JSR	$0001C202.L		;REQ is not savedisk
	BRA.W	L_1AB32
L_1AB5A	LEA	$000258FE.L,A0
	CLR.L	D1
	MOVE.B	$0000E093.L,D1		;letter of saveplace
	SUBI.B	#$0041,D1
	TST.B	(A0,D1.W)
	BNE.B	L_1AB7C
	JSR	$0001C222.L		;REQ savegame does not exist
	BRA.W	L_1AB32
L_1AB7C	MOVE.L	#$0006577C,D2
	MOVEA.L	D2,A1
	MOVE.L	#$0007E35D,D3
	SUB.L	D2,D3
	MOVE.L	D3,D4
	DIVU	#$1600,D4
	ADDI.L	#1,D4
	EXT.L	D4
	MULU	D4,D1
	ADDI.W	#2,D1
	CMPI.L	#$0000002C,$0001473C.L
	BEQ.B	L_1ABB8
	MOVE.L	#$000648EA,D2
	MOVE.L	#$000000C4,D3
L_1ABB8	JSR	$0001B8E6.L
	JSR	$0001B922.L
	JSR	$0001BA26.L
	MOVE.L	D1,D0
	JSR	$0001B992.L
L_1ABD2	JSR	$0001B992.L
	MOVE.B	D0,$00021D96.L
	JSR	$0001B772.L
	TST.L	D7
	BEQ.B	L_1AC22
	JSR	$0001B80C.L
	TST.L	D7
	BEQ.B	L_1AC22
	ADDI.L	#1,D0
	LEA	$0001FC1E.L,A2
	MOVE.W	#$057F,D5
L_1AC02	MOVE.L	(A2)+,(A1)+
	SUBI.L	#4,D3
	BLE.B	L_1AC14
	DBRA	D5,L_1AC02
	DBRA	D4,L_1ABD2
L_1AC14	JSR	$0001B910.L
	MOVE.L	#$FFFFFFFF,D0
	BRA.B	L_1AC34
L_1AC22	CLR.L	D0
	JSR	$0001C22A.L		;REQ read error
	BRA.W	L_1AB32
L_1AC2E	JSR	$0001C212.L		;REQ loading canceled
L_1AC34	CLR.L	$0002138E.L
	JSR	$0001B6D0.L		;insert pm-disk
	MOVE.W	#0,$00001FF4.L
	JSR	$0001B910.L
	MOVEM.L	(A7)+,D1-D5/D7-A2
	RTS	
 ENDC

_loadsavegame
	movem.l	d1/a0-a2,-(a7)
;	MOVE.W	#$0090,$00001FF4.L	;switch to black bg
	lea	_letter,a0
	MOVE.B	$0000E093.L,(a0)	;letter of saveplace
	lea	_fname,a0
	lea	$6577c,a1
	
		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)
		tst.l	d1
		beq	.end

	JSR	$0001C222.L		;REQ savegame does not exist
	moveq	#0,d0

.end
;	MOVE.W	#0,$00001FF4.L		;switch to game bg
	movem.l	(a7)+,d1/a0-a2
	rts

 IFEQ 1
L_1AC58	MOVE.W	#$0090,$00001FF4.L
	JSR	$0001C1EA.L		;REQ insert savedisk
	TST.W	D0
	BNE.W	L_1ADC4
	JSR	$0001BADE.L		;check for savedisk
	TST.W	D0
	BNE.W	L_1AC82
	JSR	$0001C202.L		;REQ is not savedisk
	BRA.W	L_1AC58
L_1AC82	BTST	#3,$00BFE001.L
	BNE.B	L_1AC9A
	JSR	$0001C23A.L		;REQ disk write protected
	TST.W	D0
	BEQ.B	L_1AC58
	BRA.W	L_1ADC4
L_1AC9A	LEA	$000258FE.L,A0
	CLR.L	D1
	MOVE.B	$0000E093.L,D1
	SUBI.B	#$0041,D1
	TST.B	(A0,D1.W)
	BEQ.B	L_1ACBE
	JSR	$0001C1FA.L		;REQ savegame already exist
	TST.W	D0
	BNE.W	L_1ADC4
L_1ACBE	MOVE.L	#$0006577C,D2
	MOVEA.L	D2,A1
	MOVE.L	#$0007E35D,D3
	SUB.L	D2,D3
	MOVE.L	D3,D4
	DIVU	#$1600,D4
	ADDI.L	#1,D4
	EXT.L	D4
	MULU	D4,D1
	ADDI.W	#2,D1
	JSR	$0001B8E6.L
	JSR	$0001B922.L
	JSR	$0001BA26.L
	MOVE.L	D1,D0
	JSR	$0001B992.L
	SUBI.W	#1,D4
L_1AD00	LEA	$00021D9E.L,A0
	MOVE.W	#$0ED7,D5
L_1AD0A	MOVE.L	#$AAAAAAAA,(A0)+
	DBRA	D5,L_1AD0A
	LEA	$0001FC1E.L,A2
	MOVE.W	#$057F,D5
L_1AD1E	MOVE.L	(A1)+,(A2)+
	DBRA	D5,L_1AD1E
	MOVE.L	D1,-(A7)
	MOVE.B	D0,$00021D96.L
	JSR	$0001B992.L
	JSR	$0001BA26.L
	JSR	$0001BC2E.L
	JSR	$0001BB62.L
	ADDI.W	#1,D0
	MOVE.L	(A7)+,D1
	DBRA	D4,L_1AD00
	JSR	$0001B922.L
	JSR	$0001BA26.L
	LEA	$00021D9E.L,A0
	MOVE.W	#$0ED7,D5
L_1AD64	MOVE.L	#$AAAAAAAA,(A0)+
	DBRA	D5,L_1AD64
	LEA	$000258FE.L,A2
	CLR.L	D0
	MOVE.B	$0000E093.L,D0
	SUBI.B	#$0041,D0
	MOVE.B	#1,(A2,D0.W)
	LEA	$0001FC1E.L,A1
	MOVE.L	#$53415645,(A1)+
	MOVE.L	(A2)+,(A1)+
	MOVE.L	(A2)+,(A1)+
	CLR.L	D0
	MOVE.L	D1,-(A7)
	MOVE.B	D0,$00021D96.L
	JSR	$0001B992.L
	JSR	$0001BA26.L
	JSR	$0001BC2E.L
	JSR	$0001BB62.L
	MOVE.L	(A7)+,D1
	JSR	$0001B910.L
	BRA.B	L_1ADCA
	DC.W	$4280
L_1ADC4	JSR	$0001C20A.L
L_1ADCA	CLR.L	$0002138E.L
	JSR	$0001B6D0.L
	MOVE.W	#0,$00001FF4.L
	JSR	$0001B910.L
	MOVEM.L	(A7)+,D1-D5/D7-A2
	RTS	
_1adea	LEA	$0002138E.L,A0

 ENDC

_savesavegame
	movem.l	d1/a0-a2,-(a7)
;	MOVE.W	#$0090,$00001FF4.L
	lea	_letter,a0
	MOVE.B	$0000E093.L,(a0)	;letter of saveplace

	lea	_fname,a0
		move.l	(_resload),a2
		jsr	(resload_CheckFileExist,a2)
	tst.l	d0
	beq	.go
	JSR	$0001C1FA.L		;REQ savegame already exist
	TST.W	D0
	BNE	.end
.go
	move.l	#$18be1,d0	;size
	lea	_fname,a0
	lea	$6577c,a1
		bsr	_Save

.end
	MOVE.W	#0,$00001FF4.L
	movem.l	(a7)+,d1/a0-a2
	rts
	
_fname	dc.b	"save/"
_letter	dc.b	0,0
	EVEN

;--------------------------------

_load_dd94	movem.l	d0-a6,-(a7)
		move.w	($40,a7),d2		;number of file
		bne	.g
		move.l	#$000535ea,d3
		add.l	#$80,d3
		and.l	#$ffffff80,d3
		move.l	d3,$f858
		move.l	d3,$df0a
.g		lea	$df06,a2
		moveq	#$c,d0
		mulu	d2,d0
		add.w	d0,a2
		movem.l	(a2),a0-a1		;name + location
		bsr	_Loader
		move.l	d0,(8,a2)		;filesize
		move.l	a2,a1
		jmp	$ca10+$1400
		
;--------------------------------

_kinit		movem.l	a0-a1,-(a7)
		lea	(_keyboard,pc),a1
		cmp.l	$68,a1
		beq	.q
		lea	(_realint68,pc),a0
		move.l	$68,(a0)
		move.l	a1,$68
.q		movem.l	(a7)+,a0-a1
		rts

_realint68	dc.l	0

_keyboard	move.l	d0,-(a7)
		move.b	$bfec01,d0
		ror.b	#1,d0
		not.b	d0

; RAW-Key-Codes:
;	ESC	$45
;	DEL	$46
;	F1..F10	$50..$59
;	HELP	$5f

		cmp.b	#$58,d0
		bne	.1
		move.l	(a7)+,d0
		bra	_debug			;coredump & quit
.1
		cmp.b	#$59,d0
		beq	_exit			;exit
		cmp.b	#$45,d0
		beq	_exit			;exit

		move.l	(a7)+,d0
		move.l	(_realint68),-(a7)	;enter orginal rou.
		rts

;--------------------------------

	IFD FILES
_Loader		move.l	a2,-(a7)
		lea	.buf,a2
		move.l	(a0)+,(a2)+
		move.l	(a0),(a2)
		move.l	(a7)+,a2
		lea	.buf,a0
		bsr	_Load
		move.l	d0,d7
		bra	_kinit

.buf		ds.b	10
	ENDC
	
_Loader		movem.l	d1-d2/a0-a1,-(a7)

		move.l	(a0)+,d0
		move.l	(a0),d1
		move.l	a1,a0
		lea	DIR,a1
.find		add.w	#16,a1
		cmp.l	(a1),d0
		bne	.find
		cmp.l	(4,a1),d1
		bne	.find
		move.w	(8,a1),d0
		mulu.w	#11*512,d0
		move.l	(12,a1),d1
		move.l	d1,-(a7)		;size of file
		moveq	#1,d2
		bsr	_LoadDisk
		move.l	(a7)+,d0		;size is return value

		movem.l	(a7)+,d1-d2/a0-a1
		bra	_kinit

;--------------------------------

L_398		DC.B	'INTRODAT'
L_3A0		DC.B	'START_UP'
L_3A8		DC.B	'RUN_PROG'
_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	a0 = name  a1 = location
; OUT:	d0 = size

_Load		movem.l	d1-d2/a0-a2,-(a7)
		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)
		tst.l	d1
		bne	.err
		tst.l	d0		;filesize = 0 ??
		beq	.err
		movem.l	(a7)+,d1-d2/a0-a2
		rts
.err		move.l	d1,d0
		movem.l	(a7)+,d1-d2/a0-a2
		move.l	a0,-(a7)		;filename
		move.l	d0,-(a7)		;doserror
		move.l	#TDREASON_DOSREAD,-(a7)
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------
; IN:	d0 = length  a0 = name  a1 = location
; OUT:  d0 = succ

_Save		movem.l	d1-d2/a0-a2,-(a7)
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
		tst.l	d0
		beq	.err
		movem.l	(a7)+,d1-d2/a0-a2
		rts
.err		move.l	d1,d0
		movem.l	(a7)+,d1-d2/a0-a2
		move.l	a0,-(a7)		;filename
		move.l	d0,-(a7)		;doserror
		move.l	#TDREASON_DOSWRITE,-(a7)
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d2/a0-a2,-(a7)
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		tst.l	d0
		beq	.err
		movem.l	(a7)+,d0-d2/a0-a2
		moveq	#-1,d0
		rts
		
.err		move.l	d1,-(a7)
		movem.l	(4,a7),d0-d2/a0-a2
		move.l	d2,(4+5*4,a7)		;disk number
		move.l	(a7),(4+4*4,a7)		;doserror
		add.w	#4+4*4,a7
		move.l	#TDREASON_DISKLOAD,-(a7)
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------

_exit		move.l	#TDREASON_OK,-(a7)
		bra	_end
_debug		move.l	#TDREASON_DEBUG,-(a7)
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	END
