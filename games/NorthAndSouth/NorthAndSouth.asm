;---------------------------------------------------------------------------
;  :Program.	North&South.asm
;  :Contents.	Slave for "North & South" from Infogrames
;  :Author.	Mr.Larmer of Wanted Team, Wepl
;  :Original
;  :History.	17.02.01 Wepl adjusted
;		02.06.03 Wepl minor changes
;		?	   other devs were too lazy to add sth to the history
;		2025-03-15 imported to repo
;		2025-03-17 cleanup, use v19/resload_ReadJoyPort, use some ExpMem
;		2025-03-17 code simplified
;		2025-03-27 more code simplified
;		2025-03-30 joypad handling fixed/rewritten
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"NorthAndSouth.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

	STRUCTURE globals,$100
	LONG	gl_joy0
	BYTE	gl_files

;============================================================================

CHIPMEMSIZE	= $79000
FASTMEMSIZE	= $7000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN			;set all initial colors to black
BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
;HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 19
slv_Flags	= WHDLF_NoError
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_name	dc.b	"North & South",0
slv_copy	dc.b	"1989 Infogrames",0
slv_info	dc.b	"adapted by Wepl, CFou!, Mr.Larmer & JOTD",-1
		dc.b	"Use 2nd joystick button / CD32 pad blue to switch units",10
		dc.b	"Use CD32 pad FWD+BWD to retreat",-1
		dc.b	"Version 2.2 "
		INCBIN	.date
		dc.b	0
slv_CurrentDir	dc.b	"data",0
slv_config	DC.B	"C1:B:Force Joystick/CD32Pad instead Mouse"
                dc.b    0
_Boot2Name	dc.b	'boot2.bin',0
_nsname		db	"ns.am2",0
	even

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available
; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock
	
	;check for files instead diskimage
		lea	_nsname,a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		sne	gl_files

.versionTest

	;check version
		move.l	#$2A4,d0
		lea	12(a4),a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)

		cmp.w	#$8E19,D0	V1&V3	; multilanguage version
		beq	.verok
		cmp.w	#$4A39,D0	V2 NTSC	; english version (hidden bootblock)
		beq	.USversion
.not_support	pea	TDREASON_WRONGVER
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.USversion	tst.b	gl_files
		bne	.filesversionUS

		move.l	a4,a0
		move.l	#$DBC00,D0
		move.l	#$400,d1	; SKIP TRACK PROTECT
		move.l	#1,d2		; RUN GOOD HIDDEN BOOTBLOCK
		jsr	(resload_DiskLoad,a2)
		BRA	.versionTest

.filesversionUS
		lea	_Boot2Name(pc),a0
		move.l	a4,a1
		jsr	(resload_LoadFile,a2)
		BRA	.versionTest

.verok		tst.b	gl_files
		beq	.boot
		patch2	$298(A4),_LoadFilePart200	; PATCH DOIT FUNCTION FOR TRACKDISKDEVICE

	;call bootblock
.boot		pea	.patch(pc)
		lea	($2c,a5),a1
		jmp	(12,a4)				; ns.am2 is loaded/relocated from bootblock
.patch
		pea	(a0)

		lea	pl_version_1,a3
		lea	pl_version_1f,a4
		cmp.l	#$4883b67c,$7FFE(A0)		;V1 multilanguage
		beq	.go

		lea	pl_version_2,a3
		lea	pl_version_2f,a4
		cmp.l	#$61A64A40,$7EFe(A0)		;V2 English NTSC
		beq	.go

		lea	pl_version_3,a3
		lea	pl_version_3f,a4
		cmp.l	#$61A64A40,$7F4a(A0)		;V3 multilanguage
		bne	.not_support

.go		move.l	a0,a1
		move.l	_resload(pc),a2
		move.l	a3,a0
		tst.b	gl_files
		beq	.nofiles
		move.l	a4,a0
.nofiles	jmp	resload_Patch(a2)


pl_version_1f	PL_START
		PL_P	$13B62,_LoadFilePart200Game	; Patch TrackDisk access to load files
		PL_NEXT	pl_version_1

pl_version_1	PL_START
		PL_PSS	$7d74,keyboard_single,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$8006,$7001			; skip protection
		PL_PSS	$f350,keyboard_multi,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_IFC1
		PL_PS	$7de6,_inject_single
		PL_DATA	$7E1C,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_PSS	$f350,keyboard_multi_port0,4	; menu keyboard read: joypad FWD+BWD = ESC
		PL_PS	$f3ba,_inject_multi
		PL_DATA	$f406,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_ENDIF
		PL_END

pl_version_2f	PL_START
		PL_P	$139d8,_LoadFilePart200Game	; Patch TrackDisk access to load files
		PL_NEXT	pl_version_2

