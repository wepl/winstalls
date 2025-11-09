;*---------------------------------------------------------------------------
;  :Program.	divzero.asm
;  :Contents.	check for condition codes after divu/s by zero
;		http://eab.abime.net/showthread.php?t=68345
;  :Author.	Wepl
;  :History.	17.03.13 created
;		09.11.25 imported to winstalls
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i

 BITDEF AF,68060,7
 BITDEF AF,UAE,9

	IFD BARFLY
	;OUTPUT	wart:.debug/DivZero.Slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoDivZero		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	0			;ws_keyexit
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

_name		dc.b	"Check Division by Zero",0
_copy		dc.b	"Wepl",0
_info		dc.b	"created by Wepl",10
		dc.b	"Version 1.0 "
		INCBIN	".date"
		dc.b	0
_res		dc.b	"MC680"
_cpu		dc.b	"00 UAE="
_uae		dc.b	"N",10
		dc.b	"divu X="
_tu		dc.b	"X N=X Z=X V=X C=X",10
		dc.b	"divs X="
_ts		dc.b	"X N=X Z=X V=X C=X",0

	EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_divu,a1
		lea	_tu,a2
		bsr	_test

		lea	_divs,a1
		lea	_ts,a2
		bsr	_test

		move.l	a0,a3
		clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_ATTNFLAGS_GET
		move.l	a7,a0
		jsr	(resload_Control,a3)
		lea	_cpu,a0
		move.l	(4,a7),d0
		btst	#AFB_68010,d0
		beq	.u
		moveq	#"1",d1
		btst	#AFB_68020,d0
		beq	.w
		moveq	#"2",d1
		btst	#AFB_68030,d0
		beq	.w
		moveq	#"3",d1
		btst	#AFB_68040,d0
		beq	.w
		moveq	#"4",d1
		btst	#AFB_68060,d0
		beq	.w
		moveq	#"6",d1
.w		move.b	d1,(a0)
.u		btst	#AFB_UAE,d0
		beq	.nu
		move.b	#"Y",(_uae-_cpu,a0)
.nu
		pea	_res
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a3)

_divu		divu	d0,d1
		rts

_divs		divs	d0,d1
		rts

_test		moveq	#0,d0
		moveq	#-1,d1
		move	d0,ccr
		jsr	(a1)
		move	sr,d6
		lea	(4*4,a2),a3
		moveq	#4,d7
.lp1		lsr.w	#1,d6
		bcc	.s1
		move.b	#"1",(a3)
.s1		subq.w	#4,a3
		dbf	d7,.lp1

		moveq	#0,d0
		moveq	#-1,d1
		move	d1,sr
		jsr	(a1)
		move	sr,d6
		lea	(4*4,a2),a3
		moveq	#4,d7
.lp2		lsr.w	#1,d6
		bcs	.s2
		move.b	#"0",(a3)
.s2		subq.w	#4,a3
		dbf	d7,.lp2

		rts

;======================================================================

	END

