;*---------------------------------------------------------------------------
;  :Program.	Flink.asm
;  :Contents.	Slave for "Flink" from Psygnosis
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	22.03.99/2.7.2000
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	asm-one:Include2.0/
	INCLUDE LIBRARIES/DOS_LIB.I
	INCLUDE	LIBRARIES/DOS.I
	INCLUDE EXEC/EXEC_LIB.I
	INCLUDE	EXEC/MEMORY.I
	INCLUDE	GRAPHICS/GRAPHICS_LIB.I
	INCLUDE INTUITION/INTUITION_LIB.I
	INCLUDE INTUITION/INTUITION.I
	INCLUDE	OWN/CCRMAKRO
	INCLUDE	own/whdload.i

	ifeq	1
	INCDIR	asm-one:include2.0/
	INCLUDE	lvo/exec_lib.i
	INCLUDE	lvo/dos_lib.i
	INCLUDE	lvo/graphics_lib.i
	INCLUDE	lvo/intuition_lib.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	whdload.i
	endc

;	OUTPUT	dh2:flink/Flink.slave
;	OPT	O+ OG+			;enable optimizing

Trainer		=	0	; 0-off, 1-on
Decruncher	=	0

;======================================================================
SLBASE
_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ReqAGA|WHDLF_Req68020	;ws_flags
		dc.l	$200000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-_base	;ws_GameLoader
		dc.w	dir-_base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$00		;ws_keydebug = F9
_keyexit	dc.b	$5D		;ws_keyexit = F10
		DC.L	0		;no fastmem
		dc.w	slname-SLBASE
		dc.w	slcr-SLBASE
		dc.w	slinst-SLBASE
***********************************************************************
slname		dc.b	'Flink',0
slcr		dc.b	'1994 Psygnosis',0
slinst		dc.b	'HD-V1.3 July 2000 by Mr.Larmer and Harry',0



	dc.b	'$VER: Flink CD32 HD by Mr.Larmer/Wanted Team - V1.3 (01.04.2000)',0
dir
	dc.b	'data',0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	A0,A2
		moveq	#CACRF_EnableI,d1
		move.l	d1,d0
		jsr	resload_SetCACR(a2)

;	ILLEGAL
		lea	_OSEmu(pc),A0		;file name
		lea	$5000.w,A1		;address
		jsr	resload_LoadFileDecrunch(a2)

		move.l	a2,a0
		lea	_base(pc),a1
		jsr	$5000.w

		move.w	#0,SR

		move.l	4.w,A6

		move.w	#$4EF9,D0
		pea	Return(pc)

		move.w	D0,_LVOReplyMsg(a6)
		move.l	(A7),_LVOReplyMsg+2(a6)
;		move.w	D0,_LVOCheckIO(a6)
;		move.l	(A7),_LVOCheckIO+2(a6)
;		move.w	D0,_LVOWaitIO(a6)
;		move.l	(A7),_LVOWaitIO+2(a6)
;		move.w	D0,_LVOAbortIO(a6)
;		move.l	(A7),_LVOAbortIO+2(a6)
		move.w	D0,_LVORawDoFmt(a6)
		move.l	(A7)+,_LVORawDoFmt+2(a6)

		moveq	#0,D0
		lea	DosNam(pc),A1
		move.l	4.w,A6
		jsr	_LVOOpenLibrary(a6)
		move.l	D0,A6

		lea	GameName(pc),A0
		move.l	A0,D1
		jsr	_LVOLoadSeg(a6)

		lsl.l	#2,D0
		addq.l	#4,D0
		move.l	D0,A1

	MOVEM.L	a1/a6,-(A7)		;alloc mem for blitter faults
	move.l	4,a6
	move.l	#$10000,d0
	moveq.l	#0,d1
	jsr	-198(a6)

	MOVEM.L	(A7)+,a1/a6

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

	ifne	Decruncher
		add.l	#$22BBE,A1
		move.w	#$4EF9,(A1)
		pea	Decrunch(pc)
		move.l	(a7)+,2(A1)
		sub.l	#$22BBE,A1
	endc

	MOVE.L	A1,A0			;REMOVE CRASH IN  SEVERAL SPELLS
	ADD.L	#$3C106-$19F08,A0
	MOVE.W	#$207B,(A0)

	ifne	Trainer

		move.w	#$6004,$78AE(a1)
		moveq	#$4A,d0
		move.b	d0,$7956(a1)
		move.l	a1,a0
		add.l	#$20000,a0
		move.b	d0,$18144-$20000(a0)
		move.b	d0,$19536-$20000(a0)
		move.b	d0,$1BCD4-$20000(a0)
		move.b	d0,$1BE62-$20000(a0)
		move.b	d0,$1C35A-$20000(a0)
		move.b	#12,$1C624-$20000(a0)
		move.b	#12,$1C898-$20000(a0)
		move.b	d0,$1C950-$20000(a0)
		move.b	#12,$1CC0E-$20000(a0)
		move.b	d0,$1CDD4-$20000(a0)
		move.b	d0,$1CEE2-$20000(a0)
		move.b	d0,$1D16E-$20000(a0)
		move.w	#$4E71,$20B56-$20000(a0)
	endc
		moveq	#0,D0
		sub.l	a0,a0

		jmp	(a1)
