;*---------------------------------------------------------------------------
;  :Program.	tech.asm
;  :Contents.	Slave for "Tech"
;  :Author.	BJ
;  :Version.	$Id$
;  :History.	08.03.97
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	OUTPUT	wart:tech/tech.slave
	BOPT	O+ OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	SUPER

;======================================================================

.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	2		;ws_Version
		dc.w	WHDLF_NoError	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	$400		;ws_ExecInstall
		dc.w	.Start-.base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache

;======================================================================
.Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)

		move.l	#CACRF_EnableI,d0
		move.l	d0,d1
		move.l	(_resload),a2
		jsr	(resload_SetCACR,a2)
	
		lea	_main,a0
		lea	$21b00,a1
		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)
		
		bsr	_emul_os

		lea	$7ec00,a4	;trainer start



		moveq	#0,d0
		move.l	#CACRF_EnableI,d1
		move.l	(_resload),a2
		jsr	(resload_SetCACR,a2)

;	illegal
		
		jmp	($342,a4)	;game
		jmp	(a4)		;trainer
	
;--------------------------------

LIBSTART	= $400

	INCLUDE	exec/execbase.i
	INCLUDE	lvo/exec.i
	INCLUDE	graphics/gfxbase.i
	INCLUDE	lvo/graphics.i
	INCLUDE	lvo/dos.i
	INCLUDE	utility/utility.i
	INCLUDE	lvo/utility.i
	INCLUDE	lvo/layers.i
	
SETFUNC	MACRO
	lea	\1,a0
	move.l	a0,2+\2
	ENDM

EXEC_LIB_LEN	= -(_LVOexecPrivate15)
EXEC_DAT_LEN	= SYSBASESIZE
GFX_LIB_LEN	= -(_LVOWriteChunkyPixels)
GFX_DAT_LEN	= gb_SIZE
DOS_LIB_LEN	= -(_LVOSetOwner)
DOS_DAT_LEN	= LIB_SIZE
UTIL_LIB_LEN	= -(_LVOGetUniqueID)
UTIL_DAT_LEN	= ub_Reserved+1
LAYERS_LIB_LEN	= -(_LVODoHookClipRects)
LAYERS_DAT_LEN	= $26+4

;--------------------------------

_emul_os	lea	LIBSTART,a6		;A6 = free
		bsr	_emul_exec
		bsr	_emul_util
		bsr	_emul_layers
		bsr	_emul_gfx
		bsr	_emul_dos
	;layers
		move.l	_layersbase,a0
		move.l	_gfxbase,$22(a0)	;gfxbase
		move.l	_execbase,$26(a0)	;execbase
	;graphics
		move.l	_gfxbase,a0
		move.l	_utilbase,gb_UtilBase(a0)
		move.l	_execbase,gb_ExecBase(a0)
		move.l	_layersbase,gb_LayersBase(a0)
	;system
		move.l	_execbase,a0
		move.l	a0,4
		
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,_custom+dmacon
		
		rts

;--------------------------------

_emul_exec	lea	(EXEC_LIB_LEN,a6),a5	;A5 = execbase
		lea	_execbase,a0
		move.l	a5,(a0)
		move.l	#EXEC_LIB_LEN,d0
		move.l	#EXEC_DAT_LEN,d1
		move.l	a6,a0
		bsr	_MakeLib
		lea	(EXEC_DAT_LEN,a5),a6	;A6 = free
		SETFUNC	.forbid,_LVOForbid(a5)
		SETFUNC	.permit,_LVOPermit(a5)
		SETFUNC	.oldopenlibrary,_LVOOldOpenLibrary(a5)
		rts
.forbid
.permit		rts
.oldopenlibrary	move.l	_gfxbase,d0
		lea	.gfxname,a0
		bsr	.ool_cmp
		beq	.ool_f
		move.l	_dosbase,d0
		lea	.dosname,a0
		bsr	.ool_cmp
		beq	.ool_f
		move.l	_utilbase,d0
		lea	.utilname,a0
		bsr	.ool_cmp
		beq	.ool_f
		bra	_BadFunc
