;*---------------------------------------------------------------------------
;  :Program.	savegame.s
;  :Contents.	routine for multiple save game support
;		it creates an interface from which the user can choice between
;		9 different savegames, a description can be entered for each
;		savegame, all savegames will be stored in one single file which
;		grows dynamically
;		the savegames must have always the same size
;  :Author.	Wepl
;  :Version.	$Id: interphase.asm 1.6 1998/05/25 15:45:29 jah Exp jah $
;  :History.	14.06.98 extracted from Interphase slave
;		15.06.98 returncode fixed
;			 problem with savegames larger than $7fff fixed
;  :Requires.	_keyexit	byte variable containing rawkey code
;		_exit		function to quit
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
; this is a example sequence to use the savegame routine
; during execution some custom registers will be destroyed, if the installed
; program does not refresh them itself, it must be done after calling the
; savegame routine

	IFEQ 1

		move.l	#100,d0			;savegame size
		lea	$3e900,a0		;address of savegame
		lea	$65000,a1		;free mem for screen
		bsr	_sg_load
	;	move.w	#$4100,(_custom+bplcon0)
	;	move.w	#320/8*3,(_custom+bpl1mod)
	;	move.l	#$00000eee,(_custom+color)

	ENDC

;--------------------------------
; IN:	d0 = ULONG size (only on function save required)
;	a0 = APTR  address of load/save area
;	a1 = APTR  space for the screen ($2800 bytes)
; OUT:	d0 = BOOL  success
;	d1/a0/a1 destroyed

MAXNAMELEN	= 40
LINE		= 320/8
SCREEN		= LINE*200
SAVEDIRLEN	= 4+10+(10*MAXNAMELEN)
CHARHEIGHT	= 5
CHARWIDTH	= 5

	INCLUDE	macros/ntypes.i

	NSTRUCTURE	SaveGame,0
		NLONG	sg_screen
		NLONG	sg_size
		NLONG	sg_address
		NLONG	sg_old68
		NLONG	sg_old6c
		NWORD	sg_oldintena
		NWORD	sg_olddmacon
		NSTRUCT	sg_save_names,10*MAXNAMELEN
		NSTRUCT	sg_save_flags,10
		NSTRUCT	sg_save_id,4
		NSTRUCT	sg_tmpname,MAXNAMELEN
		NWORD	sg_c_x
		NWORD	sg_c_y
		NBYTE	sg_key
		NBYTE	sg_c_on
		NBYTE	sg_success
		NALIGNLONG
		NLABEL	sg_SIZEOF

;--------------------------------
; print save game directory
; IN:	-
; OUT:	-

XBASE	= 50
YBASE	= 40
YSKIP	= 15

_sg_printdir	moveq	#XBASE,d0		;x-pos
		moveq	#YBASE-YSKIP,d1		;first line
		moveq	#'1',d2
		moveq	#0,d3			;amount saves
.next		add.w	#YSKIP,d1		;line skip
		bsr	_pc
		movem.l	d0/d2,-(a7)
		add.w	#15,d0
		sub.w	#'1',d2
		mulu.w	#MAXNAMELEN,d2
		lea	(sg_save_names,a5),a0
		add.w	d2,a0
		bsr	_ps
		movem.l	(a7)+,d0/d2
		addq.b	#1,d2
		cmp.b	#'9',d2
		bls	.next
		rts

;--------------------------------
; save a savegame
; IN:	D0 = size of the savegame
;	A0 = address to load savegame on
;	A1 = address of free memory for screen ($2800 bytes)
; OUT:	D0 = BOOL success

_sg_save	moveq	#0,d1
		bra	_sg_degrade
_sg_save_in	bsr	_sg_loaddir

.start		moveq	#7,d1
		lea	_save,a0
		bsr	_psc
		add.w	#8,d1
		lea	_saveselect,a0
		bsr	_psc
		add.w	#8,d1
		lea	_esc,a0
		bsr	_psc

		bsr	_sg_printdir

