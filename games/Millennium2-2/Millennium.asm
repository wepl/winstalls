;*---------------------------------------------------------------------------
;  :Program.	Millenium.asm
;  :Contents.	Slave for "Millenium" from 
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	31.08.98
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i

	OUTPUT	dh1:demos/millennium/Millennium.slave
	OPT	O+ OG+			;enable optimizing

;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	7		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$58		;ws_keydebug = F9
_keyexit	dc.b	$59		;ws_keyexit = F10

	dc.b	'$VER:Millenium HD by Mr.Larmer/Wanted Team - V0.1 (31.08.98)',0
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

; alloc mem for bootblock

		move.l	#$400,D0
		moveq	#0,D1
		move.l	4.w,a6
		jsr	-$C6(a6)		; AllocMem
		move.l	d0,-(A7)
		beq.b	.skip

; read bootblock

		move.l	d0,a0
		moveq	#0,D0
		move.l	#$400,D1
		moveq	#1,d2
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

; calculate checksum for bootblock (probably not run cracked version)

		move.l	#$400,D0
		move.l	(a7),a0
		move.l	_resload(pc),a2
		jsr	resload_CRC16(a2)

		cmp.w	#$C367,D0
		bne.b	.skip

; alloc mem for IOstruct (why OSEmu module not return in A1 that ptr struct?)

		moveq	#88,D0
		moveq	#0,D1
		move.l	4.w,a6
		jsr	-$C6(a6)		; AllocMem
		move.l	d0,-(A7)
		beq.b	.skip

; open trackdisk.device

		moveq	#0,D0
		moveq	#0,D1
		move.l	(a7),a1
		lea	80(a1),a0		; port struct
		move.l	a0,14(a1)
		lea	trackname(pc),a0
		move.l	4.w,a6
		jsr	-$1BC(A6)		; OpenDevice

		move.l	(a7)+,a1
		move.l	(a7)+,a0

;		move.w	#$4E71,$338(A0)		; insert RTS (skip intro)

		move.w	#$4E75,$368(A0)		; insert RTS (go to patch)
		pea	patch(pc)
.skip
		jmp	$C(a0)

OSEmu		dc.b	'OSEmu.400',0
trackname	dc.b	'trackdisk.device',0
		even

patch
;		move.l	#$A8D398FB,D6		; skip protection

;		move.w	#$6002,$686B2		; skip DoIO input.device AddHandler

;		move.w	#$6002,$6FC14		; skip ReadPixel
;		move.w	#$6002,$6FC30		; skip WritePixel
;		move.w	#$6002,$6E9F8		; skip BltTemplate

		move.l	$4.w,$68E7C		; skip ptr to $FCD300
		move.l	$4.w,$790F2		; skip ptr to $FCD300

;.m	move.w	$DFF006,$DFF180
;	bra.b	.m

		jmp	(a3)

;--------------------------------

_resload	dc.l	0		;address of resident loader

;======================================================================

	END
