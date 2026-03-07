;*---------------------------------------------------------------------------
;  :Program.	cannonfodder2.asm
;  :Contents.	Slave for "Cannonfodder 2"
;  :Author.	Wepl
;  :Original.	v1 crack
;		v2 german	Bert Jahn
;		v3 english
;		v4 french	Denis Lechevalier <dlfrsilver@hotmail.fr>
;		v5 italian
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
;		20.02.01 support for english crack version reenabled (wrong crc???)
;			 one access fault fixed
;		20.07.03 keyboard fixed
;		10.08.05 support for french version added
;		08.09.05 save/load fixed for french version
;		11.12.08 savepath changed for compatibility with WHDLoad 16.9
;			 buffer in ExpMem, requires whdload v16.9 now
;		11.05.11 keyboard routine modified, issue #2422
;		15.05.11 access fault on loading savegame fixed, issue #2438
;		24.11.18 support for italian version added
;		02.03.26 trainer for english version added by Arise from Decay
;		07.03.26 italian support completed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

crc_v1	= $e95e		;english cracked ?
crc_v2	= $b9c6		;german
crc_v3	= $389d		;english
crc_v4	= $aa9f		;french
crc_v5	= $e80b		;italian

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	HD2:whdload/cannonfodder2/CannonFodder2.Slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-
	SUPER
	ENDC

BUFLEN = $1000

	STRUCTURE	globals,$100
		LONG	_resload

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	BUFLEN			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_Config

;============================================================================

_name		dc.b	"Cannonfodder 2",0
_copy		dc.b	"1994 Sensible Software",0
_info		dc.b	"Installed and fixed by Wepl",10
		dc.b	"Version 1.13 "
		INCBIN	".date"
		dc.b	10,"Trainer addded by Arise from Decay",10
		dc.b	"Press `N` to skip level",0
_config		dc.b	"C1:X:Infinite Recruits:0;"
		dc.b	"C1:X:Infinite Grenades:1;"
		dc.b	"C1:X:Infinite Bazookas:2;"
		dc.b	"C1:X:Troops Invulnerable:3",0
_dir		dc.b	"data",0
_main		dc.b	"cf2",0
_d1		dc.b	"DISK1",0
_d2		dc.b	"DISK2",0
_d3		dc.b	"DISK3",0
_ds		dc.b	"CFSDISK",0
_savepath	dc.b	"save",0
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
		lea	(_pl4),a0
		cmp.w	#crc_v4,d0
		beq	.ok
		lea	(_pl5),a0
		cmp.w	#crc_v5,d0
		beq	.ok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.ok		move.l	a5,a1
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
; equal part for all versions

_pl		PL_START
		PL_W	$2dbc,$4200		;bplcon0
		PL_S	$5fc2,8+8		;bplcon3,4
		PL_S	$5fd2,4			;move #$2000,sr
		PL_CL	$762c			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_CL	$7724			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_CL	$777a			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_CL	$77d0			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_P	$98a6,_keyboard		;keyboard int umleiten
		PL_R	$9ec8			;copylock
		PL_CL	$9ee2			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_W	$ac98,$1e		;htotal
		PL_P	$afd6,_Loader
		PL_W	$c0c2,$200		;bplcon0
		PL_END

;======================================================================
; english

_pl1		PL_START
	;	PL_L	$9ff6,$203c3d74		;differences between cracked and original version
	;	PL_L	$9ffa,$2cf14e75		;differences between cracked and original version
		PL_W	$1C278,$4200
		PL_W	$1C318,$4200
		PL_W	$1C32c,$5200
		PL_W	$1C610,$5200
		PL_W	$1C6Ce,$4200
		PL_PS	$1ddfa,_af
		PL_B	$22b92,$6f		;bra -> ble
	;	PL_B	$22b92,$60		;differences between cracked and original version
	;	PL_B	$22c7a,$60		;differences between cracked and original version
		PL_PS	$22c7c,_s1
		PL_W	$26076,$6600
		PL_W	$26266,$4200
		PL_W	$275E0,$5200
		PL_W	$2786c,$4200
		PL_W	$28974,$352+$304	;load/save game
		PL_S	$289a6,$e4-$a6		;skips file "CFSDISK"
		PL_S	$28c2c,4		;load/save game
		PL_W	$28c38,$98a-$890	;load/save game
		PL_CL	$28C52			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_S	$28d94,10		;load/save game
		PL_CL	$29496			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_R	$297c6			;"insert disk 3"
		PL_IFC1X 0
		PL_NOPS $1d4d0,3		;Trainer recruits
		PL_ENDIF
		PL_IFC1X 1
		PL_NOPS $170fe,2		;Trainer Grenades
		PL_ENDIF
		PL_IFC1X 2
		PL_NOPS $1aaf4,2		;Trainer Bazookas
		PL_ENDIF
		PL_IFC1X 3
		PL_NOPS $1cefe,1		;Trainer Invulnerability
		PL_ENDIF
		PL_NEXT	_pl

