;*---------------------------------------------------------------------------
;  :Program.	cf2.asm
;  :Contents.	Slave for "Cannonfodder 2"
;  :Author.	BJ
;  :Version.	$Id: cf2.asm 1.2 1998/09/23 17:34:48 jah Exp jah $
;  :History.	20.05.96
;		17.05.97 improved for version 3
;			 adapded for german version
;		22.05.97 working on german version
;		12.01.98 support for original english version
;		21.09.98 access fault in soundplayer in german version fixed
;		29.09.98 fix problem with savegames from a floppy game
;			 containing absolute address of relocated program
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

crc_v1	= $54b2		;english cracked ?
crc_v2	= $b9c6		;german
crc_v3	= $389d		;english

	INCDIR	Includes:
	INCLUDE	whdload.i

	OUTPUT	wart:c/cannonfodder2/cf2.slave
	BOPT	O+ OG+				;enable optimizing
	BOPT	ODd- ODe-			;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

;======================================================================

.base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	5			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	$fea00			;ws_ExecInstall
		dc.w	_Start-.base		;ws_GameLoader
		dc.w	_dir-.base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10

;======================================================================
		
_dir		dc.b	"data",0

;======================================================================

	DOSCMD	"WDate >T:date"
		dc.b	"$VER: CannonFodder2.Slave "
	INCBIN	"T:date"
		dc.b	0
	EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2			;A2 = resload

		move.l	#CACRF_EnableI,d0
		move.l	d0,d1
		jsr	(resload_SetCACR,a2)

		lea	(_main),a0
		lea	($80000),a1
		move.l	a1,a5			;A5 = main address
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	a5,a0
		jsr	(resload_CRC16,a2)
		cmp.w	#crc_v2,d0
		beq	_version2
		cmp.w	#crc_v1,d0
		beq	_version1
		cmp.w	#crc_v3,d0
		bne	_badver

;======================================================================
		
_version1
	;differences between cracked and original version
		move.l	#$203c3d74,($80000+$9ff6)
		move.l	#$2cf14e75,($80000+$9ffa)
		move.b	#$60,($80000+$22b92)
		move.b	#$60,($80000+$22c7a)

		LEA	$3D50.W,A0	;clr diskbuffer for root-block
		MOVEQ	#$007F,D0	;filenamen generierung
L_B8		CLR.L	(A0)+
		DBRA	D0,L_B8
		
		clr.l	$89ee2		;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$762c(a5)	;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$7724(a5)	;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$777a(a5)	;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$77d0(a5)	;move.l #xxxxxxxx,a0 (source für stringcopy)
		CLR.L	$000A8C52.L	;move.l #xxxxxxxx,a0 (source für stringcopy)
		CLR.L	$000A9496.L	;move.l #xxxxxxxx,a0 (source für stringcopy)
					;exception #11266 at $89e08

	;	ill	$86686		;SOFT INT (CopperList)
	;	ill	$8668e		;if 80614<>0
	;	ill	$866bc		;if 80614=0

		ret	$89ec8			;copylock
		
	;	nops	4,$898a6		;intreq reset before int disabled
		patch	$8990a,_keyboard	;keyboard int umleiten

		patch	$8afd6,_Loader

	;load/save game
		MOVEQ	#4,D0
		LEA	$000A8D94.L,A0
L_124		MOVE.W	#$4E71,(A0)+
		DBRA	D0,L_124
		ADDI.W	#$0304,$000A8974.L

		move.l	#$4e714e71,$000A8C2C
		SUBI.W	#$0890,$000A8C38.L

		ret	$a97c6		;"insert disk 3"

	;	patch	$9de0c,_bug	;buserror bug (reading from -xxx)

		lea	$64990,a0	;area for dir of savedisk
		moveq	#5*32/4,d0	;must cleared because coupls of bugs
.c3		clr.l	(a0)+
		dbf	d0,.c3

	;	patch	$a8b8e,_bug2	;11266 if load savegame and 0 or 1 savegame exist
		patch	$a89a6,$a89e4	;skips file "CFSDISK"

		move.l	#$4e714e71,$5fd2(a5)	;move #$2000,sr
		move	#0,sr			;to usermode
		JMP	$5f46(a5)

