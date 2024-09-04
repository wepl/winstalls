;*---------------------------------------------------------------------------
;  :Modul.	picture.s
;  :Contents.	show picture (init custom/copper, decrunch pic)
;  :History.	30.08.97 extracted form slave sources
;  :Requires.	_resload	long variable containing resload base
;		_colors		color table
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*
;
; IN:	A0 = APTR start of packed picture
;	A1 = APTR address for screen memory
; OUT:	d0-d1/a0-a1 destroyed
;
;--------------------------------

_Picture	movem.l	d2-d7/a2-a6,-(a7)

		lea	(_custom),a6		;A6 = _custom
		move.l	(_resload),a5		;A5 = _resload
		move.l	a1,a4			;A4 = Screen start
		moveq	#3,d4			;D4 = Picture depth
		
		move.l	a4,a1
		jsr	(resload_Decrunch,a5)
		
		lea	(a4,d0.l),a1		;A1 copperlist
		divu	d4,d0			;D0 size of a bitplane
		move.w	#bplpt,d1
		move.l	a1,(cop1lc,a6)
		move.l	a4,d2
		move.l	d4,d3

.mcl		move.w	d1,(a1)+
		addq.w	#2,d1
		swap	d2
		move.w	d2,(a1)+
		move.w	d1,(a1)+
		addq.w	#2,d1
		swap	d2
		move.w	d2,(a1)+
		add.l	d0,d2
		subq.w	#1,d3
		bne	.mcl
		moveq	#-2,d0
		move.l	d0,(a1)+
		waitvb	a6
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER,(dmacon,a6)
		
		lea	_colors,a0
		lea	(color,a6),a1
		moveq	#1,d0
		lsl.w	d4,d0
.mc		move.w	(a0)+,(a1)+
		subq.w	#1,d0
		bne	.mc
		
		move.l	#$2981f1c1,(diwstrt,a6)		;320x200
		move.l	#$003800d0,(ddfstrt,a6)
		move.w	d4,d0				;depth
		ror.w	#4,d0
		or.w	#$0200,d0
		move.w	d0,(bplcon0,a6)
		clr.w	(bplcon1,a6)
		clr.l	(bpl1mod,a6)

		waitvb	a6
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER,(dmacon,a6)
		
		movem.l	(a7)+,d2-d7/a2-a6
		rts