.ool_f		rts
.ool_cmp	move.l	a1,-(a7)
.ool_0		cmp.b	(a0)+,(a1)+
		bne	.ool_1
		tst.b	(-1,a0)
		bne	.ool_0
.ool_1		move.l	(a7)+,a1
		rts

.dosname	dc.b	"dos.library",0
.gfxname	dc.b	"graphics.library",0
.utilname	UTILITYNAME
	EVEN

_execbase	dc.l	0

;--------------------------------

_emul_util	lea	(UTIL_LIB_LEN,a6),a5	;A5 = utilbase
		lea	_utilbase,a0
		move.l	a5,(a0)
		move.l	#UTIL_LIB_LEN,d0
		move.l	#UTIL_DAT_LEN,d1
		move.l	a6,a0
		bsr	_MakeLib
		lea	(UTIL_DAT_LEN,a5),a6	;A6 = free
		rts

_utilbase	dc.l	0

;--------------------------------

_emul_layers	lea	(LAYERS_LIB_LEN,a6),a5	;A5 = layersbase
		lea	_layersbase,a0
		move.l	a5,(a0)
		move.l	#LAYERS_LIB_LEN,d0
		move.l	#LAYERS_DAT_LEN,d1
		move.l	a6,a0
		bsr	_MakeLib
		lea	(LAYERS_DAT_LEN,a5),a6	;A6 = free
		SETFUNC	_dohookcliprects,_LVODoHookClipRects(a5)
		rts

_dohookcliprects
		MOVE.L	A0,D0
		SUBQ.L	#1,D0
		BNE.B	L_2944
		RTS	
L_2944		MOVEM.L	D2-D7/A2-A5,-(A7)
		MOVE.L	A2,D6
		MOVEA.L	(A1),A2
		MOVE.L	A0,D7
		MOVE.L	A1,D5
		MOVE.L	4(A1),-(A7)
		SUBQ.L	#8,A7
		MOVE.L	A2,D4
		BNE.B	L_2970
		MOVEA.L	D7,A0
		MOVEA.L	D4,A1
		MOVEA.L	D5,A2
		MOVEA.L	D6,A3
		MOVEA.L	D6,A4
		MOVEQ	#0,D2
		MOVEQ	#0,D3
		PEA	L_2A7E(PC)
		BRA.W	L_2A96
L_2970		MOVEA.L	A2,A1
		BSR.W	L_2CA4
		MOVE.W	$0010(A2),D2
		SUB.W	$002C(A2),D2
		MOVE.W	$0012(A2),D3
		SUB.W	$002E(A2),D3
		MOVEA.L	A7,A1
		MOVEA.L	D6,A0
		MOVE.L	D6,-(A7)
		BEQ.B	L_29A8
		MOVE.L	A1,D6
		MOVE.W	(A0)+,D0
		ADD.W	D2,D0
		MOVE.W	D0,(A1)+
		MOVE.W	(A0)+,D0
		ADD.W	D3,D0
		MOVE.W	D0,(A1)+
		MOVE.W	(A0)+,D0
		ADD.W	D2,D0
		MOVE.W	D0,(A1)+
		MOVE.W	(A0)+,D0
		ADD.W	D3,D0
		MOVE.W	D0,(A1)+
L_29A8		LEA	8(A2),A5
		SUBQ.L	#8,A7
L_29AE		MOVE.L	(A5),D0
		BEQ.B	L_2A2E
		MOVEA.L	D0,A5
		LEA	$0010(A5),A3
		TST.L	D6
		BEQ.B	L_29D4
		MOVEA.L	A3,A0
		MOVEA.L	D6,A1
		MOVEA.L	A7,A2
		BSR.W	L_2BA4
		MOVE.L	(A2)+,D0
		MOVE.L	(A2)+,D1
		CMP.W	D0,D1
		BLT.B	L_29AE
		CMP.L	D0,D1
		BLT.B	L_29AE
		MOVEA.L	A7,A3
L_29D4		MOVEA.L	A3,A4
		MOVEA.L	D4,A1
		MOVEA.L	D7,A0
		MOVEA.L	D5,A2
		TST.L	8(A5)
		BNE.B	L_29E8
		BSR.W	L_2A96
		BRA.B	L_29AE