pl_version_2	PL_START
		PL_B	$9b6,$60			; Skip NTSC test, freezed on title screen
		PL_PSS	$7C6C,keyboard_single,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$7F4a,$7001			; skip protection
		PL_PSS	$f248,keyboard_multi,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_PS	$119A2,_Crack			; crack disk protection
		PL_IFC1
		PL_PS	$7cde,_inject_single
		PL_DATA	$7d14,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_PSS	$f248,keyboard_multi_port0,4	; menu keyboard read: joypad FWD+BWD = ESC
		PL_PS	$f2b2,_inject_multi
		PL_DATA	$f2fe,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_ENDIF
		PL_END

pl_version_3f	PL_START
		PL_P	$13B24,_LoadFilePart200Game	; Patch TrackDisk access to load files
		PL_NEXT	pl_version_3

pl_version_3	PL_START
		PL_PSS	$7CB8,keyboard_single,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$7F4a,$7001			; skip protection
		PL_PSS	$f25a,keyboard_multi,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_IFC1
		PL_PS	$7d2a,_inject_single
		PL_DATA	$7d60,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_PSS	$f25a,keyboard_multi_port0,4	; menu keyboard read: joypad FWD+BWD = ESC
		PL_PS	$f2c4,_inject_multi
		PL_DATA	$f310,6				; remove mouse read
			moveq	#0,d0
			nop
			nop
		PL_ENDIF
		PL_END

; single player mode
; always active except in action sequences (combat, train, capture) in two player mode

keyboard_single
		moveq	#1,d0
		move.l	_resload,a0
		jsr	(resload_ReadJoyPort,a0)

		btst	#RJPB_FORWARD,d0
		beq	.nor1
		btst	#RJPB_REVERSE,d0
		beq	.nor1
		moveq	#$45,d0				; escape
		rts
.nor1
		btst	#RJPB_BLUE,d0
		beq	.noblue1
		moveq	#$61,d0				; right shift
		rts
.noblue1
		MOVE.B	$bfec01,D0			; normal keyboard check
		ROR.B	#$01,D0
		NOT.B	D0
		rts

_inject_single	eor.b	#CIAF_GAMEPORT1,d0		; original
		or.b	d0,d1				; original
		move.l	d1,-(a7)
		moveq	#0,d0
		move.l	_resload,a0
		jsr	(resload_ReadJoyPort,a0)
		move.l	(a7)+,d1
		btst	#RJPB_RED,d0
		beq	.nofire
		bset	#7,d1
.nofire		btst	#RJPB_RIGHT,d0
		beq	.noright
		bset	#3,d1
.noright	btst	#RJPB_LEFT,d0
		beq	.noleft
		bset	#2,d1
.noleft		btst	#RJPB_DOWN,d0
		beq	.nodown
		bset	#1,d1
.nodown		btst	#RJPB_UP,d0
		beq	.noup
		bset	#0,d1
.noup		rts

; multiplayer mode
; only active in action sequences (combat, train, capture) in two player mode

keyboard_multi_port0
		moveq	#0,d0
		move.l	_resload,a0
		jsr	(resload_ReadJoyPort,a0)
		move.l	d0,gl_joy0

		btst	#RJPB_FORWARD,d0
		beq	.nor0
		btst	#RJPB_REVERSE,d0
		beq	.nor0
		moveq	#$41,d0				; backspace
		bra	.port1
.nor0
		btst	#RJPB_BLUE,d0
		beq	.port1
		moveq	#$61,d0				; right shift
.port1

keyboard_multi
		moveq	#1,d0
		move.l	_resload,a0
		jsr	(resload_ReadJoyPort,a0)

		btst	#RJPB_FORWARD,d0
		beq	.nor1
		btst	#RJPB_REVERSE,d0
		beq	.nor1
		moveq	#$45,d0				; escape
		rts
.nor1
		btst	#RJPB_BLUE,d0
		beq	.noblue1
		moveq	#$60,d0				; left shift
		rts
.noblue1
		MOVE.B	$bfec01,D0
		ROR.B	#$01,D0
		NOT.B	D0
		rts

; d0=rawkey d4=port0result

_inject_multi
		move.l	gl_joy0,d1
		moveq	#0,d4				; overwrite keyboard result, otherwise stick bits gets never released
		btst	#RJPB_RED,d1
		beq	.nofire
		bset	#7,d4
.nofire		btst	#RJPB_RIGHT,d1
		beq	.noright
		bset	#3,d4
.noright	btst	#RJPB_LEFT,d1
		beq	.noleft
		bset	#2,d4
.noleft		btst	#RJPB_DOWN,d1
		beq	.nodown
		bset	#1,d4
.nodown		btst	#RJPB_UP,d1
		beq	.noup
		bset	#0,d4
.noup
		move.l	(a7),a0				; return pc
		move	(-8,a0),d1			; d16 result port0
		move.b	d4,(a4,d1.w)			; save result port0
		tst.b	d0				; original
		bpl	.nokeyup			; original
		moveq	#0,d0				; original
.nokeyup	rts

;----------------------------
_Crack
	move.w	#$32E0,d6
	rts
