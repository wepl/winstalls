;*---------------------------------------------------------------------------
;  :Program.	powermonger.asm
;  :Contents.	Slave for "PowerMonger"
;  :Author.	Wepl
;  :Original.	v1 original	Peter Schreck
;		v2 Hit Squad	Harley Kingston <hkingston@ozemail.com.au>
;  :Version.	$Id: powermonger.asm 1.3 2002/07/17 21:04:26 wepl Exp wepl $
;  :History.	20.05.96
;		09.12.96 reworked for diskimages and clean media
;		30.12.96 ws_DontCache removed (WARNING ws_Version is only 1)
;		22.04.98 keyboard changed, adapted for new whdload, rework
;		17.07.02 rework, intro sound fixed
;		09.02.24 repo import
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER					;disable supervisor warnings
	ENDC

;DEBUG
;QUICKSTART=1
;SHOWTIME=1
EXPSIZE=$80000

;======================================================================

_base		SLAVE_HEADER				;ws_Security + ws_ID
		dc.w	18				;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_NoDivZero	;ws_flags
		dc.l	$80000				;ws_BaseMemSize
		dc.l	0				;ws_ExecInstall
		dc.w	_Start-_base			;ws_GameLoader
		dc.w	0				;ws_CurrentDir
		dc.w	0				;ws_DontCache
_keydebug	dc.b	0				;ws_keydebug = F9
_keyexit	dc.b	$59				;ws_keyexit = F10
_expmem		dc.l	-EXPSIZE			;ws_ExpMem
		dc.w	_name-_base			;ws_name
		dc.w	_copy-_base			;ws_copy
		dc.w	_info-_base			;ws_info
		dc.w	0				;kickstart name
		dc.l	0				;kicksize
		dc.w	0				;kickcrc
		dc.w	_config-_base
_config
		dc.b	"C1:L:Fast RAM use:Auto,Off,On;"
		; C2 is frame rate limit
		dc.b	"C3:X:All maps conquered:0;"
		dc.b	"C3:X:Win on retire:1;"
		dc.b	0

;============================================================================

_name		dc.b	"Powermonger",0
_copy		dc.b	"1990 Bullfrog Productions",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"update by paraj",10
		dc.b	"version 1.4 "
		INCBIN	".date"
		dc.b	0
_keyexit2	dc.b	$45				;ws_keyexit = ESC
	IFD DEBUG
_run_prog_dec	DC.B	'RUN_PROG.dec',0
	ENDC
	EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)

	;get custom settings
		move.l	a0,a1
		lea	(_tags,pc),a0
		jsr	(resload_Control,a1)

	;decide whether to use fastmem
		move.l	(_custom1,pc),d0
		beq	.autofast
		cmp.b	#1,d0
		beq	.nofast
		bra	.usefast
.autofast
	;auto -> use if 030+
		moveq	#-4,d0
		and.b	(_attnflags+3,pc),d0
		beq	.nofast
.usefast
	;move stack to fast mem
		move.l	(_expmem,pc),d0
		beq	.nofast
		lea	(_fastbuf,pc),a0
		move.l	d0,(a0)
		add.l	#EXPSIZE,d0
		move.l	d0,a0
		move.l	a0,sp
		lea	(-$400,a0),a0
		move.l	a0,usp
.nofast

	;install keyboard quitter
		bsr	_SetupKeyboard
		
	;load disk directory