L_29E8		TST.L	$000C(A5)
		BEQ.B	L_29AE
		MOVEQ	#$000F,D1
		AND.W	$0010(A5),D1
		SUB.W	$0010(A5),D1
		MOVE.W	4(A4),D0
		ADD.W	D1,D0
		SWAP	D0
		MOVE.W	6(A4),D0
		SUB.W	$0012(A5),D0
		MOVE.L	D0,-(A7)
		ADD.W	(A4),D1
		SWAP	D1
		MOVE.W	2(A4),D1
		SUB.W	$0012(A5),D1
		MOVE.L	D1,-(A7)
		MOVEA.L	A7,A3
		MOVE.L	4(A2),-(A7)
		MOVE.L	$000C(A5),4(A2)
		BSR.B	L_2A96
		MOVE.L	(A7)+,4(A2)
		ADDQ.L	#8,A7
		BRA.B	L_29AE
L_2A2E		ADDQ.L	#8,A7
		MOVE.L	(A7)+,D6
		MOVEA.L	D4,A2
		MOVE.L	$0020(A2),D0
		BEQ.B	L_2A7E
		MOVEA.L	D5,A0
		MOVE.L	D0,4(A0)
		MOVEQ	#0,D2
		MOVEQ	#0,D3
		LEA	$0024(A2),A5
L_2A48		MOVE.L	(A5),D0
		BEQ.B	L_2A7E
		MOVEA.L	D0,A5
		LEA	$0010(A5),A3
		TST.L	D6
		BEQ.B	L_2A72
		MOVEA.L	A3,A0
		MOVEA.L	D6,A1
		MOVEA.L	A7,A2
		BSR.W	L_2BA4
		MOVE.L	(A2)+,D0
		MOVE.L	(A2)+,D1
		CMP.W	D0,D1
		BLT.B	L_2A48
		SWAP	D0
		SWAP	D1
		CMP.W	D0,D1
		BLT.B	L_2A48
		MOVEA.L	A7,A3
L_2A72		MOVEA.L	A3,A4
		MOVEA.L	D4,A1
		MOVEA.L	D7,A0
		MOVEA.L	D5,A2
		BSR.B	L_2A96
		BRA.B	L_2A48
L_2A7E		ADDQ.L	#8,A7
		MOVEA.L	D5,A0
		MOVE.L	(A7)+,4(A0)
		TST.L	D4
		BEQ.B	L_2A90
		MOVEA.L	D4,A0
		BSR.W	L_2CB6
L_2A90		MOVEM.L	(A7)+,D2-D7/A2-A5
		RTS	
L_2A96		MOVE.L	A0,D0
		BEQ.B	L_2B0C
		SUBQ.L	#1,D0
		BNE.B	L_2AA0
		RTS	
L_2AA0		MOVE.W	2(A4),D0
		SUB.W	D3,D0
		EXT.L	D0
		MOVE.L	D0,-(A7)
		MOVE.W	(A4),D0
		SUB.W	D2,D0
		EXT.L	D0
		MOVE.L	D0,-(A7)
		MOVE.L	4(A3),-(A7)
		MOVE.L	(A3),-(A7)
		MOVE.L	A1,-(A7)
		MOVEA.L	A7,A1
		MOVE.L	A6,-(A7)
		MOVEA.L	8(A0),A6
		JSR	(A6)
		MOVEA.L	(A7)+,A6
		LEA	$0014(A7),A7
		RTS	
L_2B0C		MOVEM.L	D2-D7/A6,-(A7)
		MOVEA.L	4(A2),A1
		MOVEA.L	A1,A0
		MOVEQ	#0,D2
		MOVE.W	(A3),D2
		MOVEQ	#0,D3
		MOVE.W	2(A3),D3
		MOVEQ	#0,D4
		MOVE.W	4(A3),D4
		SUB.L	D2,D4
		ADDQ.L	#1,D4
		MOVEQ	#0,D5
		MOVE.W	6(A3),D5
		SUB.L	D3,D5
		ADDQ.L	#1,D5
		MOVE.L	D2,D0
		MOVE.L	D3,D1
		MOVEQ	#0,D6
		MOVEQ	#-1,D7
		MOVEA.L	$0022(A6),A6
		JSR	_LVOBltBitMap(A6)
		MOVEM.L	(A7)+,D2-D7/A6
		RTS	
