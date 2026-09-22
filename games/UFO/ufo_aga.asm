;*---------------------------------------------------------------------------
;  :Modul.	ufo_aga.asm
;  :Contents.	UFO Enemy Unknown AGA/CD32
;  :Author.     Cfou!
;  :Version.    $Id: UFO_AGA.asm 1.4 2018/03/21 11:37:34 wepl Exp wepl $
;  :History.    04.03.03 started
;               22.06.03 rework for whdload v16
;		12.07.15 IOCACHE set
;		19.03.18 general cleanup and update!
;			 v17 button infos added
;			 nonvolatile stuff replaced
;			 chip memory requirements reduced
;  :Requires.   kick31.s
;  :Copyright.  Public Domain
;  :Language.   68000 Assembler
;  :Translator. Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

        INCDIR  Includes:
        INCLUDE whdload.i
        INCLUDE whdmacros.i
        INCLUDE lvo/dos.i

        IFD BARFLY
        OUTPUT  "wart:u/UFO/UFO_AGA.Slave"
        BOPT    O+                              ;enable optimizing
        BOPT    OG+                             ;enable optimizing
        BOPT    ODd-                            ;disable mul optimizing
        BOPT    ODe-                            ;disable mul optimizing
        BOPT    w4-                             ;disable 64k warnings
        BOPT    wo-                             ;disable optimize warnings
        SUPER
        ENDC

;============================================================================

CHIPMEMSIZE	= $180000	;size of chip memory
FASTMEMSIZE	= $100000	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
INITAGA				;enable AGA features
;INIT_AUDIO			;enable audio.device
;INIT_GADTOOLS			;enable gadtools.library
;INIT_LOWLEVEL			;load lowlevel.library
;INIT_MATHFFP			;enable mathffp.library
IOCACHE		= 17000		;cache for the filesystem handler (per fh)
;JOYPADEMU			;use keyboard for joypad buttons
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;NO68020				;remain 68000 compatible
;POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick31.s
	INCLUDE	whdload/nonvolatile.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"UFO Enemy Unknown",0
slv_copy	dc.b	"1994 Microprose",0
slv_info	dc.b	"adapted for WHDLoad by CFou!/Wepl",10
		dc.b	"AGA/CD³² Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
	IFGE slv_Version-17
slv_config	dc.b	"C1:B:Skip Intro (CD³²)",0
	ENDC
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required, this will never called if booted from a diskimage, only
; works in conjunction with the virtual filesystem of HDINIT
; this routine replaces the loading and executing of the startup-sequence
;
; the following example is simple and wont work for BCPL programs and 
; programs build using MANX Aztec-C
; for a more compatible routine check kick13.s

	IFD BOOTDOS

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;get tags
		lea	_tags,a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea     (_ufotemp,pc),a0
		lea	_ram,a1
		bsr     _dos_assign

	;intro
		lea	_program_intro,a0
		jsr	(resload_GetFileSize,a2)
		beq	.skipintro		;AGA version hasn't intro

		bsr	_nonvolatile_init

		move.l	_custom1,d0
		bne	.skipintro

		lea	_args_intro,a0
		moveq	#_args_end_intro-_args_intro,d0
		move.w	#$750c,d1
		lea	_program_intro,a1
		lea	_pl_intro,a3
		bsr	_exec
.skipintro
		lea	_args_00,a0
		moveq	#_args_end_00-_args_00,d0
		move.w	#$3625,d1
		move.w	#$4938,d2
		lea	_program_geo,a1		; "geo "0" "0""
		lea	_pl_geo,a3
		lea	_pl_geo_cd,a4
		bsr	_exec
		tst.l	d0
		beq	.quit
.loop
		lea	_args_10,a0
		moveq	#_args_end_10-_args_10,d0
		move.w	#$6108,d1
		move.w	#$f815,d2
		lea	_program_tact,a1	; "tactical "1" "0""
		lea	_pl_tact,a3
		lea	_pl_tact_cd,a4
		bsr	_exec

		lea	_args_10,a0
		moveq	#_args_end_10-_args_10,d0
		move.w	#$3625,d1
		move.w	#$4938,d2
		lea	_program_geo,a1		; "geo "1" "0""
		lea	_pl_geo,a3
		lea	_pl_geo_cd,a4
		bsr	_exec
		tst.l	d0
		bne	.loop
.quit
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_exec		movem.l	d0-d2/a0-a1/a3-a4,-(a7)

	;check version
		move.l	a1,a0			;name
		move.l	#300,d3			;maybe 300 byte aren't enough for version compare...
		move.l	d3,d0			;length
		moveq	#0,d1			;offset
		sub.l	d3,a7
		move.l	a7,a1			;buffer
		jsr	(resload_LoadFileOffset,a2)
		move.l	d3,d0
		move.l	a7,a0
		jsr	(resload_CRC16,a2)
		add.l	d3,a7

		move.l	(5*4,a7),d2		;a3
		cmp.w	(6,a7),d0		;d1
		beq	.versionok
		move.l	(6*4,a7),d2		;a4
		cmp.w	(10,a7),d0		;d2
		beq	.versionok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		move.l	(16,a7),d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
		move.l	d2,a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		move.l	(a7),d0
		move.l	(12,a7),a0
		jsr	(4,a1)
		move.l	d0,a3

	;remove exe
		move.l	d7,d1
		move.l	(_dosbase,pc),a6
		jsr	(_LVOUnLoadSeg,a6)

		move.l	a3,d0
		add.w	#7*4,a7
		rts

.program_err	jsr	(_LVOIoErr,a6)
		move.l	(12,a7),-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

_ufotemp	dc.b	"UFOTemp",0
_ram		dc.b	"RAM:",0
_program_intro	dc.b	"intro",0
_args_intro	dc.b	10
_args_end_intro	dc.b	0
_program_geo	dc.b	"geo",0
_program_tact	dc.b	"tactical",0
_args_00	dc.b	'"0" "0"',10
_args_end_00	dc.b	0
_args_10	dc.b	'"1" "0"',10
_args_end_10	dc.b	0
	EVEN

_pl_intro	PL_START
		PL_END

_pl_geo		PL_START
		PL_P	$5e,.jmp	;Imploder
		PL_END
.jmp		lea	_pl_geo_x,a0
_jmp		move.l	($3c,a7),d0
		lsr.l	#2,d0
		subq.l	#1,d0
		move.l	d0,a1
		move.l	d0,d2
		move.l	_resload,a2
		jsr	(resload_PatchSeg,a2)
	;set debug
	IFD DEBUG
		clr.l	-(a7)
		move.l	d2,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC
		movem.l	(a7)+,d0-a6	;original
		rts			;original
_pl_geo_x	PL_START
		PL_S	$2846,2		;protection
		PL_S	$284c,2		;protection
		PL_DATA	$2866,6		;protection
			move.b	(a0),($14,sp,d4.l)
			dw	$6006
		PL_S	$288c,2		;protection
		PL_S	$2894,2		;protection
		PL_W	$28a4,$4279	;protection tst.w -> clr.w
		PL_B	$28aa,$60	;protection
		PL_CB	$493aa+7	;DEUTSCHE
		PL_END

_pl_tact	PL_START
		PL_END

_pl_geo_cd	PL_START
	;	PL_BKPT	$3e48e		;open nonvolatile
		PL_CB	$4d650+7	;DEUTSCHE
		PL_END

_pl_tact_cd	PL_START
		PL_END

        ENDC

;============================================================================

_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
_dosbase	dc.l	0

;============================================================================

