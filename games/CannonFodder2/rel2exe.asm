;*---------------------------------------------------------------------------
;  :Program.	rel2exe.asm
;		build amiga exe from cf2 and cf2.rel
;  :Author.	WEPL
;  :History.	V 0.1 29.02.96
;		0.2 2026-03-07 skip broken part
;  :Requires.	OS V37+
;  :Copyright.	Public Domain
;  :Language.	68020 Assembler
;  :Translator.	Barfly V1.131
;---------------------------------------------------------------------------*
;##########################################################################

	INCDIR	Includes:
	INCLUDE	lvo/exec.i
	INCLUDE	exec/memory.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i
	
	INCLUDE	macros/ntypes.i

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

GL	EQUR	A4		;a4 ptr to Globals
LOC	EQUR	A5		;a5 for local vars

	STRUCTURE	ReadArgsArray,0
		ULONG	rda_input
		ULONG	rda_output
		ULONG	rda_inleav
		LABEL	rda_SIZEOF

	NSTRUCTURE	Globals,0
		NAPTR	gl_execbase
		NAPTR	gl_dosbase
		NAPTR	gl_rdargs
		NSTRUCT	gl_rdarray,rda_SIZEOF
		NALIGNLONG
		NLABEL	gl_SIZEOF

;##########################################################################

VER	MACRO
		dc.b	"rel2exe 0.2 "
	INCBIN	".date"
		dc.b	" by WEPL"
	ENDM

		bra	.start
		dc.b	"$VER: "
		VER
		dc.b	" V37+",0
	CNOP 0,2
.start

;##########################################################################

		link	GL,#gl_SIZEOF
		move.l	(4).w,(gl_execbase,GL)

		move.l	#37,d0
		lea	(_dosname),a1
		move.l	(gl_execbase,GL),a6
		jsr	_LVOOpenLibrary(a6)
		move.l	d0,(gl_dosbase,GL)
		beq	.nodoslib

		lea	(_ver),a0
		bsr	_Print

		lea	(_template),a0
		move.l	a0,d1
		lea	(gl_rdarray,GL),a0
		move.l	a0,d2
		moveq	#0,d3
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOReadArgs,a6)
		move.l	d0,(gl_rdargs,GL)
		bne	.argsok
		lea	(_readargs),a0
		bsr	_PrintErrorDOS
		bra	.noargs
.argsok	
		bsr	_Main
.opend
		move.l	(gl_rdargs,GL),d1
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOFreeArgs,a6)
.noargs
		move.l	(gl_dosbase,GL),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOCloseLibrary,a6)
.nodoslib
		unlk	GL
		moveq	#0,d0
		rts

;##########################################################################

	NSTRUCTURE	local_main,0
		NAPTR	lm_srcptr
		NULONG	lm_srcsize
		NAPTR	lm_srcrelptr
		NULONG	lm_srcrelsize
		NULONG	lm_destsize
		NULONG	lm_destptr
		NSTRUCT	lm_relname,30
		NLABEL	lm_SIZEOF

