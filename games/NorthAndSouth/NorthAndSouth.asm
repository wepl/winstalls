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

	STRUCTURE globals,0
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
slv_config	DC.B	"C1:B:Forces Joystick or CD32Pad for PL2 (mouse port)"
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
	
	;get tags
		lea	(_tag,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_Control,a2)

	;check for files instead diskimage
		lea	_nsname,a0
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
		PL_PSS	$7d74,keyboard_read,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$8006,$7001			; skip protection
		PL_PS	$8350,_TakePL1JOY1		; Patch PL1 Take JoyOption
		PL_PS	$8358,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_PS	$8364,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_L	$B4dE,$76011943			; remove swap control PORT, moveq #0,d3 + move.b ea,d3 -> moveq #1,d3 + move.b d3,ea
		PL_PS	$B5Ba,_TakeSpecialKeyPL1	; Patch Take Special Keys
		PL_PS	$B76a,_TakeSpecialKeyPL2	; Patch Take Special Keys

		PL_IFC1
		PL_W	$7E1C,$7000			; remove mouse read
		PL_NOP	$7E1E,4
		PL_PS	$7DBC,joysticks_menu_read	; double joystick read
		PL_ELSE
		PL_PS	$7DBC,joysticks_menu_read_mouse
		PL_ENDIF

		PL_END

pl_version_2f	PL_START
		PL_P	$139d8,_LoadFilePart200Game	; Patch TrackDisk access to load files
		PL_NEXT	pl_version_2

pl_version_2	PL_START
		PL_B	$9b6,$60			; Skip NTSC test, freezed on title screen
		PL_PSS	$7C6C,keyboard_read,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$7F4a,$7001			; skip protection
		PL_PS	$8248,_TakePL1JOY1		; Patch PL1 Take JoyOption
		PL_PS	$8250,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_PS	$825c,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_L	$b3d6,$76011943			; remove swap control PORT, moveq #0,d3 + move.b ea,d3 -> moveq #1,d3 + move.b d3,ea
		PL_PS	$B4b2,_TakeSpecialKeyPL1	; Patch Take Special Keys
		PL_PS	$B662,_TakeSpecialKeyPL2	; Patch Take Special Keys
		PL_PS	$119A2,_Crack			; crack disk protection

		PL_IFC1
		PL_W	$7D14,$7000			; remove mouse read
		PL_NOP	$7D16,4
		PL_PS	$7CB4,joysticks_menu_read	; double joystick read
		PL_ELSE
		PL_PS	$7CB4,joysticks_menu_read_mouse
		PL_ENDIF

		PL_END

pl_version_3f	PL_START
		PL_P	$13B24,_LoadFilePart200Game	; Patch TrackDisk access to load files
		PL_NEXT	pl_version_3

pl_version_3	PL_START
		PL_PSS	$7CB8,keyboard_read,4		; menu keyboard read: joypad FWD+BWD = ESC
		PL_W	$7F4a,$7001			; skip protection
		PL_PS	$8290,_TakePL1JOY1		; Patch PL1 Take JoyOption
		PL_PS	$8298,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_PS	$82a4,_TakePL2JOY0		; Patch PL2 Take JoyOption
		PL_L	$B3f0,$76011943			; remove swap control PORT, moveq #0,d3 + move.b ea,d3 -> moveq #1,d3 + move.b d3,ea
		PL_PS	$B4d0,_TakeSpecialKeyPL1	; Patch Take Special Keys
		PL_PS	$B684,_TakeSpecialKeyPL2	; Patch Take Special Keys

		PL_IFC1
		PL_W	$7D60,$7000			; remove mouse read
		PL_NOP	$7D62,4
		PL_PS	$7D00,joysticks_menu_read	; double joystick read
		PL_ELSE
		PL_PS	$7D00,joysticks_menu_read_mouse
		PL_ENDIF

		PL_END

keyboard_read
	move.l	joy0(pc),d0
	btst	#RJPB_FORWARD,d0
	beq.b	.j1
	btst	#RJPB_REVERSE,d0
	beq.b	.j1
	bra.b	.esc