_af		move.w	$8155a,d0		;actual player/team (0-5)
		bpl	.ok
		clr.w	d0
.ok		rts

;======================================================================
; equal part for german/french versions

_pl24		PL_START
		PL_W	$1C356,$4200
		PL_W	$1C3F6,$4200
		PL_W	$1C40a,$5200
		PL_W	$1C6Ee,$5200
		PL_W	$1C7Ac,$4200
		PL_PS	$1ded8,_af
		PL_B	$22c70,$6f		;beq -> ble
		PL_PS	$22d5a,_s1
		PL_IFC1X 0
		PL_NOPS $1d5ae,3		;Trainer recruits
		PL_ENDIF
		PL_IFC1X 1
		PL_NOPS $171dc,2		;Trainer Grenades
		PL_ENDIF
		PL_IFC1X 2
		PL_NOPS $1abd2,2		;Trainer Bazookas
		PL_ENDIF
		PL_IFC1X 3
		PL_NOPS $1cfdc,1		;Trainer Invulnerability
		PL_ENDIF
		PL_NEXT	_pl

;======================================================================
; german

_pl2		PL_START
		PL_W	$26420,$6600
		PL_W	$26638,$4200
		PL_W	$279B4,$5200
		PL_W	$27C40,$4200
		PL_W	$28e48,$360+$32e	;load/save game (bsr $294d6)
		PL_S	$28e7a,$b8-$7a		;skips file "CFSDISK"
		PL_S	$2910e,4		;load/save game
		PL_W	$2911a,$8cc-$7ce	;load/save game (bsr $299e6 -> $29218)
		PL_CL	$29134			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_S	$2927a,10		;load/save game
		PL_CL	$298ae			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_R	$29bea			;"insert disk 3"
		PL_NEXT	_pl24

_s1		cmp.l	#$100000,d0
		bhs	.ret
		move.l	d0,a1			;original
		move.l	($20,a0),d0		;original
		rts
.ret		addq.l	#4,a7
		rts

;======================================================================
; french

_pl4		PL_START
		PL_W	$2640e,$6600
		PL_W	$26626,$4200
		PL_W	$2799a,$5200
		PL_W	$27C26,$4200
		PL_W	$28e2e,$35e+$324	;load/save game (bsr $294b0)
		PL_S	$28e60,$b8-$7a		;skips file "CFSDISK"
		PL_S	$290f2,4		;load/save game
		PL_W	$290fe,$892-$78c	;load/save game (bsr $29990 -> $29204)
		PL_CL	$29118			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_S	$29266,10		;load/save game
		PL_CL	$2985c			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_R	$29b94			;"insert disk 3"
		PL_NEXT	_pl24

;======================================================================
; italian

_pl5		PL_START
		PL_W	$1C352,$4200
		PL_W	$1C3F2,$4200
		PL_W	$1C406,$5200
		PL_W	$1C6Ea,$5200
		PL_W	$1C7A8,$4200
		PL_PS	$1ded4,_af
		PL_B	$22c6c,$6f		;beq -> ble
		PL_PS	$22d56,_s1
		PL_IFC1X 0
		PL_NOPS $1d5aa,3		;Trainer recruits
		PL_ENDIF
		PL_IFC1X 1
		PL_NOPS $171d8,2		;Trainer Grenades
		PL_ENDIF
		PL_IFC1X 2
		PL_NOPS $1abce,2		;Trainer Bazookas
		PL_ENDIF
		PL_IFC1X 3
		PL_NOPS $1cfd8,1		;Trainer Invulnerability
		PL_ENDIF
		PL_W	$2640e,$6600
		PL_W	$26626,$4200
		PL_W	$27998,$5200
		PL_W	$27C24,$4200
		PL_W	$28e2c,$94bc-$8e2c	;load/save game (bsr $294bc)
		PL_S	$28e5e,$b8-$7a		;skips file "CFSDISK"
		PL_S	$290ec,4		;load/save game
		PL_W	$290f8,$1fe-$0f8	;load/save game (bsr $299a0 -> $291fe)
		PL_CL	$29112			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_S	$29260,10		;load/save game
		PL_CL	$2986a			;move.l #xxxxxxxx,a0 (source for stringcopy)
		PL_R	$29ba4			;"insert disk 3"
		PL_NEXT	_pl

