;*---------------------------------------------------------------------------
;  :Program.	cf2.asm
;  :Contents.	Slave for "Cannonfodder 2"
;  :Author.	Wepl
;  :Version.	$Id: cf2.asm 1.5 2000/09/03 18:11:44 jah Exp jah $
;  :History.	20.05.96
;		17.05.97 improved for version 3
;			 adapded for german version
;		22.05.97 working on german version
;		12.01.98 support for original english version
;		21.09.98 access fault in soundplayer in german version fixed
;		29.09.98 fix problem with savegames from a floppy game
;			 containing absolute address of relocated program
;		13.01.99 stack decreased on exit because "unacceptible args.."
;		27.08.00 adapted for v10
;		03.09.00 finished rework
;		10.01.01 bplcon0 and aga accesses fixed
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
	INCLUDE	whdmacros.i

	OUTPUT	wart:c/cannonfodder2/cf2.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

BUFLEN = 256

	STRUCTURE	globals,$100
		LONG	_resload
	;	STRUCT	_buffer,BUFLEN

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Cannonfodder 2",0
_copy		dc.b	"1994 Sensible Software",0
_info		dc.b	"Installed and fixed by Wepl",10
		dc.b	"Version 1.6 "
		INCBIN	"T:date"
		dc.b	0
_dir		dc.b	"data",0
_main		dc.b	"cf2",0
_d1		dc.b	"DISK1",0
_d2		dc.b	"DISK2",0
_d3		dc.b	"DISK3",0
_ds		dc.b	"CFSDISK",0
_savepath	dc.b	"/save",0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(_resload)
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
		lea	(_pl1),a0
		cmp.w	#crc_v1,d0
		beq	.ok
		cmp.w	#crc_v3,d0
		beq	.ok
		lea	(_pl2),a0
		cmp.w	#crc_v2,d0
		beq	.ok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.ok		move.l	a5,a1
		jsr	(resload_Patch,a2)
		lea	(_pl),a0
		move.l	a5,a1
		jsr	(resload_Patch,a2)

		LEA	$3D50.W,A0		;clr diskbuffer for root-block
		MOVEQ	#$007F,D0		;filenamen generierung
.c2		CLR.L	(A0)+
		DBRA	D0,.c2
		
		lea	$64990,a0		;area for dir of savedisk
		moveq	#5*32/4,d0		;must cleared because couples of bugs
.c3		clr.l	(a0)+
		dbf	d0,.c3

		move	#0,sr			;to usermode
		JMP	$5f46(a5)

;======================================================================

_pl		PL_START

	;exception #11266 at $89e08
		PL_L	$9ee2,0			;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$762c,0			;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$7724,0			;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$777a,0			;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$77d0,0			;move.l #xxxxxxxx,a0 (source für stringcopy)

		PL_R	$9ec8			;copylock
		PL_P	$990a,_keyboard		;keyboard int umleiten
		PL_P	$afd6,_Loader

		PL_S	$5fd2,4			;move #$2000,sr

		PL_W	$2dbc,$4200		;bplcon0
		PL_S	$5fc2,8+8		;bplcon3,4
		PL_W	$ac98,$1e		;htotal
		PL_W	$c0c2,$200		;bplcon0

		PL_END
		
;======================================================================

_pl1		PL_START

	;differences between cracked and original version
		PL_L	$9ff6,$203c3d74
		PL_L	$9ffa,$2cf14e75
		PL_B	$22b92,$60
		PL_B	$22c7a,$60

		PL_W	$1C278,$4200
		PL_W	$1C318,$4200
		PL_W	$1C32c,$5200
		PL_W	$1C610,$5200
		PL_W	$1C6Ce,$4200
		PL_W	$26076,$6600
		PL_W	$26266,$4200
		PL_W	$275E0,$5200
		PL_W	$2786c,$4200

	;exception #11266 at $89e08
		PL_L	$28C52,0		;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$29496,0		;move.l #xxxxxxxx,a0 (source für stringcopy)

	;	nops	4,$898a6		;intreq reset before int disabled
		PL_R	$297c6			;"insert disk 3"
		PL_S	$289a6,$e4-$a6		;skips file "CFSDISK"

	;	PL_B	$22b92,$6f		;bra -> ble
	;	PL_PS	$22c7c,_s1
		
	;load/save game
		PL_S	$28d94,10
		PL_W	$28974,$352+$304
		PL_S	$28c2c,4
		PL_W	$28c38,$98a-$890

		PL_END
		
;======================================================================

_pl2		PL_START

	;exceptions #11266 at $89e08
		PL_L	$29134,0		;move.l #xxxxxxxx,a0 (source für stringcopy)
		PL_L	$298ae,0		;move.l #xxxxxxxx,a0 (source für stringcopy)

		PL_R	$29bea			;"insert disk 3"
		PL_S	$28e7a,$b8-$7a		;skips file "CFSDISK"

		PL_W	$1C356,$4200
		PL_W	$1C3F6,$4200
		PL_W	$1C40a,$5200
		PL_W	$1C6Ee,$5200
		PL_W	$1C7Ac,$4200
		PL_W	$26420,$6600
		PL_W	$26638,$4200
		PL_W	$279B4,$5200
		PL_W	$27C40,$4200

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
		PL_B	$22c70,$6f		;beq -> ble
		PL_PS	$22d5a,_s1

	;load/save game
		PL_S	$2927a,10
		PL_W	$28e48,$360+$32e
		PL_S	$2910e,4
		PL_W	$2911a,$8cc-$7ce
		
		PL_END
		
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

_keyboard	cmp.b	(_keyexit),d0
		beq	.exit
		cmp.b	#$5f,d0			;HELP ?
		bne	.ret

	;	move.w	#$4a79,$a2a2e	;enable sound (version 2)
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

.ret		movem.l	(a7)+,d0-d1
		rte	

.exit		subq.l	#8,a7
		pea	TDREASON_OK
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

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
		lea	_d1,a0		;"DISK1"
		bsr	.cmp
		beq	.ok
		lea	_d2,a0		;"DISK2"
		bsr	.cmp
		beq	.ok
		lea	_d3,a0		;"DISK3"
		bsr	.cmp
		beq	.ok
		lea	_ds,a0		;"CFSDISK"
		bsr	.cmp
		beq	.ok

		cmp.l	#$8062a,a5		;only if savefile
		bne	.load
		lea	(_buffer),a0
		lea	(_savepath),a1
.l1		move.b	(a1)+,(a0)+
		bne	.l1
		move.b	#"/",(-1,a0)
.l2		move.b	(a4)+,(a0)+
		bne	.l2
		lea	(_buffer),a4

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
		LEA	(_buffer),A2
		LEA	(_savepath),A3
.l11		MOVE.B	(A3)+,(A2)+
		BNE.B	.l11
		MOVE.B	#"/",(-1,A2)
.l12		MOVE.B	(A0)+,(A2)+
		BNE.B	.l12
		LEA	(_buffer),A0
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
		lea	(_buffer),a1
		move.l	#BUFLEN,d0
		move.l	(_resload),a2
		jsr	(resload_ListFiles,a2)
		move.l	d0,d7			;d7 = how many entries
		lea	(_savepath),a0
		move.l	a0,d2

		move.l	a6,a0
		lea	(_buffer),a1
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

;======================================================================

_buffer		dsb	BUFLEN

;======================================================================

	END