;======================================================================

_version2
	;exceptions #11266 at $89e08
		clr.l	$89ee2			;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$762c(a5)		;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$7724(a5)		;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$777a(a5)		;move.l #xxxxxxxx,a0 (source für stringcopy)
		clr.l	$77d0(a5)		;move.l #xxxxxxxx,a0 (source für stringcopy)
		CLR.L	$000A9134.L		;move.l #xxxxxxxx,a0 (source für stringcopy)
		CLR.L	$000A98ae.L		;move.l #xxxxxxxx,a0 (source für stringcopy)

		patch	$8990a,_keyboard	;keyboard int umleiten
		patch	$8afd6,_Loader
		
		ret	$89ec8			;copylock
	;	lea	($89ff6),a0		;old style
	;	move.l	#$203c3d74,(a0)+
	;	move.l	#$2cf14e75,(a0)

		nops	5,$a927a		;load game
		ADDI.W	#$032e,$000A8e48.L

		move.l	#$4e714e71,$a910e	;save game
		SUBI.W	#$07ce,$000A911a.L

		ret	$a9bea			;"insert disk 3"

		lea	$64990,a0		;area for dir of savedisk
		moveq	#5*32/4,d0		;must cleared because coupls of bugs
.c3		clr.l	(a0)+
		dbf	d0,.c3

		patch	$a8e7a,$a8eb8		;skips file "CFSDISK"

		LEA	$3D50.W,A0		;clr diskbuffer for root-block
		MOVEQ	#$007F,D0		;filenamen generierung
.B8		CLR.L	(A0)+
		DBRA	D0,.B8

	;ein übelster Schrapelplayer ist das !
	;a2740 = a2892 sound off
	;a272c = a2780 sound init
	;a2728 = a2a2e sound play
	;	lea	$a2780,a0
	;	move.l	#$4e71<<16+%0100100001111001,(a0)+	;nop,pea x.l
	;	lea	(_spfuck),a1
	;	move.l	a1,(a0)+
	;	ill	$a2740
	;	ill	$a272c
	;	move.b	#$6f,$a2c70
	;	move.b	#$6f,$a2d58
	;	jsr	$a2780
	;	ret	$a2a2e			;disable sound
		move.b	#$6f,$a2c70		;beq -> ble
		patchs	$a2d5a,_s1
		
		move.l	#$4e714e71,$5fd2(a5)	;move #$2000,sr
		move	#0,sr			;to usermode
		JMP	$5f46(a5)

_s1		cmp.l	#$100000,d0
		bhs	.ret
		move.l	d0,a1			;original
		move.l	($20,a0),d0		;original
		rts

.ret		addq.l	#4,a7
		rts

_spfuck	;	move.w	#-1,$a25ca
	;	rts

;======================================================================

_keyboard	cmp.b	#$5f,d0		;HELP ?
		beq	.help
		cmp.b	(_keydebug),d0	;F9 ?
		beq	.debug
		cmp.b	(_keyexit),D0	;F10 ?
		beq	_exit
.back		movem.l	(a7)+,d0-d1
		rte	

.debug		movem.l	(a7)+,d0-d1
		move.w	(a7),(6,a7)	;sr
		move.l	(2,a7),(a7)	;pc
		clr.w	(4,a7)		;ext.l sr
		bra	_debug		;coredump & quit

.help	;	move.w	#$4a79,$a2a2e	;enable sound (version 2)
		move.l	a0,-(a7)
		move.w	$8155a,d0	;aktuelles team
		lea	$821c4,a0
		st	(a0,d0.w)
		lea	$821ca,a0
		st	(a0,d0.w)
		lea	$81f50,a0
		add.w	d0,a0
		add.w	d0,a0
		move.w	#42,(a0)	;grenades
		move.w	#42,(6,a0)	;bazookas
		move.l	(a7)+,a0
		bra	.back

