;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.5 2003/03/30 18:26:15 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;		23.07.02 RUN patch added
;		04.03.03 full caches
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:.debug/Kick13.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 2
WPDRIVES	= %1111

;BLACKSCREEN
CACHE
DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
HDINIT
HRTMON
IOCACHE		= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv|WHDLF_Examine	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-_base		;ws_GameLoader
		dc.w	_dir-_base		;ws_CurrentDir
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

_dir		dc.b	"wb13",0
_name		dc.b	"Kickstarter for 34.005",0
_copy		dc.b	"1987 Amiga Inc.",0
_info		dc.b	"adapted for WHDLoad by Wepl",10
		dc.b	"Version 0.5 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================

	IFEQ 1
_bootearly	blitz
		rts
	ENDC

	IFEQ 1
; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	blitz
		jmp	(12,a4)
	ENDC

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg	lsl.l	#2,d0		;-> APTR
		move.l	d0,a0
		moveq	#0,d0
		move.b	(a0)+,d0	;D0 = name length
	;remove leading path
		move.l	a0,a1
		move.l	d0,d2
.2		move.b	(a1)+,d3
		subq.l	#1,d2
		cmp.b	#":",d3
		beq	.1
		cmp.b	#"/",d3
		beq	.1
		tst.l	d2
		bne	.2
		bra	.3
.1		move.l	a1,a0		;A0 = name
		move.l	d2,d0		;D0 = name length
		bra	.2
.3	;get hunk length sum
		move.l	d1,a1		;D1 = segment
		moveq	#0,d2
.add		add.l	a1,a1
		add.l	a1,a1
		add.l	(-4,a1),d2	;D2 = hunks length
		subq.l	#8,d2		;hunk header
		move.l	(a1),a1
		move.l	a1,d7
		bne	.add
	;search patch
		lea	.patch,a1
.next		move.l	(a1)+,d3
		movem.w	(a1)+,d4-d5
		beq	.end
		cmp.l	d2,d3		;length match?
		bne	.next
	;compare name
		lea	(.patch,pc,d4.w),a2
		move.l	a0,a3
		move.l	d0,d6
.cmp		move.b	(a3)+,d7
		cmp.b	#"a",d7
		blo	.l
		cmp.b	#"z",d7
		bhi	.l
		sub.b	#$20,d7
.l		cmp.b	(a2)+,d7
		bne	.next
		subq.l	#1,d6
		bne	.cmp
		tst.b	(a2)
		bne	.next
	;patch
		lea	(.patch,pc,d5.w),a0
		move.l	d1,a1
		move.l	(_resload),a2
		jsr	(resload_PatchSeg,a2)
	;end
.end
	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d1,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC
		rts

PATCH	MACRO
		dc.l	\1		;cumulated size of hunks (not filesize!)
		dc.w	\2-.patch	;name
		dc.w	\3-.patch	;patch list
	ENDM

.patch		PATCH	2516,.n_run,_p_run2568
		dc.l	0

	;all upper case!
.n_run		dc.b	"RUN",0
	EVEN

_p_run2568	PL_START
	;	PL_P	0,.1
		PL_END

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

