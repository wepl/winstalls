;*---------------------------------------------------------------------------
;  :Program.	North&South.asm
;  :Contents.	Slave for "North & South" from Infogrames
;  :Author.	Mr.Larmer of Wanted Team
;  :Version.	$Id: North&South.asm 1.1 1998/09/06 10:28:50 jah Exp jah $
;  :History.	20.12.98
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/exec_lib.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	whdload.i
	OUTPUT	dh2:north&south/North&South.slave
	OPT	O+ OG+			;enable optimizing

;======================================================================

base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	7		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10

	dc.b	'$VER:North & South HD by Mr.Larmer/Wanted Team - V1.3 (20.12.98)',0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	A0,A2
		lea	OSEmu(pc),A0		;file name
		lea	$400.w,A1		;address
		jsr	resload_LoadFile(a2)

		move.l	_resload(pc),a0
		lea	base(pc),a1
		jsr	$400.w

		move.w	#0,SR

		jsr	_LVODoIO(a6)
		move.l	IO_DATA(a1),a0

; calculate checksum for bootblock (probably not run cracked version)

		movem.l	D0-D2/A0-A2,-(a7)

		lea	12(A0),A0
		move.l	#$2A4,D0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

		cmp.w	#$8E19,D0
		bne.b	.not_support

		movem.l	(a7)+,D0-D2/A0-A2

		pea	.patch(pc)

		jmp	$C(a0)
.patch
		addq.l	#8,A0

		cmp.l	#$61A64A40,$7FFE(A0)
		bne.b	.another

		move.w	#$7001,$7FFE(A0)		; skip protection
.go
		subq.l	#8,A0

		jmp	(a0)
.another
		cmp.l	#$61A64A40,$7F42(A0)
		bne.b	.not_support

		move.w	#$7001,$7F42(A0)		; skip protection

		bra.b	.go
.not_support
		subq.l	#8,a7
		pea	TDREASON_WRONGVER.w
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

;--------------------------------

_resload	dc.l	0		;address of resident loader
OSEmu		dc.b	'OSEmu.400',0

;======================================================================

	END