L_2BA4		MOVE.L	A2,-(A7)
		MOVE.W	(A0)+,D0
		MOVE.W	(A1)+,D1
		CMP.W	D0,D1
		BLE.B	L_2BB0
		MOVE.W	D1,D0
L_2BB0		MOVE.W	D0,(A2)+
		MOVE.W	(A0)+,D0
		MOVE.W	(A1)+,D1
		CMP.W	D0,D1
		BLE.B	L_2BBC
		MOVE.W	D1,D0
L_2BBC		MOVE.W	D0,(A2)+
		MOVE.W	(A0)+,D0
		MOVE.W	(A1)+,D1
		CMP.W	D0,D1
		BGE.B	L_2BC8
		MOVE.W	D1,D0
L_2BC8		MOVE.W	D0,(A2)+
		MOVE.W	(A0)+,D0
		MOVE.W	(A1)+,D1
		CMP.W	D0,D1
		BGE.B	L_2BD4
		MOVE.W	D1,D0
L_2BD4		MOVE.W	D0,(A2)+
		MOVEA.L	(A7)+,A2
		RTS	
L_2CA4		MOVE.L	A6,-(A7)
		LEA	$0048(A1),A0
		MOVEA.L	$0026(A6),A6
		JSR	_LVOObtainSemaphore(A6)
		MOVEA.L	(A7)+,A6
		RTS	
L_2CB6		MOVE.L	A6,-(A7)
		LEA	$0048(A0),A0
		MOVEA.L	$0026(A6),A6
		JSR	_LVOReleaseSemaphore(A6)
		MOVEA.L	(A7)+,A6
		RTS	

_layersbase	dc.l	0

;--------------------------------

_emul_gfx	lea	(GFX_LIB_LEN,a6),a5	;A5 = gfxbase
		lea	_gfxbase,a0
		move.l	a5,(a0)
		move.l	#GFX_LIB_LEN,d0
		move.l	#GFX_DAT_LEN,d1
		move.l	a6,a0
		bsr	_MakeLib
		lea	(GFX_DAT_LEN,a5),a6	;A6 = free
		SETFUNC	_initbitmap,_LVOInitBitMap(a5)
		SETFUNC	_initrastport,_LVOInitRastPort(a5)
		SETFUNC	_setfont,_LVOSetFont(a5)
		SETFUNC	_setapen,_LVOSetAPen(a5)
		SETFUNC	_rectfill,_LVORectFill(a5)
		SETFUNC	_bltpattern,_LVOBltPattern(a5)
		SETFUNC	_disownblitter,_LVODisownBlitter(a5)
	;	move.l	#xxxx,gb_DefaultFont(a5)
		move.w	#-1,gb_BlitLock(a5)		;blitter is free
		rts

_initbitmap	clr.b	4(a0)
		clr.w	6(a0)
		move.w	d2,2(a0)
		move.b	d0,5(a0)
		add.w	#15,d1
		asr.w	#4,d1
		add.w	d1,d1
		move.w	d1,(a0)
		rts
L_6C78		MOVEA.L	A1,A0
		MOVEQ	#$004E,D0
		BSR.W	L_7308
		MOVEQ	#-1,D0
		MOVE.B	D0,$0018(A1)
		MOVE.B	D0,$0019(A1)
		MOVE.B	D0,$001B(A1)
		MOVE.W	D0,$0022(A1)
		MOVE.B	#1,$001C(A1)
		BRA.W	L_D5A8
_initrastport	BSR.B	L_6C78
		MOVEA.L	gb_DefaultFont(A6),A0
		JMP	_LVOSetFont(A6)
L_7308		MOVE.W	D0,D1
		AND.W	#-4,D1
		SUB.W	D1,D0
		ASR.W	#2,D1
		SUBQ.W	#1,D1
		BLT.B	L_731C
L_7316		CLR.L	(A0)+
		DBRA	D1,L_7316
