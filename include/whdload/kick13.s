;*---------------------------------------------------------------------------
;  :Program.	Lotus2.asm
;  :Contents.	Slave for
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: Lotus2.asm 1.3 1999/09/16 22:31:47 jah Exp jah $
;  :History.	19.10.99 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/exec.i

	;OUTPUT	"wart:k-l/lotus2/Lotus2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

HRTMON					;enable debug support for hrtmon
NOFPU					;disable fpu support

BASEMEM		= $80000
EXPMEM		= $80000

KICKSIZE	= $40000		;34.005
CHIPMEMSIZE	= BASEMEM
FASTMEMSIZE	= EXPMEM-KICKSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Kickstarter",0
_copy		dc.b	"1989 Amiga",0
_info		dc.b	"Emulation by Wepl",10
		dc.b	"Version 0.1 "
		INCBIN	"T:date"
		dc.b	0
_kick		dc.b	"devs:kickstarts/kick34005.a500",0
_rtb		dc.b	"devs:kickstarts/kick34005.a500.rtb",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

	;set caches
		move.l	#0,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)

	;load kickstart
		lea	(_kick),a0
		move.l	(_expmem),a1
		move.l	a1,a4				;A4 = kickstart
		jsr	(resload_LoadFileDecrunch,a5)
		cmp.l	#KICKSIZE,d0
		bne	.wrongkick
		move.l	a4,a0
		jsr	(resload_CRC16,a5)
		cmp.w	#$f9e3,d0
		bne	.wrongkick

	;load relocation table
		lea	(_rtb),a0
		lea	($400),a1
		move.l	a1,a2				;A2 = rtb
		jsr	(resload_LoadFileDecrunch,a5)
		
	;relocate the kickstart
		addq.l	#4,a2				;skip kick-chksum
		move.l	#$fc0000,d2
		sub.l	a4,d2
		moveq	#0,d1
		bra	.1

.add		add.l	d0,d1
.2		sub.l	d2,(a4,d1.l)
		moveq	#0,d0
		move.b	(a2)+,d0
		bne	.add
		move.l	a2,d3
		btst	#0,d3
		beq	.3
		addq.l	#1,a2
.3		move.w	(a2)+,d0
		bne	.add
.1		move.l	(a2)+,d0
		bpl	.add

		asr.l	#2,d2
		bra	.4
.5		sub.l	d2,(a4,d1.l)
.4		move.l	(a2)+,d1
		bne	.5
		
	;patch the kickstart
		lea	kick_patch,a0
		move.l	a4,a1
		jsr	(resload_Patch,a5)

	;call
	;	jmp	(2,a4)				;original entry
		jmp	($fe,a4)			;34.005

.wrongkick	pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a5)

kick_patch	PL_START
		PL_W	$132,0				;color00 $444 -> $000
		PL_P	$61a,kick_detectfast
		PL_P	$592,kick_detectchip
		PL_W	$25a,0				;color00 $888 -> $000
	IFD HRTMON
		PL_PS	$286,kick_hrtmon
	ENDC
		PL_P	$546,kick_detectcpu
		PL_PS	$15b2,exec_MakeFunctions
		PL_PS	$422,exec_Supervisor
		PL_L	$4f4,-1				;disable search for residents at $f00000
		PL_S	$4cce,4				;skip autoconfiguration at $e80000
;	PL_I	$526
;	PL_I	$ae12
;	PL_I	$afba
;	PL_I	$af28
		PL_END

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem),a4
		add.l	#KICKSIZE,a4
		move.l	a4,($1f0-$1ea,a5)
		move.l	a4,($1fc-$1ea,a5)
		add.l	#FASTMEMSIZE,a4
		bsr	_flushcache
	ENDC
		jmp	(a5)

kick_detectchip	move.l	#CHIPMEMSIZE,a3
		jmp	(a5)

	IFD HRTMON
kick_hrtmon	move.l	a4,d0
		bne	.1
		move.l	a3,d0
.1		sub.l	#8,d0
		rts
	ENDC

kick_detectcpu	clr.l	-(a7)
		subq.l	#4,a7
		pea	WHDLTAG_ATTNFLAGS_GET
		move.l	a7,a0
		move.l	(_resload),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7)+,d0
		addq.l	#4,a7
	IFD NOFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_MakeFunctions
		subq.l	#8,a7
		move.l	(8,a7),(a7)
		move.l	a3,(4,a7)		;original
		lea	(_flushcache),a3
		move.l	a3,(8,a7)
		moveq	#0,d0			;original
		move.l	a2,d1			;original
		rts

exec_Supervisor	lea	(.1),a0
		move.l	a0,(_LVOSupervisor+2,a6)
		lea	(_custom),a0		;original
		bra	_flushcache

.1		movem.l	a0-a1,-(a7)
		move.l	($bc),a0
		lea	(.2),a1
		move.l	a1,($bc)
		move.l	a7,a1
		trap	#15
		addq.l	#8,a7
		rts

.2		move.l	a0,($bc)
		movem.l	(a1),a0-a1
		jmp	(a5)

_flushcache	move.l	(_resload),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

_resload	dc.l	0

;============================================================================

	END

