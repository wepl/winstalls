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

;======================================================================

_base		SLAVE_HEADER				;ws_Security + ws_ID
		dc.w	10				;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_NoDivZero	;ws_flags
		dc.l	$80000				;ws_BaseMemSize
		dc.l	$4e800				;ws_ExecInstall
		dc.w	_Start-_base			;ws_GameLoader
		dc.w	0				;ws_CurrentDir
		dc.w	0				;ws_DontCache
_keydebug	dc.b	0				;ws_keydebug = F9
_keyexit	dc.b	$59				;ws_keyexit = F10
_expmem		dc.l	0				;ws_ExpMem
		dc.w	_name-_base			;ws_name
		dc.w	_copy-_base			;ws_copy
		dc.w	_info-_base			;ws_info

;============================================================================

_name		dc.b	"Powermonger",0
_copy		dc.b	"1990 Bullfrog Productions",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"version 1.3 "
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

_introdat	DC.B	'INTRODAT'
_start_up	DC.B	'START_UP'
_run_prog	DC.B	'RUN_PROG'
_resload	dc.l	0		;address of resident loader
_keyint		dc.l	0

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