L_731C		TST.W	D0
		BEQ.B	L_7328
		SUBQ.B	#1,D0
L_7322		CLR.B	(A0)+
		DBRA	D0,L_7322
L_7328		RTS	
L_D5A8		MOVEM.W	D5-D7,-(A7)
		LEA	$0030(A1),A0
		MOVE.B	$001C(A1),D5
		ANDI.W	#7,D5
		BTST	#1,D5
		BNE.B	L_D60C
		MOVE.B	$0019(A1),D7
		MOVEQ	#3,D1
		BTST	#0,D5
		BNE.B	L_D5E2
		LSR.W	#2,D5
L_D5CC		MOVE.W	D5,D0
		ADD.B	D7,D7
		ADDX.w	D0,D0
		ADD.B	D7,D7
		ADDX.w	D0,D0
		ADD.W	D0,D0
		MOVE.W	L_D61E(PC,D0.W),-(A0)
		DBRA	D1,L_D5CC
		BRA.B	L_D604
L_D5E2		LSR.W	#2,D5
		MOVE.B	$001A(A1),D6
L_D5E8		MOVE.W	D5,D0
		ADD.B	D7,D7
		ADDX.w	D0,D0
		ADD.B	D6,D6
		ADDX.w	D0,D0
		ADD.B	D7,D7
		ADDX.w	D0,D0
		ADD.B	D6,D6
		ADDX.w	D0,D0
		ADD.W	D0,D0
		MOVE.W	L_D640(PC,D0.W),-(A0)
		DBRA	D1,L_D5E8
L_D604		MOVE.W	(A7)+,D5
		MOVE.W	(A7)+,D6
		MOVE.W	(A7)+,D7
		RTS	
L_D60C		ANDI.B	#-$0011,CCR
		ROXR.W	#2,D5
		ROL.W	#3,D5
		MOVE.L	L_D630(PC,D5.W),D0
		MOVE.L	D0,-(A0)
		MOVE.L	D0,-(A0)
		BRA.B	L_D604
L_D61E		DC.W	$2A2A,-$15D6,$2AEA,-$1516,-$7576,-$4576,-$7546,-$4546,0
L_D630		DC.L	$6A6A6A6A,$5A5A5A5A,-$65656566,$5A5A5A5A
L_D640		DC.W	$A0A,$3A0A,-$35F6,-$5F6,$A3A,$3A3A,-$35C6,-$5C6,$ACA
		DC.W	$3ACA,-$3536,-$536,$AFA,$3AFA,-$3506,-$506,$A0A,-$35F6
		DC.W	$3A0A,-$5F6,$ACA,-$3536,$3ACA,-$536,$A3A,-$35C6,$3A3A
		DC.W	-$5C6,$AFA,-$3506,$3AFA,-$506
_setfont	MOVE.L	A1,D0
		BEQ.B	L_1A84C
		MOVEM.L	A2-A3,-(A7)
		MOVEA.L	A0,A2
		MOVEA.L	A1,A3
		MOVE.L	A0,D0
		BEQ.B	L_1A84E
		SUBA.L	A1,A1
		JSR	-$0330(A6)
		TST.L	D0
		BEQ.B	L_1A848
		MOVE.W	$0014(A2),$003A(A3)
		MOVE.L	$0018(A2),$003C(A3)
L_1A840		CLR.B	$0038(A3)
		MOVE.L	A2,$0034(A3)
L_1A848		MOVEM.L	(A7)+,A2-A3
L_1A84C		RTS	
L_1A84E		CLR.W	$003A(A3)
		CLR.L	$003C(A3)
		BRA.B	L_1A840
_setapen	MOVE.B	D0,$0019(A1)
L_7DB4		MOVE.B	#$000F,$001E(A1)
		ORI.W	#1,$0020(A1)
		BRa	L_D5A8
_rectfill	MOVEM.L	D4-D5/A2,-(A7)
		MOVEA.L	A1,A2
		MOVEQ	#0,D4
		MOVEA.L	D4,A0
		BTST	#3,$0021(A2)
		BNE.B	L_699E
		JSR	_LVOBltPattern(A6)
		BRA.W	L_6A32