_Main		movem.l	d2/a2/a6,-(a7)
		link	LOC,#lm_SIZEOF

		move.l	(gl_rdarray+rda_input,GL),a0
		bsr	_LoadFileMsg
		move.l	d0,(lm_srcptr,LOC)
		beq	.end
		move.l	d1,(lm_srcsize,LOC)
		
		lea	(_reltemplate),a0
		lea	(gl_rdarray+rda_input,GL),a1
		lea	(lm_relname,LOC),a2
		moveq	#30,d0
		bsr	_FormatString
		
		lea	(lm_relname,LOC),a0
		bsr	_LoadFileMsg
		move.l	d0,(lm_srcrelptr,LOC)
		beq	.freesrc
		move.l	d1,(lm_srcrelsize,LOC)
		
		move.l	(lm_srcsize,LOC),d0
		add.l	(lm_srcrelsize,LOC),d0
		add.l	#1000,d0
		move.l	#MEMF_ANY,d1
		move.l	(4),a6
		jsr	(_LVOAllocVec,a6)
		move.l	d0,(lm_destptr,LOC)
		beq	.freesrcrel

		move.l	(lm_destptr,LOC),a2
		move.l	#$3f3,(a2)+
		clr.l	(a2)+
		move.l	#1,(a2)+	;anzahl hunks
		move.l	#0,(a2)+	;first
		move.l	#0,(a2)+	;last
		move.l	(lm_srcsize,LOC),d0
		addq.l	#3,d0
		lsr.l	#2,d0
		move.l	d0,(a2)+	;hunk size
		move.l	#$3e9,(a2)+	;code
		move.l	d0,(a2)+	;size
		lsl.l	#2,d0
		move.l	d0,d2
		move.l	(lm_srcptr,LOC),a0
		move.l	a2,a1
		move.l	(4),a6
		jsr	(_LVOCopyMemQuick,a6)

	;skip broken part
		move.l	#$598,d1		;size broken block
		sub.l	d1,(lm_srcrelsize,LOC)
		move.l	(lm_srcrelsize,LOC),d0
		move.l	(lm_srcrelptr,LOC),a0
		add	#4,a0			;first is ok
		sub.l	#4,d0
		lea	(a0,d1.l),a1
.copy		move.l	(a1)+,(a0)+
		sub.l	#4,d0
		bcc	.copy

	;correct the executable by reversing "org $80000"
	;correct the relocs
		move.l	(lm_srcrelptr,LOC),a1
		move.l	(lm_srcrelsize,LOC),d0
.L_20A		MOVEA.L	A2,A0
		add.L	(A1),A0
		subq.l	#1,(a1)+	;reloc address --
		subq.B	#8,(A0)		;revert "org $80000"
		SUB.L	#4,D0
		BNE.B	.L_20A

		add.l	d2,a2
		move.l	#$3ec,(a2)+	;reloc32
		move.l	(lm_srcrelsize,LOC),d0
		lsr.l	#2,d0
		move.l	d0,(a2)+	;anzahl
		clr.l	(a2)+		;auf hunk 0
		lsl.l	#2,d0
		move.l	d0,d2
		move.l	(lm_srcrelptr,LOC),a0
		move.l	a2,a1
		move.l	(4),a6
		jsr	(_LVOCopyMemQuick,a6)
		add.l	d2,a2
		clr.l	(a2)+		;end
		move.l	#$3f2,(a2)+	;hunk end

		sub.l	(lm_destptr,LOC),a2
		move.l	a2,(lm_destsize,LOC)
		
		lea	(_desttemplate),a0
		lea	(gl_rdarray+rda_input,GL),a1
		lea	(lm_relname,LOC),a2
		moveq	#30,d0
		bsr	_FormatString

		move.l	(lm_destsize,LOC),d0
		move.l	(lm_destptr,LOC),a0
		lea	(lm_relname,LOC),a1
		bsr	_SaveFileMsg
.freedest
		move.l	(lm_destptr,LOC),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
.freesrcrel
		move.l	(lm_srcrelptr,LOC),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
.freesrc
		move.l	(lm_srcptr,LOC),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)

.end		unlk	LOC
		movem.l	(a7)+,d2/a2/a6
		rts

;##########################################################################

	INCDIR	Sources:
	INCLUDE	dosio.i
		PrintArgs
		Print
	INCLUDE	error.i
		PrintErrorDOS
	INCLUDE	files.i
		LoadFileMsg
		SaveFileMsg
	INCLUDE	strings.i
		FormatString

;##########################################################################

_reltemplate	dc.b	"%s.rel",0
_desttemplate	dc.b	"%s.exe",0

; Errors
_nomem		dc.b	"not enough free store",0

; Operationen
_readargs	dc.b	"read arguments",0
_allocdestmem	dc.b	"alloc temp dest mem",0

;subsystems
_dosname	dc.b	"dos.library",0

_template	dc.b	"FILE/A"		;name eines zu ladenden Files
		dc.b	0

_ver		VER
		dc.b	10,0

;##########################################################################

	END