DIR = $400
		move.l	#$1600,d0			;offset
		move.l	#512,d1				;size
		moveq	#1,d2				;disk
		lea	DIR,a0				;destination
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)

	IFND QUICKSTART

	;load intro
		lea	(_introdat),a0
		movea.l	#$00022674,a1
		jsr	_Loader

	;load intro
		lea	(_start_up),a0
		lea	$1000,a1
		jsr	_Loader

	;run intro
		and.w	#~(INTF_INTEN|INTF_PORTS),($a,a1)
		and.w	#~(INTF_INTEN|INTF_PORTS),($2c2,a1)
		and.w	#~(INTF_INTEN|INTF_PORTS),($2f4,a1)
		addq.w	#1,($c16,a1)			;aud1vol
		jsr	(a1)

	ENDC

	;enable caches
		move.l	#CACRF_EnableI,d0
		move.l	d0,d1
		move.l	(_resload),a0
		jsr	(resload_SetCACR,a0)

	;build copperlist
		lea	_custom,a6
		moveq	#-2,d0
		lea	$300,a0
		move.l	d0,(a0)
		move.l	a0,(cop1lc,a6)
		tst.w	(copjmp1,a6)
		move	#$7fff-(INTF_INTEN|INTF_PORTS),(intena,a6)
		move	#$7fff,(dmacon,a6)
		
	;load main
		LEA	(_run_prog),A0
		MOVEA.L	#$00001000,A1
		JSR	_Loader

	;decrunch main
		cmp.l	#$227c0000,(4,a1)
		beq	.o
		cmp.l	#$61064cdf,(4,a1)
		bne	_exit
		patch	$b6(a1),.ad
		jmp	(4,a1)				;decrunch the shit
.o		ret	$14(a1)
		jsr	(4,a1)				;decrunch the shit
.ad
	IFD DEBUG
		move.l	#110804,d0
		lea	$1400,a1
		lea	_run_prog_dec,a0
		move.l	_resload,a2
		jsr	(resload_SaveFile,a2)
	ENDC

	;keyboard stuff
		and.w	#~(INTF_INTEN|INTF_PORTS),$142a
		lea	(_keyint),a0
		move.l	($68),(a0)
		lea	(_keyb),a0
		move.l	a0,($68)
		ret	$18f8
	;	ill	$1938
	;	jsr	$1400+$516

		patchs	$1400+$2462,_bug1		;access fault "word read from $82120 pc=$389c"

		move.w	#$7000,$1400+$aca0		;copylock
	;	lea	$1440+$b36c,a0

		nops	3,$1474				;check for exp mem

	;	patch	$582+$1400,_keyboard

		patch	$dd94,_load_dd94
	
	;	ill	$e148				;endlos loop wenn error in decrunching
	;	bad because will entered in extro

	;	patch	$1a2d0+$1400,$1a36e+$1400	;insert powermonger-disk
		move.w	#$4ef9,$1a2d0+$1400
		move.l	#$1a36e+$1400,$1a2d0+$1400	;insert powermonger-disk

		ret	$1bdfa				;format save-disk
		ill	$1ac02+$1400
	
		patch	$1bf2e,_loadsavegame
		patch	$1ac54+$1400,_savesavegame
	
	;	nops	5,$1a3ca+$1400			;btst #4,bfdd00, beq again
	;	ret	$1ba7e				;loader ??
	;	ret	$1b910				;init bfd100
	;	ret	$1a67e+$1400			;check dirlist
	
		ret	$1a510+$1400

		patchs	$12870,_initbuffers
		ret	$c73a				;skip "wait for protection"
		patch	$bcc4,_handlecopyprot		;dismiss immediately

	IFD QUICKSTART
		nops	1,$136bc			;skip name entry dialog
		patchs	$13712,_quickstart		;click "start"
	ELSE
		patchs	$1aca0,_palfadedelay		;spin delay in palette fade
	ENDC

		bsr	_fastpatches

		lea	(_pl_trainer,pc),a0
		sub.l	a1,a1
		move.l	(_resload,pc),a2
		jsr	(resload_Patch,a2)

		Jsr	$1400.W
		bra	_exit

;--------------------------------

_bug1		and.w	#$00ff,d5
		move.w	d5,d1
		mulu	#$20,d1
		rts
		
;--------------------------------
; game's keyboard stuff (uses mulu for delay...)