L_699E		MOVEM.L	D0-D1,-(A7)
		BTST	#1,$001C(A2)
		BEQ.B	L_69C8
		MOVEM.L	D2-D3,-(A7)
		ADDQ.W	#1,D0
		ADDQ.W	#1,D1
		SUBQ.W	#1,D2
		SUBQ.W	#1,D3
		CMP.W	D0,D2
		BLT.B	L_69C2
		CMP.W	D1,D3
		BLT.B	L_69C2
		JSR	_LVOBltPattern(A6)
L_69C2		MOVEM.L	(A7)+,D2-D3
		BRA.B	L_69CC
L_69C8		JSR	_LVOBltPattern(A6)
L_69CC		MOVEM.L	(A7)+,D4-D5
		MOVE.L	$0028(A2),-(A7)
		MOVE.L	$002C(A2),-(A7)
		MOVE.B	$0019(A2),-(A7)
		MOVE.B	$001C(A2),-(A7)
		MOVE.B	$001B(A2),$0019(A2)
		CLR.B	$001C(A2)
		MOVEA.L	A2,A1
		BSR.W	L_D5A8
		MOVEA.L	A2,A1
		MOVE.L	D4,D0
		MOVE.L	D5,D1
		JSR	_LVOMove(A6)
		MOVEA.L	A2,A1
		MOVE.L	D4,D0
		MOVE.L	D3,D1
		JSR	_LVODraw(A6)
		MOVEA.L	A2,A1
		MOVE.L	D2,D0
		MOVE.L	D3,D1
		JSR	_LVODraw(A6)
		MOVEA.L	A2,A1
		MOVE.L	D2,D0
		MOVE.L	D5,D1
		JSR	_LVODraw(A6)
		MOVEA.L	A2,A1
		MOVE.L	D4,D0
		MOVE.L	D5,D1
		JSR	_LVODraw(A6)
		MOVE.B	(A7)+,$001C(A2)
		MOVE.B	(A7)+,$0019(A2)
		MOVE.L	(A7)+,$002C(A2)
		MOVE.L	(A7)+,$0028(A2)
L_6A32		MOVEM.L	(A7)+,D4-D5/A2
		RTS
_bltpattern	CMPA.W	#0,A0
		BNE.B	L_6FC8
		TST.L	8(A1)
		BEQ.B	L_700A
L_6FC8		TST.L	(A1)
		BNE.B	L_6FF0
		CLR.L	-(A7)
		CLR.L	-(A7)
		CLR.L	-(A7)
		CLR.L	-(A7)
		MOVE.W	D4,-(A7)
		MOVE.W	#0,-(A7)
		MOVEM.W	D0-D3,-(A7)
		CLR.L	-(A7)
		MOVE.L	A0,-(A7)
		MOVE.L	A1,-(A7)
	illegal
		JSR	$0058A694.L
		LEA	$0028(A7),A7
		rts
L_6FF0		MOVE.W	D4,-(A7)
		MOVE.W	#0,-(A7)
		MOVEM.W	D0-D3,-(A7)
		MOVE.L	A0,-(A7)
		MOVE.L	A1,-(A7)
	illegal
		JSR	$0058F894.L
		LEA	$0014(A7),A7
L_7008		RTS	
L_700A		MOVEM.L	A2/A6,-(A7)
		LEA	-$001C(A7),A7
		lea	_7060,a0
		MOVE.L	a0,8(A7)
		MOVE.L	A6,$0010(A7)
		MOVEM.W	D0-D3,$0014(A7)
		LEA	$0014(A7),A2
		MOVEA.L	A7,A0
		MOVEA.L	gb_LayersBase(A6),A6
		JSR	_LVODoHookClipRects(A6)
		LEA	$001C(A7),A7
		MOVEM.L	(A7)+,A2/A6
		RTS
L_703C		DC.W	-1
L_703E		DC.W	$7FFF
		DC.W	$3FFF
		DC.W	$1FFF
		DC.W	$FFF
		DC.W	$7FF
		DC.W	$3FF
		DC.W	$1FF
		DC.W	$FF
		DC.W	$7F
		DC.W	$3F
		DC.W	$1F
		DC.W	$F
		DC.W	7
		DC.W	3
		DC.W	1
		DC.W	0
		DC.W	0
	;Hook for Clip Rect
