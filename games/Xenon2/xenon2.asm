;*---------------------------------------------------------------------------
;  :Program.	xenon2.asm
;  :Contents.	Slave for "Xenon 2"
;  :Author.	Wepl
;  :Version.	$Id: xenon2.asm 1.7 2003/05/11 21:21:05 wepl Exp wepl $
;  :History.	31.03.97 initial
;		12.04.97 adaption from J.F.Fabre's Installer
;		20.12.98 work on CDTV version started
;		24.12.98 work on disk version started
;		25.12.98 disk version finished
;		07.01.98 support for second disk version started
;		03.06.99 support for third disk version added
;		17.06.00 highscores fixed
;		18.06.00 trainer fixed
;		16.08.00 crash on not entering highscores fixed
;		06.05.03 snoop bugs fixed
;		11.05.03 keyboard fixed
;		11.08.04 support for v4/v5 added, UAE fix
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

;CDTV		;if defined Slave for CDTV version will be created

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD CDTV
	OUTPUT	"wart:x-y/xenon2/Xenon2CDTV.Slave"
	ELSE
	OUTPUT	"wart:x-y/xenon2/Xenon2.Slave"
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
		dc.b	"Version 1.8 Floppy "
		INCBIN	"T:date"
		dc.b	0
	ELSE
_data		dc.b	"data",0
_name		dc.b	"Xenon 2 - Megablast",0
_copy		dc.b	"1991 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"Version 1.5 CDTV "
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
		patch	$3c54a,_savehighs
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

_savehighs	addq.l	#2,a7			;original
		jsr	$3ca02			;original
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
		cmp.w	#$7e53,d0
		beq	_v4
		cmp.w	#$bdce,d0
	;	cmp.w	#$e08d,d0		;without first std track in image
		beq	_v5
		cmp.w	#$c0fb,d0
		bne	_wrongver

;============== version 2

_v2		move.b	#-1,$1055		;snoop ciab.prb
		patch	$10ac,_v2_1
		jmp	($1018)

_v2_1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)
		patch	$63f62,_v2_2
		move.b	#-1,$44f		;snoop ciab.prb
		move.w	#$4200,$45e		;snoop custom.bplcon0
		patchs	$5f4,_keyboard
		move.l	#$636,_custom+cop1lc	;snoop copper dma before list
		jmp	$400

_v2_2		move.l	#$52*$1600,d0		;offset
		move.l	#$40000,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l  (RESLOAD),a5
		jsr	(resload_DiskLoad,a5)

		patchs	$fd4,_keyboard
		skip	$7058-$7046,$7046	;vector init
		move.b	#-1,$70ab		;snoop ciab.prb
		patch	$47d8,_32bit
		patch	$9012,_load
		skip	8,$6f86			;cash clear before each level

		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$853a,_v2_savehighs
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

_v2_savehighs	addq.l	#2,a7			;original
		jsr	$86aa			;original
		move.l	#$fc-$66+$28,d0
		lea	$8368-$28,a0
		bra	_savehighs

;============== version 3

_v3		move.b	#-1,$1051		;snoop ciab.prb
		patch	$10a8,.1
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
		skip	4,$64bc8		;prefetching problem on UAE
		patch	$64bf2,.2
		jmp	$64bb6			;$a24

.2		move.b	#-1,$467		;snoop ciab.prb
		move.w	#$4200,$476		;snoop custom.bplcon0
		patchs	$bc2,_keyboard
		move.l	#$c02,_custom+cop1lc	;snoop copper dma before list
		patch	$63e,.3			;second copylock
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
		patch	$64276,_v13_5
		jmp	$64252

;============== version 1

_v1		move.b	#-1,$104d		;snoop ciab.prb
		patch	$10b0,.1
		jmp	($1016)

.1		move.l	#$2c00,d0		;offset
		move.l	#$6b6c0,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		jsr	(resload_DiskLoad,a5)

		lea	$64de4,a7		;$410
		move.l	#$7670CF6B,d0		;CopyLock
		rol.l	#8,d0			;$a1a
		eor.l	#$400,d0		;$a20
		ror.l	#8,d0			;$a22
		skip	4,$64b5a		;prefetching problem on UAE
		patch	$64b84,.2
		jmp	$64b48			;$a24

.2		move.b	#-1,$467		;snoop ciab.prb
		move.w	#$4200,$476		;snoop custom.bplcon0
		patchs	$bc2,_keyboard
		move.l	#$c02,_custom+cop1lc	;snoop copper dma before list
		patch	$63e,.3			;second copylock
		jmp	$400

.3		move.l	#$7670CF6B,d0		;CopyLock
		patch	$641d2,.4
		jmp	$b82

	;after intro
.4		move.l	#$70c00,d0		;offset
		move.l	#$3fc00,d1		;size
		moveq	#1,d2			;disk
		lea	$400,a0			;address
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		patch	$64260,_v13_5
		jmp	$6423c

	;main loaded and decrypted
_v13_5		patchs	$fd4,_keyboard
		move.l	#$4ef8763a,$70f6	;third copylock
		skip	$7654-$7642,$7642	;vector init
		move.b	#-1,$76d1		;snoop ciab.prb
		move.w	#$4200,$76e0		;snoop custom.bplcon0
		patch	$47ce,_32bit
		patch	$921a,_load
		skip	8,$6f7c			;cash clear before each level

		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$8b18,_v13_savehighs
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
	;	move.l	#$5618,d1
		jmp	$400