_keyb		movem.l	d0/a0,-(a7)
		lea	($534b6),a0
		moveq	#0,d0
		move.b	$bfec01,d0
		move.b	d0,$71b2
		bclr	#0,d0			;key up/down ?
	;	sne	$1a2e
		sne	(1,a0,d0.l)
	;	and.b	#1,(a0,d0.l)
		movem.l	(a7)+,_MOVEMREGS
		move.l	(_keyint),-(a7)
		rts

;--------------------------------

_loadsavegame
	movem.l	d1/a0-a2,-(a7)
;	MOVE.W	#$0090,$00001FF4.L	;switch to black bg

	lea	_letter,a0
	MOVE.B	$0000E093.L,(a0)	;letter of saveplace

	lea	_fname,a0
	move.l	(_resload),a2
	jsr	(resload_CheckFileExist,a2)
	tst.l	d0
	bne	.go
	JSR	$0001C222.L		;REQ savegame does not exist
	moveq	#0,d0			;failed
	Bra	.end
.go
	lea	_fname,a0
	lea	$6577c,a1
	move.l	(_resload),a2
	jsr	(resload_LoadFileDecrunch,a2)

.end
;	MOVE.W	#0,$00001FF4.L		;switch to game bg
	movem.l	(a7)+,d1/a0-a2
	rts


_savesavegame
	movem.l	d1/a0-a2,-(a7)
;	MOVE.W	#$0090,$00001FF4.L

	lea	_letter,a0
	MOVE.B	$0000E093.L,(a0)	;letter of saveplace

	lea	_fname,a0		;name
	move.l	(_resload),a2
	jsr	(resload_CheckFileExist,a2)
	tst.l	d0
	beq	.go
	JSR	$0001C1FA.L		;REQ savegame already exist
	TST.W	D0
	BNE	.end
.go
	move.l	#$18be1,d0		;size
	lea	_fname,a0		;name
	lea	$6577c,a1		;address
	move.l	(_resload),a2
	jsr	(resload_SaveFile,a2)
.end
	MOVE.W	#0,$00001FF4.L
	movem.l	(a7)+,d1/a0-a2
	rts
	
_fname	dc.b	"save/"
_letter	dc.b	0,0,0

;--------------------------------

_load_dd94	movem.l	d0-a6,-(a7)
		move.w	($40,a7),d2		;number of file
		bne	.g
		move.l	(_texturesptr,pc),d3
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
_texturesptr	dc.l	($000535ea+$80)&$ffffff80 ; original address

;--------------------------------

_Loader		movem.l	d1-d2/a0-a2,-(a7)

		move.l	(a0)+,d0
		move.l	(a0),d1
		move.l	a1,a0				;destination
		lea	DIR,a2
.find		add.w	#16,a2
		cmp.l	(a2),d0
		bne	.find
		cmp.l	(4,a2),d1
		bne	.find
		move.w	(8,a2),d0
		mulu.w	#11*512,d0			;offset
		move.l	(12,a2),d1			;size
		move.l	d1,-(a7)
		moveq	#1,d2				;disk
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)

	IFD DEBUG
		move.l	a2,a0
		move.l	(a7),d0
		move.l	(16,a7),a1
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)
	ENDC

		movem.l	(a7)+,d0-d2/a0-a2		;size returned in d0 !!!
		rts
;		bra	_kinit

;--------------------------------
_palfadedelay
		; Most registers available
		; Original code spins for ~200K 7Mhz cycles
		move.w	#440,d0 ; a bit under (1/7e6)*2e5*(313*50) ~= 447
.wait1
		move.b	vhposr+_custom,d1
.wait2
		cmp.b	vhposr+_custom,d1
		beq	.wait2
		dbf	d0,.wait1
		rts

;--------------------------------

BUFSIZE=320*200*4/8
BitplanePtr1=$535c2
BitplanePtr2=$535c6
BitplanePtr3=$0df16
CurBufferOffset=$1ab8
BufferSwapped=$535d6
FrameCounter=$3b796
LMBClicked=$535e0

