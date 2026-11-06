;*---------------------------------------------------------------------------
;  :Program.	WHDLoad.Audio.asm
;  :Contents.	audio plugin for WHDLoad, plays compressed audio tracks
;		(mp3, ogg, flac, wav, aac, m4a, wma) via additional audio hardware
;		as replacement for CD-DA tracks of CDTV/CD32 games
;  :Author.	Wepl
;  :History.	15.10.26 created, support for AmiGUS (Zorro II)
;		18.10.26 AmiGUS driver moved to amigus.s, common variable area _vars,
;			 driver functions copied into the header instead of dispatching
;  :Requires.	WHDLoad 21+
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, Vasm
;---------------------------------------------------------------------------*
; the plugin consists of a single hunk which contains all code and variables
; it supports multiple hardware drivers, on init all drivers are probed in the
; order of the driver table until the first one finds its hardware
; all routines called by WHDLoad get their arguments in registers and may
; modify d0/d1/a0/a1 only
; the interrupt routine must not touch any custom or cia register

	INCDIR	Includes:
	INCLUDE	exec/types.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdaudio.i

	IFD BARFLY
	OUTPUT	"C:WHDLoad.Audio"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	BOPT	w4-			;disable 64k warnings
	ENDC

; size of the variable area _vars, which is used by the active driver
; it is cleared by _init before calling the init of each driver
VARS_SIZEOF	= 320

	IFNE VARS_SIZEOF&3
	FAIL	VARS_SIZEOF must be a multiple of 4
	ENDC

;============================================================================
; internal driver structure, one for each supported hardware

	STRUCTURE	Driver,0
		APTR	drv_name		;name of the hardware
		APTR	drv_init		;detect and init hardware
						;OUT: d0 = WAUDINIT_*, a0 = error message
		;the following fields are copied into the plugin header
		;(waud_exts..waud_irq) and must be in the same order
		APTR	drv_exts		;supported extensions
		APTR	drv_mem			;memory areas used
		APTR	drv_exit
		APTR	drv_play
		APTR	drv_stop
		APTR	drv_suspend
		APTR	drv_resume
		APTR	drv_volume
		APTR	drv_irq
		LABEL	drv_SIZEOF

;============================================================================

	SECTION	plugin,CODE

;============================================================================
; plugin header

_base		WAUD_HEADER
		dc.w	WAUD_VERSION		;waud_version
		dc.w	0			;waud_flags
		dc.l	_name			;waud_name
		dc.l	0			;waud_trace
		dc.l	_init			;waud_init
		dc.l	0			;waud_exts	set by _init from
		dc.l	0			;waud_mem	the found driver
		dc.l	0			;waud_exit
		dc.l	0			;waud_play
		dc.l	0			;waud_stop
		dc.l	0			;waud_suspend
		dc.l	0			;waud_resume
		dc.l	0			;waud_volume
		dc.l	0			;waud_irq

	IFNE *-_base-waud_SIZEOF
	FAIL	plugin header has wrong size
	ENDC
	IFNE waud_SIZEOF-waud_exts-(drv_SIZEOF-drv_exts)
	FAIL	driver structure doesn't match plugin header
	ENDC

		dc.b	"$VER: "
_name		dc.b	"WHDLoad.Audio 1.0 "
	INCBIN	".date"
		dc.b	0
_trc_probe	dc.b	"audio: probing for %s",0
_trc_nohw	dc.b	"audio: no supported hardware found",0
	EVEN

;============================================================================
; table of supported hardware, probed in this order

_drivers	dc.l	amigus_driver
		dc.l	0

;============================================================================
; initialize plugin, probe all drivers
; IN:	-
; OUT:	d0 = LONG WAUDINIT_*
;	a0 = CPTR error message on WAUDINIT_ERROR

_init		movem.l	a2-a3,-(a7)
		lea	(_drivers,pc),a2	;A2 = driver table
.next		move.l	(a2)+,d0
		beq	.nohw
		move.l	d0,a3			;A3 = actual driver
		lea	(_trc_probe,pc),a0
		lea	(drv_name,a3),a1
		bsr	_trace
	;clear variables, they may contain garbage from a previous driver
		lea	(_vars,pc),a0
		moveq	#VARS_SIZEOF/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr
		move.l	(drv_init,a3),a0
		jsr	(a0)
		tst.l	d0
		beq	.found
		bpl	.next
	;error, a0 = message
		bra	.end

	;copy driver data and functions into the plugin header
.found		lea	(drv_exts,a3),a0
		lea	(_base+waud_exts,pc),a1
		moveq	#(drv_SIZEOF-drv_exts)/4-1,d0
.copy		move.l	(a0)+,(a1)+
		dbf	d0,.copy
		moveq	#WAUDINIT_OK,d0
		bra	.end

.nohw		lea	(_trc_nohw,pc),a0
		sub.l	a1,a1
		bsr	_trace
		moveq	#WAUDINIT_NOHW,d0
.end		movem.l	(a7)+,_MOVEMREGS
		rts

;============================================================================
; write trace message via WHDLoad (only during init/exit)
; IN:	a0 = CPTR format string
;	a1 = APTR argument array
; OUT:	-
;	d0-d1/a0-a1 destroyed

_trace		move.l	(_base+waud_trace,pc),-(a7)
		bne	.rts
		add	#4,a7
.rts		rts

;============================================================================
; drivers

	INCLUDE	amigus.s

;============================================================================
; uninitialized variables, must be at the end

	CNOP 0,4
_vars		dx.b	VARS_SIZEOF		;variables of all drivers

;============================================================================

	END