.keyloop	bsr	_sg_get_key
		cmp.b	#$45,d0
		beq	_sg_restore
		
		lea	(_keytrans),a0
		move.b	(a0,d0.w),d1
		cmp.b	#'1',d1
		blo	.keyloop
		cmp.b	#'9',d1
		bhi	.keyloop
		
		moveq	#XBASE+9,d0
		sub.w	#'1',d1
		move.w	d1,d6			;D6 = save no.
		mulu	#YSKIP,d1
		add.w	#YBASE-5,d1
		move.w	d0,d2
		add.w	#210,d2
		move.w	d1,d3
		add.w	#YSKIP-1,d3
		bsr	_sg_rect
		
		move.w	d6,d0
		mulu.w	#MAXNAMELEN,d0
		lea	(sg_save_names,a5),a3
		add.w	d0,a3			;A3 = save name
		
		move.l	a3,a0
		lea	(sg_tmpname,a5),a1
.cpy		move.b	(a0)+,(a1)+
		bne	.cpy

.chkname	moveq	#-1,d5
		move.l	a3,a0
.cnt		addq.w	#1,d5			;D5 = charpos in save name
		tst.b	(a0)+
		bne	.cnt
		
		move.w	d5,d0
		mulu	#CHARWIDTH,d0
		add.w	#XBASE+15,d0
		move.w	d0,(sg_c_x,a5)
		move.w	d6,d1
		mulu	#YSKIP,d1
		add.w	#YBASE,d1
		move.w	d1,(sg_c_y,a5)
		st	(sg_c_on,a5)

		moveq	#15,d1
		lea	_saveinsert,a0
		bsr	_psc
		
.nextkey	bsr	_sg_get_key
		cmp.b	#$43,d0			;enter
		beq	.return
		cmp.b	#$44,d0			;return
		beq	.return
		cmp.b	#$41,d0			;backspace
		beq	.bs
		cmp.b	#$46,d0			;delete
		beq	.bs
		cmp.b	#$45,d0			;escape
		beq	.esc
		cmp.w	#MAXNAMELEN-1,d5
		beq	.nextkey
		lea	(_keytrans),a0
		move.b	(a0,d0.w),d2
		beq	.nextkey
		move.b	d2,(a3,d5.w)
		addq.w	#1,d5
		move.w	(sg_c_x,a5),d0
		move.w	(sg_c_y,a5),d1
		add.w	#CHARWIDTH,(sg_c_x,a5)
		bsr	_pc
		bra	.nextkey

.bs		tst.w	d5
		beq	.nextkey
		bsr	_sg_cursoroff
		subq.w	#1,d5
		clr.b	(a3,d5.w)
		bra	.chkname

.esc		bsr	_sg_cursoroff
		lea	(sg_tmpname,a5),a0
		move.l	a3,a1
.cpy2		move.b	(a0)+,(a1)+
		bne	.cpy2
		bsr	_sg_initscr
		bra	.start
		
.return		tst.w	d5			;a name specified ?
		beq	.esc
		bsr	_sg_cursoroff

		moveq	#15,d1
		lea	_saveconfirm,a0
		bsr	_psc
		
.nextkey2	bsr	_sg_get_key
		cmp.b	#$45,d0			;escape
		beq	.esc
		cmp.b	#$43,d0			;enter
		beq	.confirmed
		cmp.b	#$44,d0			;return
		bne	.nextkey2

.confirmed	lea	(sg_save_flags,a5),a0
		st	(a0,d6.w)

		move.l	#SAVEDIRLEN,d0		;size
		moveq	#0,d1			;offset
		lea	(_sg_name),a0		;filename
		lea	(sg_save_id,a5),a1	;address
		move.w	#resload_SaveFileOffset,a2
		bsr	_sg_exec_resload

		move.l	(sg_size,a5),d0		;size
		move.l	#SAVEDIRLEN,d1
		bra	.loopin