_initbuffers
	IFD SHOWTIME
		patchs	$1a70,_showtimeswap
	ENDC

		move.l	(_fastbuf,pc),d0
		beq	.nofast

		lea	(_origbufs,pc),a0
		move.l	BitplanePtr2,(a0)+	;reverse order
		move.l	BitplanePtr1,(a0)
		move.l	d0,a0
		move.l	d0,BitplanePtr1
		add.l	#BUFSIZE,d0
		move.l	d0,BitplanePtr2
		add.l	#BUFSIZE,d0
		move.l	d0,BitplanePtr3
		add.l	#BUFSIZE,d0
		lea	(_fastbuf,pc),a1
		move.l	d0,(a1)

		move.w	#BUFSIZE*3/4-1,d0
.cl
		clr.l	(a0)+
		dbf	d0,.cl

		patchs	$1a70,_swapbuffers
		patch	$1ad4,_waitswap
		patchs	$1ae4e,_endseq

		patchs	$129a2,_ingamewaitswap
		patchs	$13178,_ingameswap

		; Patch uses of BitplanePtr1 that need to be directly displayed
		; Other references rules out
		lea.l	(_currentfb,pc),a0
		move.l	a0,$4628 ; Not sure about this one, but should be benign
		move.l	a0,$1add2
		move.l	a0,$1ad28
		move.l	a0,$1aa80
.nofast
		jmp	$1363a

_doswap
		movem.l d0/a0-a1,-(sp)
		move.l	CurBufferOffset,d0
		move.l	(_origbufs,pc,d0.l),a0
		lea	(_currentfb,pc),a1
		move.l	a0,(a1)
		move.l	BitplanePtr2,a1
		move.w	#BUFSIZE/16-1,d0
.l
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		move.l	(a1)+,(a0)+
		dbf	d0,.l
		movem.l (sp)+,d0/a0-a1
		rts

_origbufs	dc.l	0,0
_currentfb	dc.l	0			;current front buffer
_nexttime	dc.l	0
_savedclick	dc.w	0

; The pre-game menus all have loops roughly like this:
;	jsr	WaitBufferSwapped
;	jsr	Render
;	jsr	HandleInput
;	jsr	SwapBuffers
;	clr.w	LMBClicked
;
; Which is based on the assumption that the VBL interrupt (that checks for mouse clicks)
; happens after clearing LMBClicked and before HandleInput.
; Otherwise clicks can get lost. This also happens in the stock game (especially on the
; map selection screen), but is more likely with "SwapBuffers" now taking significant
; time instead of only having to swap copperlists.
;
; Try to work around this by ensure a VBL happens after swapping, and save the result,
; restoring it in "WaitBufferSwapped".

_swapbuffers
		clr.w	LMBClicked
	IFD SHOWTIME
		bsr	_showtime
	ENDC
		bsr	_doswap

		clr.w	BufferSwapped
.w
		tst.w	BufferSwapped
		beq	.w

		lea	(_savedclick,pc),a0
		move.w	LMBClicked,(a0)		;preserve mouse clicks that happened during copy
		move.l	BitplanePtr1,a0		;original code
		rts

_waitswap
		move.w	d0,-(sp)
		move.w	(_savedclick,pc),d0
		or.w	d0,LMBClicked
		move.w	(sp)+,d0
		rts

_ingamewaitswap
		; original code
		move.w	$3b79,$3b79c
		clr.w	$3b79a
.waitswap
		tst.w	BufferSwapped
		beq	.waitswap
		; frame rate limit
		movem.l d0-d1/a0,-(sp)
		lea	(_nexttime,pc),a0
		move.l	(a0),d0