;---------------------------
_LoadFilePart200Game
	movem.l	D3-D4/a3-a4,-(a7)
	lea	_GameName(pc),a4
	move.l	(A3),(a4)	; take name of file
	move.l	4(A3),4(a4)	; take name of file
	move.l	8(A3),8(a4)	; take name
	move.l	a1,a3		; TRackDiskDEvice struct

	move.l	_GameName(pc),D4
	move.l	_GameNamePrec(pc),D3
	cmp.l	d3,D4
	beq	.ok
	bsr	_ResetFileinfo
.ok
	bsr	_LoadFilePart200
	movem.l	(a7)+,d3-D4/a3-A4
	rts

_LoadFilePart200
	move.l	4,a6
	movem.l	d0-a6,-(a7)
	cmp.w	#$c,$1C(a1)
	beq	.skip
	cmp.w	#$9,$1C(a1)
	beq	.skip
	cmp.L	#$0,$24(a1)
	beq	.skip
	cmp.L	#$1600,$2C(a1)	; no data on track 1
	beq	.skip
	
	move.l	$24(a1),d0	; LG
	move.l	$2C(a1),d1	; OFFSET
	move.l	$28(a1),a1	; dest

	lea	_GameName(pc),a0
	cmp.l	#$400,d1	; DiR
	bne	.pasdir

	lea	_DirectoryAdr(pc),a0
	move.l	a1,(a0)			; save directory adress
	exg.l	d0,d1			; offset <> length
	moveq	#1,d2			; disk number
	move.l	a1,a0			; destination
	move.l	_resload,a2
	jsr	(resload_DiskLoad,a2)
	bsr	_TakeFirstFileInfo
.skip	movem.l	(a7)+,d0-a6
	rts
;//////////////////////
.pasdir

	bsr	_TakeFileInfo	

	move.l	_FileLengthAdr(pc),d2
	sub.l	_FileOffsetAdr(pc),d1	; start offset
	move.l	d1,d3
	add.l	#$200,d3
	cmp.l	D3,D2
	bHS	.cont
	; end of file
	DIVU	#$200,D2
	SWAP.W D2
	AND.L	#$fff,D2
	MOVE.L	D2,D0
	bsr	_LoadFileOffset
	bsr	_ResetFileinfo
	LEA	_GameNamePrec(PC),a0
	move.l	_GameName(pc),(a0)
	movem.l	(a7)+,d0-a6
	rts	
;//////////////////////
.cont	bsr	_LoadFileOffset
	LEA	_GameNamePrec(PC),a0
	move.l	_GameName(pc),(a0)
	movem.l	(a7)+,d0-a6
	rts	
;//////////////////////
_ResetFileinfo
	movem.l d0-D2/a0-A2,-(a7)
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	clr.l	(a4)
	clr.l	4(a4)
	clr.l	8(a4)
	clr.l	(a1)
	clr.l	(a2)
	movem.l (a7)+,d0-D2/a0-A2
	rts
_TakeFirstFileInfo
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	move.l	(a4),d0	
	tst.l	d0
	bne	.nom
	; take FIRST NAME & file info: 'ns.am2'
	move.l	(A0),(a4)	; take name of file
	move.l	4(A0),4(a4)	; take name of file
	move.l	8(A0),8(a4)	; take name
	MOVE.L	$C(A0),(A1)	; start offset of file
	MOVE.L	$10(A0),(A2)	; length file
.nom	rts

_TakeFileInfo
	movem.l d0-D2/a0-A2,-(a7)
	move.l	_DirectoryAdr(pc),a0
	lea	_GameName(pc),a4
	lea	_FileOffsetAdr(pc),a1
	lea	_FileLengthAdr(pc),a2
	move.l	(a2),d0	
	tst.l	d0
	bne	.nom
	; take NAME & info of file
	move.l	#$200/$14-1,d2
.nextfile
	move.l	$C(a0),D0
	tst.l	d0
	beq	.endofdir
	cmp.l	d1,d0			; start offset?
	beq	.found
	lea	$14(A0),a0		; next file info
	dbf	d2,.nextfile
.endofdir
.error move.w	#$F00,$DFF180
	bra	.error
.found
	move.l	(A0),(a4)	; take name of file
	move.l	4(A0),4(a4)	; take name of file
	move.l	8(A0),8(a4)	; take name
	MOVE.L	$C(A0),(A1)	; start offset of file
	MOVE.L	$10(A0),(A2)	; length file
.nom	movem.l (a7)+,d0-D2/a0-A2
	rts

;--------------------------------
_LoadFileOffset	movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFileOffset(a2)
		movem.l	(a7)+,d1/a0-a2
		rts

;============================================================================

_GameName	dx.l	4		; leave it!!!! name buffer =>if not crash
_GameNamePrec	dx.l	1
_FileOffsetAdr	dx.l	1
_FileLengthAdr	dx.l	1
_DirectoryAdr	dx.l	1

;============================================================================

	END