;--------------------------------

_Loader		cmp.w	#3,d0		;list
		beq	.cmd3
		cmp.w	#1,d0		;save
		beq	.cmd1
		tst.w	d0		;load
		beq	.cmd0
		illegal

	;load file
.cmd0		movem.l	d2-a6,-(a7)
		move.l	a0,a4		;A4 = name
		move.l	a1,a5		;A5 = ptr
		
		addq.l	#4,a4		; == "DF0:"
		tst.b	(a4)
		beq	.ok
		lea	.d1,a0		;"DISK1"
		bsr	.cmp
		beq	.ok
		lea	.d2,a0		;"DISK2"
		bsr	.cmp
		beq	.ok
		lea	.d3,a0		;"DISK3"
		bsr	.cmp
		beq	.ok
		lea	.ds,a0		;"CFSDISK"
		bsr	.cmp
		beq	.ok

		cmp.l	#$8062a,a5		;only if savefile
		bne	.load
		lea	(.buf),a0
		lea	(_savepath),a1
.l1		move.b	(a1)+,(a0)+
		bne	.l1
		move.b	#"/",(-1,a0)
.l2		move.b	(a4)+,(a0)+
		bne	.l2
		lea	(.buf),a4

.load		move.l	a4,a0
		move.l	a5,a1
		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	d0,d1
		
		cmp.l	#$8062a,a5
		bne	.ok
	;fix problem with savegames from a floppy game
	;containing absolute address of relocated program
		move.l	#$80a1a,$80cec
		
.ok		movem.l	(a7)+,d2-a6
		moveq	#0,d0
		rts

.cmp		move.l	a4,a1
.lp		move.b	(a1)+,d0
		beq	.cmpok
		cmp.b	(a0)+,d0
		beq	.lp
		moveq	#-1,d0
.cmpok		rts

	;save file
.cmd1		MOVEM.L	D2-A6,-(A7)
		ADDQ.L	#4,A0
		LEA	(.buf),A2
		LEA	(_savepath),A3
.l11		MOVE.B	(A3)+,(A2)+
		BNE.B	.l11
		MOVE.B	#"/",(-1,A2)
.l12		MOVE.B	(A0)+,(A2)+
		BNE.B	.l12
		LEA	(.buf),A0
		MOVE.L	D1,D0
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
		MOVEM.L	(A7)+,D2-A6
		moveq	#0,D0
		RTS	

	;list directory
.cmd3		movem.l	d2-a6,-(a7)
		lea	(_savepath),a0
		move.l	a1,a6			;a6 = array
		lea	(.buf),a1
		move.l	#.bufend-.buf,d0
		move.l	(_resload),a2
		jsr	(resload_ListFiles,a2)
		move.l	d0,d7			;d7 = how many entries
		lea	(_savepath),a0
		move.l	a0,d2

		move.l	a6,a0
		lea	(.buf),a1
		move.w	d7,d0
		beq	.cmd3_end
		
.cmd3_lp	move.b	#-3,(a0)+		;FILE
		addq.l	#1,a0
		moveq	#-1,d1

.cmd3_n		addq.l	#1,d1
		move.b	(a1)+,(a0)+
		bne	.cmd3_n
		sub.l	d1,a0
		subq.l	#2,a0
		move.b	d1,(a0)
		add.w	#31,a0
		subq.l	#1,d0
		bne	.cmd3_lp

.cmd3_end	move.l	d7,d1
		movem.l	(a7)+,d2-a6
		moveq	#0,d0
		rts

.buf		ds.b	256
.bufend
.d1		dc.b	"DISK1",0
.d2		dc.b	"DISK2",0
.d3		dc.b	"DISK3",0
.ds		dc.b	"CFSDISK",0
_savepath	dc.b	"/save",0
	EVEN

;--------------------------------

_badver		pea	TDREASON_WRONGVER
		bra	_end
_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_resload	dc.l	0		;address of resident loader
_main		dc.b	"cf2",0

;======================================================================
_End
;======================================================================

	END