Decrunch
	ifne	Decruncher

		incbin	'NUKE'
	endc

	ifne	0

	movem.l	D2-D7/A3-A6,-(SP)
	moveq	#0,D0
	moveq	#0,D1
	move.w	#$8000,D2
	move.w	#$8000,D3
	moveq	#0,D4
	moveq	#0,D5
	moveq	#0,D6
	moveq	#0,D7
	movea.w	#$10,A3
	lea	lbW000178(PC),A6
	bsr.b	lbC00008E
	move.l	A0,D0
	movem.l	(SP)+,D2-D7/A3-A6
	rts

lbC00002C:
	dbra	D5,lbC000036
	moveq	#7,D5
	move.l	(A5)+,D4
	add.l	D4,D4
lbC000036:
	moveq	#$1E,D0
	and.w	D4,D0
	roxr.l	#4,D4
	move.w	0(A6,D0.W),D1
	asl.l	D1,D6
	sub.w	D1,D7
	bcc.s	lbC000054
	moveq	#0,D1
	move.w	(A5)+,D1
	neg.w	D7
	asl.l	D7,D1
	or.l	D1,D6
	neg.w	D7
	add.w	A3,D7
lbC000054:
	swap	D6
	movea.l	A0,A1
	add.w	$20(A6,D0.W),D6
	suba.w	D6,A1
	clr.w	D6
	swap	D6
	move.w	$40(A6,D0.W),D0
	jmp	lbC00006A(PC,D0.W)

lbC00006A:
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	moveq	#0,D0
	add.w	D3,D3
	bne.s	lbC00007A
	move.w	(A5)+,D3
	addx.w	D3,D3
lbC00007A:
	addx.w	D0,D0
	add.w	D3,D3
	addx.w	D0,D0
	add.w	D0,D0
	jmp	lbC000086(PC,D0.W)

lbC000086:
	bra.s	lbC0000F2

	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
lbC00008E:
	add.w	D2,D2
	bne.s	lbC000096
	move.w	(A5)+,D2
	addx.w	D2,D2
lbC000096:
	bcs.s	lbC00002C
	add.w	D2,D2
	bne.s	lbC0000A0
	move.w	(A5)+,D2
	addx.w	D2,D2
lbC0000A0:
	bcc.s	lbC0000B0
	move.b	-(A4),(A0)+
	cmpa.l	A2,A0
	blt.s	lbC00002C
	rts

lbC0000AA:
	move.b	-(A4),(A0)+
	move.b	-(A4),(A0)+
	move.b	-(A4),(A0)+
lbC0000B0:
	moveq	#0,D0
	add.w	D3,D3
	bne.s	lbC0000BA
	move.w	(A5)+,D3
	addx.w	D3,D3
lbC0000BA:
	addx.w	D0,D0
	add.w	D3,D3
	addx.w	D0,D0
	add.w	D0,D0
	jmp	lbC0000C6(PC,D0.W)

lbC0000C6:
	bra.s	lbC0000AA

	move.b	-(A4),(A0)+
	move.b	-(A4),(A0)+
	move.b	-(A4),(A0)+
	move.b	-(A4),(A0)+
	cmpa.l	A2,A0
	blt.w	lbC00002C
	rts

lbC0000D8:
	moveq	#0,D0
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
lbC0000F2:
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	move.b	(A1)+,(A0)+
	tst.b	D0
	bne.s	lbC00008E
	dbra	D5,lbC000106
	moveq	#7,D5
	move.l	(A5)+,D4
	add.l	D4,D4
lbC000106:
	moveq	#$1E,D0
	and.w	D4,D0
	roxr.l	#4,D4
	jmp	lbC0000D8(PC,D0.W)

	dc.w	0,0,4,10,$10,$40,$100,$200,$10,$80,$200,$800
	dc.w	$2000,$4000,$20,$80,$200,$800,$2000,$4000,4,6,8,9
	dc.w	4,7,9,11,13,14,5,7,9,11,13,14,0,1,2,3,4,5,6,7,8,9
	dc.w	10,11,12,13,14,15
lbW000178:
	dc.w	4,6,8,9,4,7,9,11,13,14,5,7,9,11,13,14,0,$10,$50
	dc.w	$150,0,$10,$90,$290,$A90,$2A90,0,$20,$A0,$2A0
	dc.w	$AA0,$2AA0,$20,$20,$20,$20,$1E,$1E,$1E,$1E,$1E
	dc.w	$1E,0,0,0,0,0,0,0

	endc

Return
		moveq	#0,d0
		rts
DosNam
		dc.b	'dos.library',0
GameName
		dc.b	'flink',0
		even

;--------------------------------

_resload	dc.l	0		;address of resident loader
_OSEmu		dc.b	'OSEmu.5000',0

;======================================================================

	END
