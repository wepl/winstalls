;*---------------------------------------------------------------------------
;  :Program.	xenon2.asm
;  :Contents.	Slave for "Xenon 2"
;  :Author.	Wepl
;  :Version.	$Id: xenon2.asm 1.4 1999/06/03 20:34:22 jah Exp jah $
;  :History.	31.03.97 initial
;		12.04.97 adaption from J.F.Fabre's Installer
;		20.12.98 work on CDTV version started
;		24.12.98 work on disk version started
;		25.12.98 disk version finished
;		07.01.98 support for second disk version started
;		03.06.99 support for third disk version added
;		17.06.00 highscores fixed
;		18.06.00 trainer fixed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

CDTV		;if defined Slave for CDTV version will be created

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD CDTV
	OUTPUT	"wart:x/xenon2 cdtv/Xenon2.Slave"
	ELSE
	OUTPUT	"wart:x/xenon2/Xenon2.Slave"
	ENDC
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	BOPT	w4-			;disable 64k warnings
	SUPER

	STRUCTURE	globals,$100
		LONG	RESLOAD

;======================================================================


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
	IFD CDTV
		dc.l	$c6000			;ws_BaseMemSize
	ELSE
		dc.l	$81000			;ws_BaseMemSize
	ENDC
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
	IFD CDTV
		dc.w	_data-_base		;ws_CurrentDir
	ELSE
		dc.w	0			;ws_CurrentDir
	ENDC
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

	IFND CDTV
_name		dc.b	"Xenon 2 - Megablast",0
_copy		dc.b	"1988 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"Version 1.5 Floppy "
		INCBIN	"T:date"
		dc.b	0
	ELSE
_data		dc.b	"data",0
_name		dc.b	"Xenon 2 - Megablast",0
_copy		dc.b	"1991 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"Version 1.4 CDTV "
		INCBIN	"T:date"
		dc.b	0
	ENDC
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(RESLOAD)
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = _custom

	;get tags
		lea	(_control),a0
		jsr	(resload_Control,a5)

	IFD CDTV

	;install keyboard quitter
		bsr	_SetupKeyboard
	;load exe
		lea	(_x2),a0
		lea	($400),a1
		move.l	a1,a4			;A4 = address
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	a4,a0
		sub.l	a1,a1
		jsr	(resload_Relocate,a5)

		lea	_px2,a0
		sub.l	a1,a1
		jsr	(resload_Patch,a5)

		move.l	#NTSC_MONITOR_ID,d0
		cmp.l	(_monitor),d0
		bne	.1
		move.w	#4,($12,a4)		;3=pal 4=ntsc
.1
		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$3c54c,_savehighs
.trained	lea	$3a296,a1
		move.l	#$4e714eb9,(a1)+
		move.l	a0,(a1)

		lea	(_highs),a0
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs),a0
		lea	$3c366-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	(_custom2),d0
		beq	.nolmb
		move.l	#$bfe001,$35092+4	;second fire button -> LMB
.nolmb
		lea	(_vbi),a0
		move.l	a0,($6c)
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,(intena,a6)
		move.w	#INTF_VERTB,(intreq,a6)

		jmp	(a4)

_vbi		move.w	#INTF_VERTB,(_custom+intreq)
		rte

_px2
	PL_START
	PL_S	$3aa4a,$3aae8-$3aa4a		;os stuff
	PL_S	$3ab2c,$3ab40-$3ab2c		;asking exec.VBlankFrequency
	PL_P	$4fd78,_load_sounds
	PL_P	$3c7de,_load_speech
	PL_P	$33930,_load_level
	PL_P	$3d86e,_load_intro
	PL_P	$411a8,_load_speech2
	PL_P	$50fce,_load_piccode
	PL_P	$50f68,_load_pics
	PL_P	$3e09a,_load_intro2
	PL_P	$3d2a4,_load_level2
	PL_P	$4fd28,_load_sounds2
	PL_R	$3a924				;cdtv.device stuff
	PL_R	$3a9ba				;cdtv.device stuff
	PL_P	$37a98,_32bit
	;PL_P	$410b2,$34fb2			;strange sound problem (does not help)
	PL_S	$3a742,12			;cash clear before each level
	PL_END

