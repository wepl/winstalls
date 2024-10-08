;*---------------------------------------------------------------------------
; Program:	BlackMonks.s
; Contents:	Slave for "Black Monks Cracktro" (c) 1989 Black Monks
; Author:	Codetapper of Action
; History:	06.01.02 - v1.0
;		         - Full load from HD
;		         - Keyboard routine added
;		         - Blitter wait added
;		         - Snoop bug fixed
;		         - High pass filter disabled for clearer sound
;		         - Copperlist bugs fixed (x2)
;		         - Intro can be compressed to save space (FImp, Propack etc)
;		         - Source included
;		         - Quit option (default key is 'F10')
;		2024-08-21 v1.1 by Wepl
;			- fixed access fault on 68000
;			- use standard keyboard routine
;		2024-08-22 by Wepl
;			- removed some dead code
; Requires:	WHDLoad 13+
; Copyright:	Public Domain
; Language:	68000 Assembler
; Translator:	Barfly
; Info:
;---------------------------------------------------------------------------*

		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"BlackMonks.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

_name		dc.b	"Black Monks Cracktro",0
_copy		dc.b	"1989 Black Knight",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.1 "
		INCBIN	.date
		dc.b	0
_MainFile	dc.b	"BlackMonks",0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		bsr	_SetupKeyboard

_restart	lea	_MainFile(pc),a0
		lea	$3c084,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		lea	_PL_Intro(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		move.w	#$83d0,$dff096		;Enable DMA

		jsr	$58000+$1bf9c-$1bf7c	;Start the intro, skip OS access at start
	
		pea	TDREASON_OK
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_PL_Intro	PL_START
		PL_P	$3462,_ByteWrite	;clr.b (6,a0,d0.w)
		PL_R	$1c048			;Restore O/S
		PL_PS	$1c26c,_Blt_dd6_dff058
		PL_W	$1c272,$4e71
		PL_END

;======================================================================

_ByteWrite	clr.w	(6,a0,d0.w)
		rts

;======================================================================

_Blt_dd6_dff058	move.w	#$dd6,$dff058

_BlitWait	btst	#6,$dff002
		bne	_BlitWait
		rts

;======================================================================

	INCLUDE	whdload/keyboard.s

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