.loop		add.l	d0,d1			;offset
.loopin		subq.w	#1,d6
		bpl	.loop
		lea	(_sg_name),a0		;filename
		move.l	(sg_address,a5),a1	;address
		move.w	#resload_SaveFileOffset,a2
		bsr	_sg_exec_resload

		st	(sg_success,a5)
		bra	_sg_restore

;--------------------------------
; disable text cursor
; IN:	-
; OUT:	-

_sg_cursoroff	sf	(sg_c_on,a5)
		move.w	(sg_c_x,a5),d0
		move.w	(sg_c_y,a5),d1
		move.w	#' ',d2
		bra	_pc

;--------------------------------
; clear screen
; IN:	-
; OUT:	-

_sg_clrscr	movem.l	d0/a0,-(a7)

		move.l	(sg_screen,a5),a0
		move.w	#(320*256/8)/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr

		movem.l	(a7)+,d0/a0
		rts

;--------------------------------
; init screen
; IN:	-
; OUT:	-

_sg_initscr	movem.l	d0-d3/a0,-(a7)

		bsr	_sg_clrscr

	;draw border
	;	moveq	#0,d0
	;	moveq	#0,d1
	;	move.w	#319,d2
	;	move.w	#199,d3
	;	bsr	_sg_rect
	;print info
		move.w	#180,d1
		lea	_info1,a0
		bsr	_psc
		add.w	#8,d1
		lea	_info2,a0
		bsr	_psc

		movem.l	(a7)+,d0-d3/a0
		rts

;--------------------------------
; load a savegame
; IN:	A0 = address to load savegame on
;	A1 = address of free memory for screen ($2800 bytes)
; OUT:	D0 = BOOL success

_sg_load	moveq	#-1,d1
		bra	_sg_degrade
_sg_load_in	bsr	_sg_loaddir
		beq	.nosavegame

.start		moveq	#7,d1
		lea	_load,a0
		bsr	_psc
		add.w	#8,d1
		lea	_loadselect,a0
		bsr	_psc
		add.w	#8,d1
		lea	_esc,a0
		bsr	_psc
		
		bsr	_sg_printdir
		
		lea	(sg_save_names,a5),a0
		moveq	#0,d0
		

.keyloop	bsr	_sg_get_key
		cmp.b	#$45,d0
		beq	_sg_restore
		
		lea	(_keytrans),a0
		moveq	#0,d1
		move.b	(a0,d0.w),d1
		cmp.b	#'1',d1
		blo	.keyloop
		cmp.b	#'9',d1
		bhi	.keyloop
		
		lea	(sg_save_flags,a5),a0
		tst.b	(-'1',a0,d1.w)
		beq	.keyloop
		
		moveq	#XBASE+9,d0
		sub.w	#'1',d1
		move.w	d1,d6			;D6 = save no.
		mulu	#YSKIP,d1
		add.w	#YBASE-5,d1
		move.w	d0,d2
		add.w	#210,d2
		move.w	d1,d3
		add.w	#YSKIP-1,d3
		bsr	_sg_rect
		
		moveq	#15,d1
		lea	_loadconfirm,a0
		bsr	_psc
		
.nextkey2	bsr	_sg_get_key
		cmp.b	#$43,d0			;enter
		beq	.confirmed
		cmp.b	#$44,d0			;return
		beq	.confirmed
		cmp.b	#$45,d0			;escape
		bne	.nextkey2
		bsr	_sg_initscr
		bra	.start

.confirmed	move.l	(sg_size,a5),d0		;size
		move.l	#SAVEDIRLEN,d1
		bra	.loopin
.loop		add.l	d0,d1			;offset
.loopin		subq.w	#1,d6
		bpl	.loop
		lea	(_sg_name),a0		;filename
		move.l	(sg_address,a5),a1	;address
		move.w	#resload_LoadFileOffset,a2
		bsr	_sg_exec_resload

		st	(sg_success,a5)
		bra	_sg_restore

