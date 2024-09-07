;*---------------------------------------------------------------------------
; Program:	Zyconix.s
; Contents:	Slave for "Zyconix" (c) 1992 Accolade
; Author:	Codetapper
; History:	25.05.01 - v1.0
;		         - Full load from HD
;		         - Empty DBF loops fixed
;		         - Original game bugs fixed (move.b #$82,$bfd01 -> move.b #$82,$bfed01)
;		         - RomIcon, NewIcon and OS3.5 coloricon (created by me!)
;		         - Quit option (default key is 'F10')
;		25.05.21 - v1.1
;		         - Now supports the original (only 20 years late!)
;		         - Loads and saves high scores
;		         - Source code included
; Requires:	WHDLoad 13+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:		High score saving routine is called at $eba2 in the 
;		original (jsr $14c0)
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Zyconix.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

PatList	MACRO
	IFNE	NARG-1
		FAIL	arguments "Patchlist"
	ENDC
		movem.l	d0-d1/a0-a2,-(sp)
		lea	\1(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		movem.l	(sp)+,d0-d1/a0-a2
	ENDM

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

;============================================================================

_name		dc.b	"Zyconix",0
_copy		dc.b	"1992 Accolade",0
_info		dc.b	"Installed by Codetapper!",10
		dc.b	"Version 1.1 "
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		dc.b	-1,"Thanks to Gunnar Andersson, Xavier Bodenand and"
		dc.b	10,"Irek Kloska for sending the originals!"
		dc.b	-1,"Greetings to Riempie and CFou!"
		dc.b	0
_config		dc.b	0
_Highs		dc.b	"Zyconix.highs",0
		EVEN
_FileTable	dc.l	  1, $55ca		;Track number, file length
		dc.l	  5,  $3fc		;Highscores
		dc.l	  6, $d918
		dc.l	 16,$2fcb8
		dc.l	 32,$19cb8
		dc.l	 51, $febe
		dc.l	 63, $509e
		dc.l	 67, $5000
		dc.l	 71,$1589e
		dc.l	 87, $c70c
		dc.l	 97,$1594e
		dc.l	113,$16ff0
		dc.l	130,$1551a
		dc.l	146,$12444
		dc.l	  0,     0		;End of table

;======================================================================
_Start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	resetregs

		lea	$30000,a0		;Load original data
		move.l	#$1600,d0
		move.l	#$5800,d1
		bsr	_DiskLoad

		cmp.l	#$e8d0,$3006e		;Check for the original
		bne	_CheckCrystal

		PatList	_PL_Accolade
		jmp	$30000

_PL_Accolade	PL_START
		PL_P	$3006c,_Game
		PL_P	$304f6,_Loader		;Load data
		PL_END

;======================================================================

_CheckCrystal	move.l	#$400,d0		;offset
		move.l	#$6600,d1		;size
		lea	$50000-$24,a0		;destination address
		bsr	_DiskLoad

		cmp.l	#$40000,$500ac		;Check for Crystal crack
		bne	_wrongver

		PatList	_PL_Crystal
		jmp	$50000			;Decrunch intro (Bytekiller 1.3)

_PL_Crystal	PL_START
		PL_P	$500aa,_AccoladeCrack
		PL_END

;======================================================================

_AccoladeCrack	PatList	_PL_AccoladeCrk
		jmp	$30000			;Start Crystal cracked game

_PL_AccoladeCrk	PL_START
		PL_P	$3006c,_Game		;Patch game
		PL_R	$304ec			;Stupid delay after loading
		PL_P	$3186e,_LoaderCrystal
		PL_END

;======================================================================

_Game		PatList	_PL_Game
		jmp	$e8d0			;Stolen code

_PL_Game	PL_START
		PL_P	$100,_BeamDelayD0	;Empty DBF loop
		PL_P	$14c0,_SaveHighScores
		PL_L	$1522,$4eb80100
		PL_L	$3cce,$4eb80100
		PL_L	$bf6e,$4eb80100
		PL_L	$bfaa,$4eb80100
		PL_L	$df8a,$bfed01		;move.b #$82,$bfd01
		PL_PS	$dfe4,_EmptyDBF
		PL_W	$dfea,$4e71
		PL_PS	$dff2,_Keybd		;Detect quit key
		PL_END

;======================================================================

_Loader		movem.l	d0-d2/a0-a2,-(sp)
		lea	_FileTable(pc),a2
.SearchNext	move.l	(a2)+,d2		;d2 = Track number
		move.l	(a2)+,d1		;d1 = Length
		beq	_wrongver
		cmp.w	d0,d2
		bne	.SearchNext
		mulu	#$1600,d2
		move.l	d2,d0
		bsr	_DiskLoad
		movem.l	(sp)+,d0-d2/a0-a2
		moveq	#0,d0
		rts

_LoaderCrystal	move.l	d5,d0			;d0 = Offset
		move.l	d6,d1			;d1 = Length
		bsr	_DiskLoad
		movem.l	(sp)+,d1-d7/a0-a6	;Game has already stacked stuff
		moveq	#0,d0
		rts

_DiskLoad	movem.l	d0-d1/a0-a2,-(sp)
		movea.l	_resload(pc),a2
		cmp.l	#$6e00,d0		;Check we are loading highscores
		bne	.NormalDiskLoad		;$offset $6e00 length $3fc

		move.l	a0,a1			;Check the file exists
		lea	_Highs(pc),a0
		bsr	_GetFileSize
		beq	.NotFound		;Loading high scores but file not found
		jsr	resload_LoadFileDecrunch(a2)
		bra	.Done

.NotFound	move.l	#$6e00,d0		;Restore stuff and load from disk image instead
		move.l	a1,a0

.NormalDiskLoad	moveq	#1,d2			;d2 = Disk number
		movea.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
.Done		movem.l	(sp)+,d0-d1/a0-a2
		rts

_GetFileSize	movem.l	d1/a0-a2,-(sp)
		movea.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(sp)+,d1/a0-a2
		tst.l	d0
		rts

;======================================================================

_SaveHighScores	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a0,a1			;a1 = Destination ($14d52)
		lea	_Highs(pc),a0		;a0 = High score filename
		move.l	#$3fc,d0		;Length
		movea.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2w2
		dbf	d1,.int2w1		;(min=127탎 max=190.5탎)
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_BeamDelayD0	divu	#40,d0
		and.l	#$ffff,d0
		movem.l	d0-d1,-(sp)
		move.l	d0,d1
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2w2
		dbf	d1,.int2w1
		movem.l	(sp)+,d0-d1
		move.w	#-1,d0
		rts

;======================================================================

_Keybd		not.b	d0			;Stolen code
		ror.b	#1,d0
		move.b	d0,d1

		cmp.b	_keyexit(pc),d0
		beq	_exit
		rts

;======================================================================
_resload	dc.l	0			;Address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
;_debug		pea	TDREASON_DEBUG
;		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
