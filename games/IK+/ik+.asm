;*---------------------------------------------------------------------------
;  :Program.	ik+.asm
;  :Contents.	Slave for "IK+"
;  :Author.	WEPL
;  :Version.	$Id: ik+.asm 1.1 1998/03/16 16:58:59 jah Exp $
;  :History.	22.09.97 initial
;		01.10.97 debug key changed because F9 is used in game
;		24.11.98 adapted for v8 (obsoletes novbrmove)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	OUTPUT	wart:h-j/ik+/IK+.Slave
	BOPT	O+ OG+				;enable optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

;======================================================================

.base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	8			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-.base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem

;======================================================================

	DOSCMD	"WDate >T:date"
		dc.b	"$VER: IK+.Slave 1.2 by Wepl "
	INCBIN	"T:date"
		dc.b	0
	EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)

	IFEQ 1
		moveq	#0,d0			;offset
		move.l	#$400,d1		;size
		lea	$1000,a0		;destination
		sub.l	a1,a1			;tags
		move.l	(_resload),a2
		jsr	(resload_DiskLoadDev,a2)
		skip	6*2,$100c+$1a
		clr.w	$500			;stackframe format error
		jmp	$100c
	ENDC

		lea	(_file),a0
		lea	$600,a1
		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)

		lea	(_ciaa),a1
		or.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr,a1)	;allow ints and clear requests
		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)		;input mode

		ret	$2475c			;copylock
		clr.w	$500			;stackframe format error
		ret	$1976			;preserve NMI
		patch	$1aaa,_keyb

		jmp	$600

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

_file		dc.b	"IK+.Image",0
_resload	dc.l	0			;address of resident loader

;======================================================================

	END