.nosavegame	moveq	#60,d1
		lea	_loadno1,a0
		bsr	_psc
		add.w	#8,d1
		lea	_loadno2,a0
		bsr	_psc
		bsr	_sg_get_key
		bra	_sg_restore

;--------------------------------
; loads save directory
; IN:	-
; OUT:	D0 = BOOL success
;	flags on D0

_sg_loaddir	lea	(_sg_name),a0
		move.w	#resload_GetFileSize,a2
		bsr	_sg_exec_resload
		tst.l	d0
		beq	.nocurrentfile

		move.l	#SAVEDIRLEN,d0		;size
		moveq	#0,d1			;offset
		lea	(_sg_name),a0		;filename
		lea	(sg_save_id,a5),a1	;address
		move.w	#resload_LoadFileOffset,a2
		bsr	_sg_exec_resload
		cmp.l	#"Wepl",(sg_save_id,a5)
		bne	.nocurrentfile
		moveq	#-1,d0			;successful loaded
		rts

.nocurrentfile	lea	(sg_save_id,a5),a0
		move.w	#SAVEDIRLEN/4-1,d0
.clr0		clr.l	(a0)+
		dbf	d0,.clr0
		move.l	#"Wepl",(sg_save_id,a5)
		moveq	#0,d0			;nothing current
		rts

;--------------------------------
; execute resload function

_sg_exec_resload
		move.w	#INTF_INTEN,(intena,a6)
		add.l	(_resload),a2
		jsr	(a2)
		move.w	#INTF_SETCLR!INTF_INTEN,(intena,a6)
		clr.l	($144,a6)
		clr.l	($14c,a6)
		rts

;--------------------------------

_sg_get_key	clr.b	(sg_key,a5)
		moveq	#0,d0
.waitdown	move.b	(sg_key,a5),d0
		ble	.waitdown
		bchg	#7,d0
.waitup		cmp.b	(sg_key,a5),d0
		bne	.waitup
		bclr	#7,d0
		rts

;--------------------------------

_sg_degrade	movem.l	d2-d7/a2-a6,-(a7)
		link	a5,#sg_SIZEOF			;A5 = data
		move.l	d0,(sg_size,a5)
		move.l	a0,(sg_address,a5)
		move.l	a1,(sg_screen,a5)
		sf	(sg_c_on,a5)
		sf	(sg_success,a5)
		bsr	_sg_waitvb
		move.w	(_custom+intenar),(sg_oldintena,a5)
		move.w	#$7fff,(_custom+intena)
		lea	(_custom),a6			;A6 = _custom
		move.w	(dmaconr,a6),(sg_olddmacon,a5)
		move.w	#$7fff,(dmacon,a6)
		bsr	_sg_initscr
		lea	(_sg_int68),a0
		move.l	$68,(sg_old68,a5)
		move.l	a0,$68
		lea	(_sg_int6c),a0
		move.l	$6c,(sg_old6c,a5)
		move.l	a0,$6c
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB|INTF_PORTS,(intena,a6)
		tst.b	(ciaicr+_ciaa)			;clear all intreq
		move.w	#INTF_VERTB|INTF_PORTS,(intreq,a6)
		bsr	_sg_waitvb
		move.w	#$1200,(bplcon0,a6)
		clr.w	(bpl1mod,a6)
		move.l	#$00000eee,(color,a6)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER,(dmacon,a6)
		tst.l	d1
		beq	_sg_save_in
		bra	_sg_load_in

;--------------------------------

_sg_restore	bsr	_sg_clrscr
		move.b	(sg_success,a5),d0
		ext.w	d0
		move.w	d0,a0				;a0 = success
		bsr	_sg_waitvb
		move.w	#$7fff,(intena,a6)
		move.w	#$7fff,(dmacon,a6)
		move.l	(sg_old68,a5),$68
		move.l	(sg_old6c,a5),$6c
		move.w	#$7fff,(intreq,a6)
		move.w	(sg_oldintena,a5),d0
		bset	#15,d0				;d0 = intena
		move.w	(sg_olddmacon,a5),d1
		bset	#15,d1				;d1 = dmacon
		unlk	a5
		movem.l	(a7)+,d2-d7/a2-a6
		move.w	d0,(_custom+intena)
		bsr	_sg_waitvb
		move.w	d1,(_custom+dmacon)
		move.l	a0,d0				;success
		rts

