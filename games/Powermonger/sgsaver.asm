;##########################################################################
; $Id$
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

	NSTRUCTURE	Globals,0
		NAPTR	gl_execbase
		NAPTR	gl_dosbase
		NALIGNLONG
		NLABEL	gl_SIZEOF

;##########################################################################

	SECTION	"",CODE,RELOC16

VER	MACRO
		dc.b	"sgsaver 0.1 "
	DOSCMD	"WDate >t:date"
	INCBIN	"t:date"
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

		bsr	_Main
.opend
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
		NLABEL	lm_SIZEOF

_Main		movem.l	d2/a2-a6,-(a7)
		link	LOC,#lm_SIZEOF
		lea	(_disk),a0
		bsr	_LoadFileMsg
		move.l	d1,(lm_srcsize,LOC)
		move.l	d0,(lm_srcptr,LOC)
		beq	.end

		cmp.l	#901120,(lm_srcsize,LOC)
		bne	.freefile

		move.l	(lm_srcptr,LOC),a3
		cmp.l	#"SAVE",(a3)		;check for right disk
		bne	.freefile
		
		add.w	#$2c00,a3
		lea	(_sg),a2
		
		moveq	#8-1,d2

.loop		move.l	a3,a0
		add.l	#$18bd0,a0
		tst.l	(a0)+
		bne	.skip
		tst.l	(a0)+
		bne	.skip

		move.l	#101345,d0		;size
		move.l	a3,a0			;ptr
		move.l	a2,a1			;name
		bsr	_SaveFileMsg
.skip
		add.l	#$18c00,a3
		addq.b	#1,(a2)
		
		dbf	d2,.loop

.freefile
		move.l	(lm_srcptr,LOC),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)

.end		unlk	LOC
		movem.l	(a7)+,d2/a2-a6
		rts

;##########################################################################

	INCDIR	Sources:
	INCLUDE	files.i
		LoadFileMsg
		SaveFileMsg

;##########################################################################

_dosname	dc.b	"dos.library",0
_disk		dc.b	"disk.1",0
_sg		dc.b	"A",0
	EVEN

;##########################################################################

	END