.j1
	move.l	joy1(pc),d0
	btst	#RJPB_FORWARD,d0
	beq.b	.kb
	btst	#RJPB_REVERSE,d0
	beq.b	.kb
.esc
	move.b	#$45,d0
	bra.b	.out
.kb
	MOVE.B $00bfec01,D0
	ROR.B #$01,D0
	NOT.B D0
.out	rts
	
joysticks_menu_read_mouse
	bsr	_joystick
	lea	$DFF00C,A0
	RTS

joysticks_menu_read
	movem.l	d0-d2,-(a7)
	move.l	$DFF00A,d2	; save value
	bsr	_joystick
	move.l	joy1(pc),d0
	bne.b	.joy1_move
	; check if all directions neutral. If all neutral, check 2nd joystick
	swap	d2
.joy1_move
	lea	.joybuff(pc),a0
	move.w	d2,(a0)
	movem.l	(a7)+,d0-d2
	rts
	
.joybuff
	dc.w	0
	
;---------------------------
;===============V1
;---------------------------
;---------------------------
_TestJoy0Gen
	move.l	joy1(pc),d0
		btst	#RJPB_BLUE,d0	; fix second button winuae
		bne	.noSB
	btst	#RJPB_RED,d0
	beq	.noSB
	bset	#7,d3			; fire
.noSB	rTs
;---------------------------
;---------------------------
_TestJoy1Gen
	move.l	joy0(pc),d0
	tst.b	d1			; 2PL mode=>0? 1PL mode=>2
	beq	.2PLmode
	move.l	joy1(pc),d0
.2PLmode	

	move.l	_mouse_as_joy(pc),d1
;;	btst	#1,d1			; CD32 PAD FOR PLAYER 2 MOUSE PORT
	BEQ	.noCD32PAD	
	; JOTD: up & down were reversed
	btst	#RJPB_DOWN,d0
	beq	.noU
	bset	#1,d3			; UP
.noU	btst	#RJPB_UP,d0
	beq	.noD
	bset	#0,d3			; DOWN
.noD	btst	#RJPB_LEFT,d0
	beq	.noL
	bset	#2,d3			; LEFT
.noL	btst	#RJPB_RIGHT,d0
	beq	.noR
	bset	#3,d3			; RIGHT
.noR
.noCD32PAD
		btst	#RJPB_BLUE,d0	; fix second button winuae
		bne	.noSB
	btst	#RJPB_RED,d0
	beq	.noSB
	bset	#7,d3			; fire
.noSB
	rts