;--------------------------------

_sg_int68	movem.l	d0-d1,-(a7)
		btst	#CIAICRB_SP,(ciaicr+_ciaa)	;check int reason
		beq	.int2_exit
		move.b	(ciasdr+_ciaa),d0		;read code
		clr.b	(ciasdr+_ciaa)			;output LOW (handshake)
		or.b	#CIACRAF_SPMODE,(ciacra+_ciaa)	;to output
		not.b	d0
		ror.b	#1,d0
		cmp.b	(_keyexit),d0
		beq	_exit
		move.b	d0,(sg_key,a5)
		moveq	#3-1,d1				;wait because handshake min 75 탎
.int2_w1	move.b	(vhposr,a6),d0
.int2_w2	cmp.b	(vhposr,a6),d0			;one line is 63.5 탎
		beq	.int2_w2
		dbf	d1,.int2_w1			;(min=127탎 max=190.5탎)
		and.b	#~(CIACRAF_SPMODE),(ciacra+_ciaa)	;to input
.int2_exit	move.w	#INTF_PORTS,(intreq,a6)
		movem.l	(a7)+,d0-d1
		rte

;--------------------------------

_sg_int6c	move.l	(sg_screen,a5),(bplpt,a6)
		tst.b	(sg_c_on,a5)
		beq	.1
		movem.l	d0-d2,-(a7)
		move.w	(sg_c_x,a5),d0
		move.w	(sg_c_y,a5),d1
		move.w	#' ',d2
		bchg	#0,(sg_c_on,a5)
		beq	.2
		move.w	#'_',d2
.2		bsr	_pc
		movem.l	(a7)+,d0-d2
.1		move.w	#INTF_VERTB,(intreq,a6)
		rte

;--------------------------------

_sg_waitvb	waitvb
		rts

;--------------------------------
; draw rectangle
; IN:	d0 = word x start
;	d1 = word y start
;	d2 = word x stop
;	d3 = word y stop
; OUT:	-

_sg_rect	bsr	_sg_xline
		exg	d1,d3
		bsr	_sg_xline
		exg	d1,d2
		exg	d1,d3
		bsr	_sg_yline
		exg	d0,d3
		bra	_sg_yline

;--------------------------------
; line in x axis
; IN:	d0 = word x start
;	d1 = word y start
;	d2 = word x stop
; OUT:	-

_sg_xline	movem.l	d0/d2,-(a7)
		cmp.w	d0,d2
		beq	.end
		bhi	.in
		exg	d0,d2
		bra	.in
.next		addq.w	#1,d0
.in		bsr	_sg_pset
		cmp.w	d0,d2
		bne	.next
.end		movem.l	(a7)+,d0/d2
		rts

;--------------------------------
; line in y axis
; IN:	d0 = word x start
;	d1 = word y start
;	d2 = word y stop
; OUT:	-

_sg_yline	movem.l	d1/d2,-(a7)
		cmp.w	d1,d2
		beq	.end
		bhi	.in
		exg	d1,d2
		bra	.in
.next		addq.w	#1,d1
.in		bsr	_sg_pset
		cmp.w	d1,d2
		bne	.next
.end		movem.l	(a7)+,d1/d2
		rts

;--------------------------------
; set a pixel
; IN:	d0 = word x start
;	d1 = word y start
; OUT:	-

_sg_pset	move.l	d1,-(a7)
		bsr	_getscrptr
		move.w	d0,d1
		lsr.w	#3,d1
		add.w	d1,a0
		moveq	#7,d1
		and.w	d0,d1
		neg.w	d1
		addq.w	#7,d1
		bset	d1,(a0)
		move.l	(a7)+,d1
		rts