;======================================================================

_keyboard	movem.l	d0-d1/a0-a2,-(a7)
		lea	_ciaa,a0
		lea	_custom,a2
		btst	#CIAICRB_SP,(ciaicr,a0)
		beq	.end
		lea	$814e9,a1
		move.b	(ciasdr,a0),d0
		or.b	#CIACRAF_SPMODE,(ciacra,a0)
		ror.b	#1,d0
		not.b	d0
		bpl	.down
		move.b	(a1),d1
		eor.b	d0,d1
		and.b	#$7f,d1
		bne	.down
		moveq	#0,d0
.down		move.b	d0,(a1)

		cmp.b	(_keyexit),d0
		beq	.exit
		cmp.b   #$36,d0			;`N` ?
		beq	.skiplv
		cmp.b	#$5f,d0			;HELP ?
		bne	.wait
	;	move.w	#$4a79,$a2a2e		;enable sound (version 2)
		move.w	$8155a,d0		;aktuelles team
		lea	$821c4,a1
		st	(a1,d0.w)
		lea	$821ca,a1
		st	(a1,d0.w)
		lea	$81f50,a1
		add.w	d0,a1
		add.w	d0,a1
		move.w	#42,(a1)		;grenades
		move.w	#42,(6,a1)		;bazookas
		bra	.wait

.skiplv		move.w	#$ffff,$81dd0		;win phase/mission

.wait		moveq	#3-1,d1
.wait1		move.b	(vhposr,a2),d0
.wait2		cmp.b	(vhposr,a2),d0
		beq	.wait2
		dbf	d1,.wait1

.end		and.b	#~(CIACRAF_SPMODE),(ciacra,a0)
		move.w	#INTF_PORTS,(intreq,a2)
		tst.w	(intreqr,a2)
		movem.l	(a7)+,_MOVEMREGS
		rte

.exit		pea	TDREASON_OK
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
		move.l	(_expmem),a0
		lea	(_savepath),a1
.l1		move.b	(a1)+,(a0)+
		bne	.l1
		move.b	#"/",(-1,a0)
.l2		move.b	(a4)+,(a0)+
		bne	.l2
		move.l	(_expmem),a4

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
		move.l	(_expmem),A2
		LEA	(_savepath),A3
.l11		MOVE.B	(A3)+,(A2)+
		BNE.B	.l11
		MOVE.B	#"/",(-1,A2)
.l12		MOVE.B	(A0)+,(A2)+
		BNE.B	.l12
		move.l	(_expmem),A0
		MOVE.L	D1,D0
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
		MOVEM.L	(A7)+,D2-A6
		moveq	#0,D0
		RTS	

	;list directory
	;in:	a0 = source path
	;	a1 = buffer to fill
	;	a2 = mfm buffer
	;out:	d0 = success=0
	;	d1 = amount of entries
.cmd3		movem.l	d2-a6,-(a7)
		lea	(_savepath),a0
		move.l	a1,a6			;a6 = array
		move.l	(_expmem),a1
		move.l	#BUFLEN,d0
		move.l	(_resload),a2
		jsr	(resload_ListFiles,a2)
		move.l	d0,d7			;d7 = how many entries

		move.l	a6,a0
		move.l	(_expmem),a1
		move.w	d7,d0
		beq	.cmd3_skip
		
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
.cmd3_skip
	;avoid issue #2438
		moveq	#4,d1
		sub.w	d7,d1
		bcs	.cmd3_end
.cmd3_clr	clr.b	(2,a0)
		add.w	#32,a0
		dbf	d1,.cmd3_clr

.cmd3_end	move.l	d7,d1
		movem.l	(a7)+,d2-a6
		moveq	#0,d0
		rts

;======================================================================

	END