;---------------------------
;---------------------------
_TakePL1JOY1
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41D3(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41D3(a4)

	move.B	-$41D3(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right
	move.l	(a7)+,d0
	rts

;---------------------------
_TakePL2JOY0
	bsr	_CD32_Read
	movem.l	d0-d1,-(a7)

	move.B	-$7460(A4),d1		; 1PL MODe =>$02
	move.b	-$41D4(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41D4(a4)

	movem.l	(a7)+,d0-D1
	move.B	-$41D4(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	rts
	

ROK_MACRO:MACRO
rest_of_keys_\1_\2
	btst	#RJPB_REVERSE,d3
	beq	.no_retreat
	btst	#RJPB_FORWARD,d3
	beq	.no_retreat
	move.b	#$\2,-$\1(a4)		; RShift
.no_retreat
	rts
	ENDM
	
	; player 1
	ROK_MACRO	41DC,45
	ROK_MACRO	41E8,45
	ROK_MACRO	41DE,45
	; player 2
	ROK_MACRO	41DC,41
	ROK_MACRO	41E8,41
	ROK_MACRO	41DE,41
	
;---------------------------
_TakeSpecialKeyPL1
;	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	D4,-$41DC(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DC_45
	move.b	-$41DC(a4),d3		; $61=RShift | $45=Esc $60= Left
	ext.W	d3
	rts
;---------------------------
_TakeSpecialKeyPL2
;	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	#$61,-$41DC(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DC_41

	move.b	-$41DC(a4),d3		; $61=RShift | $45=Esc $60= Left
	ext.W	d3
	rts
;---------------------------

	
;==============V2
_TakePL1JOY1_V2
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41DF(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41DF(a4)
.noSB	
	move.B	-$41DF(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right

	move.l	(a7)+,d0
	rts
;---------------------------
_TakePL2JOY0_V2
	bsr	_CD32_Read
	movem.l	d0-d1,-(a7)
	move.B	-$746C(A4),d1		; 1PL MODe =>$02
	move.b	-$41E0(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41E0(a4)
	move.B	-$41E0(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	movem.l	(a7)+,d0-D1
	rts
;---------------------------
_TakeSpecialKeyPL1_V2
	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	D4,-$41E8(a4)		; LShift
.noSB
	bsr	rest_of_keys_41E8_45
	move.b	-$41E8(a4),d3
	ext.W	d3			; $60=LShift | $45=Esc
	rts
;---------------------------
_TakeSpecialKeyPL2_V2
	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	#$61,-$41E8(a4)		; RShift
.noSB
	bsr	rest_of_keys_41E8_41
	move.b	-$41E8(a4),d3		; $61=RShift | $45=Esc
	ext.W	d3
	rts
;---------------------------


;==============V3
_TakePL1JOY1_V3
	bsr	_CD32_Read
	move.l	d0,-(a7)

	move.b	-$41D5(a4),d3
	bsr	_TestJoy0Gen
	move.b	D3,-$41D5(a4)
.noSB
	move.B	-$41D5(A4),-2(A5)	; $8x=Fire | $01=Sown | $02=Up | $04=Left | $08= Right

	move.l	(a7)+,d0
	rts
;---------------------------
_TakePL2JOY0_V3
	bsr	_CD32_Read

	movem.l	d0-d1,-(a7)
	move.B	-$7460(A4),d1		; 1PL MODe =>$02
	move.b	-$41D6(a4),d3
	bsr	_TestJoy1Gen
	move.b	D3,-$41D6(a4)
	movem.l	(a7)+,d0-D1

	move.B	-$41D6(A4),-2(A5)	; $8x=Fire | $01=Down | $02=Up | $04=Left | $08= Right
	rts
;---------------------------
_TakeSpecialKeyPL1_V3
	bsr	_CD32_Read
	move.l	joy1(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	D4,-$41DE(a4)		; LShift
.noSB
	bsr	rest_of_keys_41DE_45
	move.b	-$41DE(a4),d3
	ext.W	d3			; $60=LShift | $45=Esc
	rts
;---------------------------
_TakeSpecialKeyPL2_V3
	bsr	_CD32_Read
	move.l	joy0(pc),d3
	btst	#RJPB_BLUE,d3
	beq	.noSB
	move.b	#$61,-$41DE(a4)		; RShift
.noSB
	bsr	rest_of_keys_41DE_41
	move.b	-$41DE(a4),d3		; $61=RShift | $45=Esc
	ext.W	d3
	rts
;---------------------------

_CD32_Read	move.l	d0,-(A7)
		bsr	_joystick
		move.l	(a7)+,d0
		rts
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

_joystick	movem.l	d0-d1/a0-a2,-(a7)
		moveq	#0,d0
		move.l	_resload,a2
		jsr	(resload_ReadJoyPort,a2)
		lea	joy0,a0
		move.l	d0,(a0)
		moveq	#1,d0
		move.l	_resload,a2
		jsr	(resload_ReadJoyPort,a2)
		lea	joy1,a0
		move.l	d0,(a0)
		movem.l	(a7)+,_MOVEMREGS
		rts

;============================================================================

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_mouse_as_joy	dx.l	2
_GameName	dx.l	4		; leave it!!!! name buffer =>if not crash
_GameNamePrec	dx.l	1
joy0		dx.l	1
joy1		dx.l	1
_FileOffsetAdr	dx.l	1
_FileLengthAdr	dx.l	1
_DirectoryAdr	dx.l	1

;============================================================================

	END