_load_sounds
_load_sounds2	lea	($88a48),a1		;186900 bytes

_load		move.l	d1,a0
		addq.l	#4,a0
		move.l	(RESLOAD),a2
		jmp	(resload_LoadFileDecrunch,a2)

_load_speech	move.l	($411e4),a1		;107800 bytes
		pea	($3c80c)
		bra	_load

_load_level	lea	($4e26),a1		;180000 bytes
		pea	($3395e)
		bra	_load

_load_intro	lea	($4e26),a1
		pea	($3d89c)
		bra	_load

_load_speech2	move.l	($411e4),a1		;107800 bytes
		pea	($411d6)
		bra	_load

_load_piccode	lea	($4e26),a1
		pea	($3d2ee)
		bra	_load

_load_pics	move.l	($4e42),a1
		pea	($50f96)
		bra	_load

_load_intro2	lea	($4e26),a1
		pea	($3e0c8)
		bra	_load

_load_level2	lea	($4e26),a1		;180000 bytes
		pea	($3d2d2)
		bra	_load

_savehighs	jsr	$3ca02			;original
		move.l	#$fc-$66+$28,d0
		lea	$3c366-$28,a0
		movem.l	d0/a0,-(a7)
		bsr	_crypt
		move.l	a0,a1
		lea	(_highs),a0
		move.l	(RESLOAD),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(a7)+,d0/a0

_crypt		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a0
		rts

_notrainer	move.w	#3,($cd0)		;ships
		move.l	#0,($ca0)		;cash
		rts

_gametrainer	move.w	#9,($cd0)		;ships
		move.l	#100000,($ca0)		;cash
		rts

_x2		dc.b	"x2",0
	EVEN

	INCLUDE	Sources:whdload/keyboard.s

;======================================================================

	ELSE
	
;======================================================================

	;enable cache
	;	move.l	#CACRF_EnableI,d0
	;	move.l	d0,d1
	;	jsr	(resload_SetCACR,a5)

	;bootblock
		move.l	#0,d0			;offset
		move.l	#$400,d1		;size
		moveq	#1,d2			;disk
		lea	$1000,a0		;address
		movem.l	d1/a0,-(a7)
		jsr	(resload_DiskLoad,a5)
		movem.l	(a7)+,d0/a0
		jsr	(resload_CRC16,a5)
		cmp.w	#$7f8f,d0
		beq	_v1
		cmp.w	#$7ea7,d0
		beq	_v3
		cmp.w	#$c0fb,d0
		bne	_wrongver

;============== version 2

_v2		patch	$10ac,_v2_1
		jmp	($1018)

_v2_1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)
		patch	$63f62,_v2_2
		jmp	$400

_v2_2		move.l	#$52*$1600,d0		;offset
		move.l	#$40000,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l  (RESLOAD),a5
		jsr	(resload_DiskLoad,a5)

		skip	$7058-$7046,$7046	;vector init
		patch	$47d8,_32bit
		patch	$9012,_load
		skip	8,$6f86			;cash clear before each level

		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$853c,_v2_savehighs
.trained	move.w	#$4eb9,$6bae
		move.l	a0,$6bae+2

		lea	(_highs),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs),a0
		lea	$8368-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$e841c3fc,d0
		move.l	d0,$2d10		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$2d42		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$2f8e		;access fault (lsr->asr,mulu->muls)
		move.l	d0,$34d6		;access fault (lsr->asr,mulu->muls)

		jmp	$400

