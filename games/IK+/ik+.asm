;*---------------------------------------------------------------------------
;  :Program.	ik+.asm
;  :Contents.	Slave for "IK+"
;  :Author.	Wepl
;  :Version.	$Id: ik+.asm 1.3 2001/07/14 10:14:47 jah Exp jah $
;  :History.	22.09.97 initial
;		01.10.97 debug key changed because F9 is used in game
;		24.11.98 adapted for v8 (obsoletes novbrmove)
;		13.07.01 supports another version
;		01.08.01 highscore saving added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:i/ik+/IK+.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"IK+",0
_copy		dc.b	"1988 Archer Maclean",0
_info		dc.b	"installed and fixed by Wepl",10
		dc.b	"Version 1.4 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_file		dc.b	"IK+.Image",0
_savename	dc.b	"IK+.Highs",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)
		move.l	a0,a2

	IFEQ 1
		moveq	#0,d0			;offset
		move.l	#$400,d1		;size
		lea	$1000,a0		;destination
		sub.l	a1,a1			;tags
		jsr	(resload_DiskLoadDev,a2)
		skip	6*2,$100c+$1a
		clr.w	$500			;stackframe format error
		jmp	$100c
	ENDC

		lea	(_file),a0
		lea	$600,a1
		jsr	(resload_LoadFileDecrunch,a2)
		lea	$600,a0
		jsr	(resload_CRC16,a2)
		cmp.w	#$8570,d0		;Original
		beq	.ok
		cmp.w	#$bfb0,d0		;CDTV/HitSquad
		beq	.ok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.ok
		lea	(_pl),a0
		sub.l	a1,a1
		jsr	(resload_Patch,a2)

		lea	(_ciaa),a1
		tst.b	(ciaicr,a1)				;clear requests
		move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr,a1)	;allow ints
		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)		;input mode

		jmp	$600

_pl	PL_START
	PL_R	$2475c			;copylock
	PL_W	$500,0			;stackframe format error
	PL_R	$1976			;preserve NMI
	PL_P	$1aaa,_keyb
	PL_PS	$12bc+$600,_loadhighs
	PL_PS	$9cde+$600,_savehighs
	PL_END

_loadhighs	lea	_savename,a0
		move.l	_resload,a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.end
		lea	_savename,a0
		move.l	_expmem,a1
		jsr	(resload_LoadFile,a2)
		bsr	_swaphighs
		move.b	#1,$610		;original
.end		rts

_savehighs	bsr	_swaphighs
		move.l	#6*51,d0
		lea	_savename,a0
		move.l	(_expmem),a1
		move.l	_resload,a2
		jsr	(resload_SaveFile,a2)
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		rts

_swaphighs	move.l	(_expmem),a0
		lea	$a27,a1		;name x..
		bsr	.swap
		lea	$a5a,a1		;name .x.
		bsr	.swap
		lea	$a8d,a1		;name ..x
		bsr	.swap
		lea	$98e,a1		;score xx..00
		bsr	.swap
		lea	$9c1,a1		;score ..xx00
		bsr	.swap
		lea	$9f4,a1		;belt
.swap		moveq	#51-1,d0
.loop		move.b	(a0),d1
		move.b	(a1),(a0)+
		move.b	d1,(a1)+
		dbf	d0,.loop
		rts

_keyb		cmp.b	(_keyexit),d0
		beq	_exit
		jsr	$1b5e			;original
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2_w1	move.b	(_custom+vhposr),d0
.int2_w2	cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2_w2
		dbf	d1,.int2_w1		;(min=127탎 max=190.5탎)
		jmp	$1ace

;--------------------------------

_exit		move	#$2700,sr		;otherwise freeze inside whdload
		lea	($80000),a7		;otherwise "bad stackpointer" on exit
		pea	TDREASON_OK.w
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------

_resload	dc.l	0			;address of resident loader

;======================================================================

	END