_v13_savehighs	addq.l	#2,a7			;original
		jsr	$8c88			;original
		move.l	#$fc-$66+$28,d0
		lea	$8946-$28,a0
_savehighs	movem.l	d0/a0,-(a7)
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

;============== version 4

_v4		move.l	#$400,d0		;offset
		move.l	#$28400,d1		;size
		moveq	#1,d2			;disk
		lea	$14000,a0		;address
		jsr	(resload_DiskLoad,a5)

		pea	$14000+$281b6
		pea	_v4_load
		bra	_v45_2
		
;============== version 5

_v5		moveq	#12,d1			;offset
		move.w	#$2b9,d2		;size
		lea	$18000,a0		;address
		bsr	_v5_load1

		lea	$18006,a0
		lea	$400,a1
		jsr	(resload_Decrunch,a5)
		tst.l	d0
		beq	_wrongver
		
		lea	.pl1,a0
		lea	$400,a1
		jsr	(resload_Patch,a5)
		
		move.l	#$850,_custom+cop1lc	;snoop copper dma before list
		lea	$78000,a0
		move.w	#$7d00/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr
		waitvb

		jmp	$400

.pl1		PL_START
		PL_S	$52,$7e-$52		;aga stuff
		PL_B	$a7,-1			;snoop ciab.prb
		PL_W	$b6,$4200		;snoop custom.bplcon0
		PL_PS	$410,_keyboard
		PL_P	$63a3e,_v5_2
		PL_END

_v5_2		bsr	_v5_load1

	;load filetable
		move.l	#$400+$50a,d0		;offset
		move.l	#$16*4,d1		;size
		moveq	#1,d2			;disk
		lea	$380,a0			;address
		move.l	RESLOAD,a5
		jsr	(resload_DiskLoad,a5)

		pea	$400
		pea	_v5_load2
		
_v45_2		lea	$14006,a0
		lea	$400,a1
		jsr	(resload_Decrunch,a5)
		tst.l	d0
		beq	_wrongver
		
		lea	.pl,a0
		lea	$400,a1
		jsr	(resload_Patch,a5)
		
		lea	$400+$90e2,a0
		move.w	#$4ef9,(a0)+
		move.l	(a7)+,(a0)+
		
		lea	(_gametrainer),a0
		move.l	(_custom1),d0
		bne	.trained
		lea	(_notrainer),a0
		patch	$400+$85f2,_v45_savehighs
.trained	move.l	#$4e714eb9,$400+$6a34
		move.l	a0,$400+$6a34+4

		lea	(_highs),a0
		move.l	(RESLOAD),a5
		jsr	(resload_GetFileSize,a5)
		cmp.l	#$fc-$66+$28,d0
		bne	.nohighs
		lea	(_highs),a0
		lea	$400+$840e-$28,a1
		pea	(a1)
		jsr	(resload_LoadFileDecrunch,a5)
		move.l	(a7)+,a0
		bsr	_crypt
.nohighs
		move.l	#$400+$c0e,_custom+cop1lc	;snoop copper dma before list

		rts

.pl		PL_START
		PL_PS	$ba6,_keyboard
		PL_L	$2714,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2744,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$298e,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_L	$2f12,$e841c3fc		;access fault (lsr->asr,mulu->muls)
		PL_P	$431a,_32bit
		PL_S	$6eae,12		;cash clear before each level
		PL_S	$6f8c,$6fa2-$6f8c	;vector init
		PL_B	$7029,-1		;snoop ciab.prb
		PL_P	$957a,_decrunch
		PL_END

_v45_savehighs	addq.l	#2,a7			;original
		jsr	$400+$8760		;original
		move.l	#$fc-$66+$28,d0
		lea	$400+$840e-$28,a0
		bra	_savehighs

_decrunch	movem.l	d0-d1/a0-a2,-(a7)
		move.l	RESLOAD,a2
		jsr	(resload_Decrunch,a2)
		tst.l	d0
		beq	_wrongver
		movem.l	(a7)+,_MOVEMREGS
		rts

;============== all versions

_notrainer	move.w	#3,($cca)		;ships
		move.l	#0,($c9a)		;cash
		rts

_gametrainer	move.w	#9,($cca)		;ships
		move.l	#100000,($c9a)		;cash
		rts

_v5_load1	move.l	d1,d0
		move.l	d2,d1
_v5_load2	sub.w	#1,d0			;first track only $1600
_v4_load	moveq	#1,d2			;disk
		bra	_load0
_load		moveq	#2,d2			;disk
_load0		mulu	#512,d0			;offset
		mulu	#512,d1			;size
		move.l	a0,-(a7)
		add.l	d1,(a7)
		move.l	(RESLOAD),a2
		jsr	(resload_DiskLoad,a2)
		move.l	(a7)+,a0
		moveq	#0,d0
		rts

	ENDC

;======================================================================

_keyboard	move.l	d1,-(a7)
		moveq	#3-1,d1
.wait1		move.b	(_custom+vhposr),d0
.wait2		cmp.b	(_custom+vhposr),d0
		beq	.wait2
		dbf	d1,.wait1
		move.l	(a7)+,d1
		rts

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