.limit
		move.l	FrameCounter,d1
		cmp.l	d1,d0
		bhi	.limit
		add.l	(_custom2,pc),d1
		move.l	d1,(a0)
		movem.l (sp)+,d0-d1/a0
		rts

_ingameswap
	IFD SHOWTIME
		bsr	_showtime
	ENDC
		bsr	_doswap
		; continue with original code
		movem.l d0/a0,-(sp)
		move.l	BitplanePtr1,a0
		jmp	$1a76


_endseq
		; Copy "END_PIC1" to front buffer
		move.l	$df9a,a0
		move.l	(_currentfb,pc),a1
		jsr	$1af94
		lea	$1abc2,a1		;original code
		rts

	IFD SHOWTIME

_showtimeswap
		bsr	_showtime
		move.l	BitplanePtr1,a0		;original code
		rts
_showtime
		movem.l d0-d1/a0-a1,-(sp)
		move.l	FrameCounter,d0
		lea	(.lasttime,pc),a0
		move.l	(a0),d1
		move.l	d0,(a0)
		sub.l	d1,d0
		move.l	BitplanePtr2,a0
		lea	(40,a0),a0

		lea	(-4,a0),a1
		moveq	#8-1,d1
.clr
		clr.l	(a1)
		clr.l	(8000,a1)
		clr.l	(16000,a1)
		clr.l	(24000,a1)
		lea	(40,a1),a1
		dbf	d1,.clr
		bsr	_drawnum

		movem.l (sp)+,d0-d1/a0-a1
		rts
.lasttime	dc.l	0

_drawnum
		divu.w	#10,d0
		swap	d0
		lea	(-1,a0),a0
		move.l	d0,d1
		and.w	#$f,d1
		lsl.w	#3,d1
		lea	(.chardata,pc,d1.w),a1
		moveq	#8-1,d1
.y
		clr.b	(a0)
		clr.b	(8000,a0)
		move.b	(a1)+,(16000,a0)
		clr.b	(24000,a0)
		lea	(40,a0),a0
		dbf	d1,.y
		lea	(-320,a0),a0
		clr.w	d0
		swap	d0
		bne	_drawnum
		rts
.chardata
		dc.b	%00111100,%01100110,%01101110,%01111110,%01110110,%01100110,%00111100,%00000000  ; 0
		dc.b	%00011000,%00111000,%01111000,%00011000,%00011000,%00011000,%00011000,%00000000  ; 1
		dc.b	%00111100,%01100110,%00000110,%00001100,%00011000,%00110000,%01111110,%00000000  ; 2
		dc.b	%00111100,%01100110,%00000110,%00011100,%00000110,%01100110,%00111100,%00000000  ; 3
		dc.b	%00011100,%00111100,%01101100,%11001100,%11111110,%00001100,%00001100,%00000000  ; 4
		dc.b	%01111110,%01100000,%01111100,%00000110,%00000110,%01100110,%00111100,%00000000  ; 5
		dc.b	%00011100,%00110000,%01100000,%01111100,%01100110,%01100110,%00111100,%00000000  ; 6
		dc.b	%01111110,%00000110,%00000110,%00001100,%00011000,%00011000,%00011000,%00000000  ; 7
		dc.b	%00111100,%01100110,%01100110,%00111100,%01100110,%01100110,%00111100,%00000000  ; 8
		dc.b	%00111100,%01100110,%01100110,%00111110,%00000110,%00001100,%00111000,%00000000  ; 9
	ENDC

;--------------------------------
	IFD QUICKSTART
_quickstart
		move.w	#6,$535b8	;"play random land"
		move.w	#$42b9,$137f0	;same "random" seed every time
		rts
.landid		dc.l	0

	ENDC

;--------------------------------

TABLESTART=$e51c
TABLEMID=$e59c
TABLEEND=$e81c

TABLESTART2=$91d8
TABLEMID2=$91e0
TABLEEND2=$98a0

_fastpatches
		lea	(_fastbuf,pc),a3
		move.l	(a3),d0
		bne	.gotfast
		rts
