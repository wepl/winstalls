;*---------------------------------------------------------------------------
;  :Program.	xenon2.asm
;  :Contents.	Slave for "Xenon 2"
;  :Author.	WEPL
;  :Version.	$Id$
;  :History.	31.03.97 initial
;		12.04.97 adaption from J.F.Fabre's Installer
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i

	OUTPUT	wart:xenon2/xenon2.slave
	BOPT	O+ OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	SUPER

CopyLockId = $7670CF6B

;======================================================================

.base		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	2		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError	;ws_flags
		dc.l	$80000		;ws_BaseMemSize
		dc.l	$100		;ws_ExecInstall
		dc.w	.Start-.base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache

;======================================================================
.Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)

	;cache
	;	move.l	#CACRF_EnableI,d0
	;	move.l	d0,d1
	;	jsr	(resload_SetCACR,a0)
	
	;bootblock
	IFEQ 1
		move.l	#0,d0		;offset
		move.l	#$400,d1	;size
		moveq	#1,d2		;disk
		lea	$1000,a0	;address
		lea	(12,a0),a5
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		ill	$fe(a5)
		jmp	(a5)
	ENDC

	;JFFabre adaption start ==========================
	;load main
		move.l	#$2c00,d0	;offset
		move.l	#$6ca00,d1	;size
		moveq	#1,d2		;disk
		lea	$400,a0		;address
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
	;check version
		lea	_version,a0
		move.w	#2,(a0)
		cmp.l	#$4FF90000,$404
		beq	.verok
		cmp.l	#$41FAFFFA,$404
		bne	_exit		;unknown version
		move.w	#1,(a0)
	;uniform 2 different versions
		move.l	#$4e526000,$2C14-$2c00+$400
		move.l	#$4bb619cf,$3228-$2c00+$400
		lea	_xenbin,a0
		lea	_xenbin_end,a1
		lea	$66fc8-$2c00+$400,a2
.vercp		move.b	(a0)+,(a2)+
		cmp.l	a0,a1
		bne	.vercp
.verok
	;prepare intro
		move.w	_version,d0
		cmp.w	#2,d0
		beq	.pi_1
		patch	$4d6,_v1	;version 1
		jmp	$400
.pi_1		patchs	$5e6,_v2_kbint1	;version 2
		patch	$63f62,_v2
		jmp	$400

	;version 1 ---------------------------------------
_v1		patchs	$64bc6,_v1_a5init
		move.w	#$4ed5,$64bf6		;jmp (a5)
		move.l	#CopyLockId,D0
	illegal
		jmp	$a1a

_v1_a5init	lea	_v1_load,a5
		moveq	#2,d1
		rts

	;after intro
_v1_load	MOVE.L	#$203C7670,$063E.W	;copylock
		MOVE.L	#$CF6B6000,$0642.W	;
		MOVE.W	#$053C,$0646.W		;
		patch	$641d8,_v1_loadgame
		patch	$64276,_v1_load2
		patchs	$bb4,_v1_kbint1
		jmp	$400

_v1_loadgame	movem.l	d0-d2/a0-a2,-(a7)
		move.l	#$70c00,d0	;offset
		move.l	#$3fc00,d1	;size
		moveq	#1,d2		;disk
		lea	$400,a0		;address
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		movem.l	(a7)+,d0-d2/a0-a2
		lea	$bfd000,a4
		move.l	#$400,$24
		jmp	$6424e
		
	;after whole game loaded
_v1_load2	patch	$70f6,_v1_cl2		;copylock
		patchs	$47ce,_32bit		;24 bit jmp
		patch	$921a,_readdisk2
	;orginal
		pea	$64252
		move.w	(a7),-(a7)
		eor.w	#$e552,(a7)
		rte

_v1_cl2		patchs	$ffc,_v1_kbint2
		move.w	#$4e71,$fd2
		move.l	#CopyLockId,d0
		jmp	$763a

_v1_kbint1	move.b	d0,$bdc
_v1_kbint2	cmp.b	#$59,d0		;F10
		beq	_exit
		cmp.b	#$58,d0		;F9
		beq	_debug
		cmp.b	#$5f,d0		;HELP
		bne	.1
		move.l	a0,-(a7)
		lea	_version,a0
		cmp.w	#1,(a0)
		bne	.11
		move.l	$c9a,a0
		add.l	a0,a0
		move.l	a0,$c9a
.11		move.l	(a7)+,a0
.1		bset	#6,$bfee01
		rts

_v2_kbint1	move.b	d0,$60e
		bra	_v1_kbint2

	;version 2 ---------------------------------------
_v2		move.l	#$70c00,d0	;offset
		move.l	#$3fc00,d1	;size
		moveq	#1,d2		;disk
		lea	$400,a0		;address
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		
		patchs	$47d8,_32bit
		patchs	$ffc,_v1_kbint2
		move.w	#$4e71,$fd2
		patch	$9012,_readdisk2
		
		jmp	$400

	;all versions ------------------------------------

_32bit		move.l	a0,-(a7)
		move.l	d5,-(a7)
		move.l	a1,d5
		and.l	#$00ffffff,d5
		move.l	d5,a1
		move.l	(a7)+,d5
		jsr	(a1)
		move.l	(a7)+,a0
		rts

_readdisk2	movem.l	d2/a1-a2,-(a7)
		mulu	#512,d0		;offset
		mulu	#512,d1		;size
		moveq	#2,d2		;disk
		move.l	a0,-(a7)
		add.l	d1,(a7)
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		move.l	(a7)+,a0
		movem.l	(a7)+,d2/a1-a2
		moveq	#0,d0
		rts

;======================================================================
		
	IFEQ 1
		
		move.l	#$2c00,d0	;offset
		move.l	#$6ce00-$2c00,d1	;size
		moveq	#1,d2		;disk
		lea	$400,a0		;address
		move.l	a0,a5
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)
		
		move.l	#CopyLockId,d0

		patch	$16(a5),$61a(a5)
	patch	$16(a5),_debug
		jmp	(a5)
		
		lea	$64de4,a7
		move.l	d0,$24
		ill	$64b8e+$3c
		jmp	($61a,a5)
		
	ENDC

;======================================================================

_resload	dc.l	0	;address of resident loader
_version	dc.w	0	;version of xenon-2

;--------------------------------

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_xenbin		INCBIN	"slaves/xen66fc8.bin"
_xenbin_end

;======================================================================

	END