_7060		MOVEM.L	D2-D7/A2-A6,-(A7)
		MOVEA.L	$0010(A0),A6
		MOVEA.L	A1,A3
		ADDQ.W	#1,gb_BlitLock(A6)
		BEQ.B	L_7074
	illegal
	;	BSR.W	L_82B8
L_7074		MOVEM.W	4(A3),D0-D3
		MOVEA.L	A2,A1
		MOVEA.L	4(A1),A2
		LEA	$00DFF000.L,A0
		SUB.W	D1,D3
		ADDQ.W	#1,D3
		MULU	(A2),D1
		MOVEQ	#$000F,D6
		MOVE.W	D0,D4
		AND.W	D6,D4
		ADD.W	D4,D4
		MOVE.W	L_703C(PC,D4.W),D4
		MOVE.W	D2,D5
		AND.W	D6,D5
		ADD.W	D5,D5
		MOVE.W	L_703E(PC,D5.W),D5
		NOT.W	D5
		LSR.W	#4,D0
		LSR.W	#4,D2
		SUB.W	D0,D2
		ADDQ.W	#1,D2
		ADD.W	D0,D0
		EXT.L	D0
		ADD.L	D0,D1
		MOVE.W	D2,D6
		ADD.W	D2,D2
		SUB.W	(A2),D2
		NEG.W	D2
		LEA	$0028(A1),A5
		LEA	8(A2),A3
		MOVEQ	#0,D0
		MOVE.B	$00EC(A6),D7		;?????
		TST.B	2(A0)
		BTST	#6,2(A0)
		BEQ.B	L_70D8
		BSR.W	L_6B4C
L_70D8		AND.B	#1,D7
		BEQ.B	L_70E4
		MOVE.W	D3,$005C(A0)
		BRA.B	L_70E8
L_70E4		LSL.W	#6,D3
		ADD.W	D6,D3
L_70E8		MOVE.W	D4,$0044(A0)
		MOVE.W	D5,$0046(A0)
		MOVE.W	D2,$0066(A0)
		MOVE.W	D2,$0060(A0)
		MOVE.W	D0,$0042(A0)
		MOVEQ	#-1,D2
		MOVE.L	D2,$0072(A0)
		MOVE.B	5(A2),D0
		MOVE.B	$0018(A1),D2
		MOVE.W	#$0300,D4
		BRA.B	L_7158
L_7110		MOVE.B	(A5)+,D4
		MOVEA.L	(A3)+,A4
		LSR.B	#1,D2
		BCC.B	L_7158
		ADDA.L	D1,A4
		TST.B	2(A0)
		BTST	#6,2(A0)
		BEQ.B	L_712A
		BSR.W	L_6B4C
L_712A		MOVE.W	D4,$0040(A0)
		MOVE.L	A4,$0054(A0)
		MOVE.L	A4,$0048(A0)
		TST.B	D7
		BEQ.B	L_7154
		MOVE.W	D6,$005E(A0)
		DBRA	D0,L_7110
		SUBQ.W	#1,$00AA(A6)
		BLT.B	L_714E
	illegal
	;	JSR	$0058833E.L
L_714E		MOVEM.L	(A7)+,D2-D7/A2-A6
		RTS	
L_7154		MOVE.W	D3,$0058(A0)
L_7158		DBRA	D0,L_7110
		JSR	_LVODisownBlitter(A6)
		MOVEM.L	(A7)+,D2-D7/A2-A6
		RTS	
	;WaitBlit
L_6B4C		TST.B	$00DFF002.L
		BTST	#6,$00DFF002.L
		BNE.B	L_6B5E
		RTS	
L_6B5E		TST.B	$00BFE001.L
		TST.B	$00BFE001.L
		BTST	#6,$00DFF002.L
		BNE.B	L_6B5E
		TST.B	$00DFF002.L
		RTS	