.gotfast
		; Textures first (code 128-bytes aligns address)
		lea	(_texturesptr,pc),a1
		move.l	d0,(a1)
		add.l	#$3300,d0
		lea	(.table,pc),a1
.patchloop
		move.l	(a1)+,d1	;size
		beq	.patchdone
.reloc
		move.l	(a1)+,d2
		beq	.next
		move.l	d2,a2
		move.l	d0,(a2)
		bra	.reloc
.next
		addq.l	#7,d1
		and.b	#-8,d1
		add.l	d1,d0
		bra	.patchloop
.patchdone

		move.l	d0,a1
		add.l	#TABLEEND-TABLESTART,d0
		move.l	d0,(a3)

		; Heavily used masking tables
		lea	(TABLEMID-TABLESTART,a1),a0
		move.l	a0,$e4c4
		move.l	a0,$f154
		lea	TABLESTART,a0
		move.w	#(TABLEEND-TABLESTART)/4-1,d0
.copytable
		move.l	(a0)+,(a1)+
		dbf	d0,.copytable

		; Dialog text/borders
		move.l	(a3),a0
		add.l	#TABLEEND2-TABLESTART2,(a3)
		lea	(_dlgdata,pc),a1
		move.l	a0,d0
		add.l	#TABLEMID2-TABLESTART2,d0
		move.l	d0,(a1)
		lea	TABLESTART2,a1
		move.w	#(TABLEEND2-TABLESTART2)/2-1,d0
.cl2
		move.w	(a1)+,(a0)+
		dbf	d0,.cl2

		patchs	$82ac,_a6dlgdata

		btst	#9-8,vposr+_custom
		beq	.noaga

		move.l	#$03b7a0,$172e	; 64-bit align bitplane buffers
		patch	$148c,_exit	; and avoid using now-corrupted "OldLevel3Vec"

		move.w	#$3,fmode+_custom
		move.b	#$b8,$1815	; adjust ddfstop
.noaga

		rts
.table
		; SPRITE16
		dc.l	7520
		dc.l	$df22,$1123c,$11afa,0
		; SPRITE8
		dc.l	19580
		dc.l	$df2e,$117ea,0
		; SPRITE24
		dc.l	12960
		dc.l	$df3a,$1127a,$11b1a,0
		; SPRITE32
		dc.l	17280
		dc.l	$df46,$0112bc,$11b3c,0
		; done
		dc.l	0

_dlgdata	dc.l	0

_a6dlgdata
		move.l	(_dlgdata,pc),a6
		moveq	#24,d4		;original code
		rts

;--------------------------------
_handlecopyprot
		jsr	$b184		;text replacement (sets up challenge)
		jmp	$c06e		;dismiss dialog immediately
;--------------------------------

_pl_trainer	PL_START
		PL_IFC3X 0
		PL_P	$13762,_alllevels
		PL_NOPS $1ad04,1		;can win in first game
		PL_ENDIF
		PL_IFC3X 1
		PL_B	$db22,$60
		PL_ENDIF
		PL_END


_alllevels
		cmp.w	#2,$535b8		;new game?
		bne	.out
		lea	$648ea,a0
		move.w	#195-1,d0
		moveq	#1,d1
.fill
		move.b	d1,(a0)+
		dbf	d0,.fill
.out
		jmp	$1aac6			;fade to black
;--------------------------------

_introdat	DC.B	'INTRODAT'
_start_up	DC.B	'START_UP'
_run_prog	DC.B	'RUN_PROG'
_resload	dc.l	0		;address of resident loader
_keyint		dc.l	0
_fastbuf	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	TAG_DONE
;--------------------------------

_exit		pea	TDREASON_OK.w
		bra	_end
_debug		pea	TDREASON_DEBUG.w
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	INCLUDE	whdload/keyboard.s

;======================================================================

	END