_v2_savehighs	jsr	$86aa			;original
		move.l	#$fc-$66+$28,d0
		lea	$8368-$28,a0
		movem.l	d0/a0,-(a7)
		bsr	_crypt
		move.l	a0,a1
		lea	(_highs),a0
		move.l	(RESLOAD),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(a7)+,d0/a0
		bra	_crypt

;============== version 3

_v3		patch	$10a8,.1
		jmp	($1016)

.1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)

		lea	$64e52,a7		;$410
		move.l	#$7670CF6B,d0		;CopyLock
		rol.l	#8,d0			;$a1a
		eor.l	#$400,d0		;$a20
		ror.l	#8,d0			;$a22
		patch	$64bf2,.2
		jmp	$64bb6			;$a24

.2		patch	$63e,.3			;second copylock
		jmp	$400

.3		move.l	#$7670CF6B,d0		;CopyLock
		patch	$641d4,.4
		jmp	$b82

	;after intro
.4		move.l	#$70c00,d0		;offset
		move.l	#$3fc00,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		patch	$64276,_5
		jmp	$64252

;============== version 1

_v1		patch	$10b0,_1
		jmp	($1016)

_1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)

		lea	$64de4,a7		;$410
		move.l	#$7670CF6B,d0		;CopyLock
		rol.l	#8,d0			;$a1a
		eor.l	#$400,d0		;$a20
		ror.l	#8,d0			;$a22
		patch	$64b84,_2
		jmp	$64b48			;$a24

_2		patch	$63e,_3			;second copylock
		jmp	$400

_3		move.l	#$7670CF6B,d0		;CopyLock
		patch	$641d2,_4
		jmp	$b82

	;after intro
_4		move.l	#$70c00,d0		;offset
		move.l	#$3fc00,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		patch	$64260,_5
		jmp	$6423c

	;main loaded and decrypted
_5		move.l	#$4ef8763a,$70f6	;third copylock
		skip	$7654-$7642,$7642	;vector init
		patch	$47ce,_32bit
		patch	$921a,_load
		skip	8,$6f7c			;cash clear before each level

		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$8b1a,_savehighs
.trained	move.w	#$4eb9,$6ba4
		move.l	a0,$6ba4+2

		lea	(_highs),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs),a0
		lea	$8946-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$e841c3fc,$2f84	;access fault (lsr->asr,mulu->muls)

		move.l	#$7670CF6B,d0		;CopyLock
		jmp	$400

_savehighs	jsr	$8c88			;original
		move.l	#$fc-$66+$28,d0
		lea	$8946-$28,a0
		movem.l	d0/a0,-(a7)
		bsr	_crypt
		move.l	a0,a1
		lea	(_highs),a0
		move.l	(RESLOAD),a2
		jsr	(resload_SaveFile,a2)
		movem.l	(a7)+,d0/a0

;============== all versions

_crypt		movem.l	d0/a0,-(a7)
		subq.w	#1,d0
.lp		eor.b	d0,(a0)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a0
		rts

_notrainer	move.w	#3,($cca)		;ships
		move.l	#0,($c9a)		;cash
		rts

_gametrainer	move.w	#9,($cca)		;ships
		move.l	#100000,($c9a)		;cash
		rts

_load		mulu	#512,d0			;offset
		mulu	#512,d1			;size
		moveq	#2,d2			;disk
		move.l	a0,-(a7)
		add.l	d1,(a7)
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		move.l	(a7)+,a0
		moveq	#0,d0
		rts

	ENDC

;======================================================================

_32bit		move.l	a0,-(a7)
		exg.l	d1,a1
		and.l	#$00ffffff,d1
		exg.l	d1,a1
		jsr	(a1)
		move.l	(a7)+,a0
		rts

_wrongver	subq.l	#8,a7
		pea	TDREASON_WRONGVER
		bra	_end
_exit		subq.l	#8,a7
		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(RESLOAD),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_control	dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	TAG_DONE
_highs		dc.b	"highs",0

;======================================================================

	END