;--------------------------------
; IN:	d1 = word y start
; OUT:	a0 = ptr

_getscrptr	move.l	(sg_screen,a5),a0
		mulu	#LINE,d1
		add.l	d1,a0
		rts
		
;--------------------------------
; print string centered
; IN:	d1 = word y
;	a0 = cptr string
; OUT:	d0 = word new x

_psc		move.l	a0,-(a7)
		moveq	#0,d0
.count		tst.b	(a0)+
		beq	.1
		subq.w	#CHARWIDTH,d0
		bra	.count
.1		asr.w	#1,d0
		add.w	#LINE*4,d0
		move.l	(a7)+,a0
		bra	_ps

;--------------------------------
; print string
; IN:	d0 = word x
;	d1 = word y
;	a0 = cptr string
; OUT:	d0 = word new x

_ps		movem.l	d2,-(a7)
		moveq	#0,d2
		bra	.in
.next		bsr	_pc
		add.w	#CHARWIDTH,d0
.in		move.b	(a0)+,d2
		bne	.next
		movem.l	(a7)+,d2
		rts

;--------------------------------
; print char
; IN:	d0 = word x
;	d1 = word y
;	d2 = char

_pc		movem.l	d0-d5/a0-a1,-(a7)
		bsr	_getscrptr
		sub.w	#32,d2
		mulu	#CHARWIDTH,d2
		lea	(_font),a1
		moveq	#CHARHEIGHT-1,d3
.cp
	IFD _68020_
		bfextu	(a1){d2:CHARWIDTH},d1
		bfins	d1,(a0){d0:CHARWIDTH}
	ELSE
		move.l	d2,d1
		lsr.l	#4,d1				;words
		add.l	d1,d1				;bytes down rounded to word
		move.l	(a1,d1.l),d1
		move.l	d2,d4
		and.w	#%1111,d4
		lsl.l	d4,d1
		and.l	#$ffffffff<<(32-CHARWIDTH),d1
		move.l	#$ffffffff>>CHARWIDTH,d5
		move.l	d0,d4
		and.w	#%1111,d4
		lsr.l	d4,d1
		ror.l	d4,d5
		move.l	d0,d4
		lsr.l	#4,d4				;words
		add.l	d4,d4				;bytes down rounded to word
		and.l	d5,(a0,d4.l)
		or.l	d1,(a0,d4.l)
	ENDC
		add.l	#(_font_-_font)*8/CHARHEIGHT,d2
		add.l	#LINE*8,d0
		dbf	d3,.cp
		movem.l	(a7)+,d0-d5/a0-a1
		rts

_font		INCBIN	pics/pic_font_5x6_br.bin
_font_

;--------------------------------

_sg_name	dc.b	"savegame",0
_info1		dc.b	"special multiple savegame support",0
_info2		dc.b	"written by wepl in spring 1998",0
_esc		dc.b	"press esc to cancel",0
_save		dc.b	">>> save a game <<<",0
_saveselect	dc.b	"select a save position using the keyboard '1' - '9'",0
_saveinsert	dc.b	"    type in a description for this save position    ",0
_saveconfirm	dc.b	"        confirm this save operation (return)        ",0
_load		dc.b	">>> load a game <<<",0
_loadselect	dc.b	"select a load position using the keyboard '1' - '9'",0
_loadconfirm	dc.b	"        confirm this load operation (return)        ",0
_loadno1	dc.b	"sorry there is currently no valid savegame to load",0
_loadno2	dc.b	"press any key to continue",0

_keytrans	dc.b	0,"1234567890",0,0,"0",0,0
		dc.b	"qwertyuiop",0,0,0,"123"
		dc.b	"asdfghjkl",0,0,0,0,"456"
		dc.b	0,"zxcvbnm,.-",0,0,"789"
		dc.b	" ",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		dc.b	"123456789",0,0,0,0,0,0,0
		ds.b	16
		ds.b	16