_disownblitter	SUBQ.W	#1,gb_BlitLock(A6)
		BLT.B	L_8394
		MOVEM.L	D0-D1/A0-A1/A5-A6,-(A7)
		MOVEA.L	$01A4(A6),A5
	illegal
		LEA	gb_BlitWaitQ(A6),A0
		MOVE.W	#$4000,$00DFF09A.L
		ADDQ.B	#1,IDNestCnt(A5)
		TST.L	gb_blthd(A6)
		BEQ.B	L_8396
		TST.B	$00DFF002.L
		BTST	#6,$00DFF002.L
		BNE.B	L_8374
		MOVE.W	#-$7FC0,$00DFF09C.L
L_8374		MOVE.W	#-$7FC0,$00DFF09A.L
		ORI.W	#2,gb_Flags(A6)
		SUBQ.B	#1,IDNestCnt(A5)
		BGE.B	L_8390
		MOVE.W	#-$4000,$00DFF09A.L
L_8390		MOVEM.L	(A7)+,D0-D1/A0-A1/A5-A6
L_8394		RTS	
L_8396		MOVEA.L	(A0),A1
		MOVE.L	(A1),D0
		BEQ.B	L_83C6
		MOVE.L	D0,(A0)
		MOVEA.L	$000A(A1),A6
		MOVEA.L	D0,A1
		MOVE.L	A0,4(A1)
		MOVEA.L	A6,A1
		MOVEA.L	A5,A6
		MOVEQ	#$0010,D0
		JSR	_LVOSignal(A6)
		SUBQ.B	#1,IDNestCnt(A6)
		BGE.B	L_83C0
		MOVE.W	#-$4000,$00DFF09A.L
L_83C0		MOVEM.L	(A7)+,D0-D1/A0-A1/A5-A6
		RTS	
L_83C6		BSET	#2,gb_Flags+1(A6)
		SUBQ.B	#1,IDNestCnt(A5)
		BGE.B	L_83DA
		MOVE.W	#-$4000,$00DFF09A.L
L_83DA		MOVEM.L	(A7)+,D0-D1/A0-A1/A5-A6
		RTS	
		
_gfxbase	dc.l	0

;--------------------------------

_emul_dos	lea	(DOS_LIB_LEN,a6),a5	;A5 = dosbase
		lea	_dosbase,a0
		move.l	a5,(a0)
		move.l	#DOS_LIB_LEN,d0
		move.l	#DOS_DAT_LEN,d1
		move.l	a6,a0
		bsr	_MakeLib
		lea	(DOS_DAT_LEN,a5),a6	;A6 = free
		rts

_dosbase	dc.l	0

;--------------------------------

; d0 = jmp-table size
; d1 = data size
; a0 = start pointer

_MakeLib	lea	_BadFunc,a1
		tst.l	d0
		ble	.1
.0		move.w	#$4ef9,(a0)+
		move.l	a1,(a0)+
		subq.l	#6,d0
		bne	.0
.1		tst.l	d1
		ble	.3
.2		clr.b	(a0)+
		subq.l	#1,d1
		bne	.2
.3		rts

_BadFunc	move.l	(a7),-(a7)	;pc
		subq.l	#4,(a7)		;jsr -nn(a6)
		clr.l	(4,a7)		;sr
		bra	_debug

;--------------------------------

_main		dc.b	"tech.data",0

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

	cmp.b	#$50,d0
	bne	.0
	move.b	_ciaa+ciacra,d0
	move.b	#16,_ciaa+ciacra
	or.b	#1,d0
	move.b	d0,_ciaa+ciacra
	move.b	_ciaa+ciacrb,d0
	move.b	#16,_ciaa+ciacrb
	or.b	#1,d0
	move.b	d0,_ciaa+ciacrb
.0
		cmp.b	#$58,d0
		bne	.1
		move.l	(a7)+,d0
		move.w	(a7),(6,a7)	;sr
		move.l	(2,a7),(a7)	;pc
		clr.w	(4,a7)		;ext.l sr
		bra	_debug		;coredump & quit
.1
		cmp.b	#$59,d0
		beq	_exit		;exit

		move.l	(a7)+,d0
		move.l	(_realint68),-(a7)	;enter orginal rou.
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	END
