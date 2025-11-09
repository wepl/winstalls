;*---------------------------------------------------------------------------
;  :Program.	emul60.asm
;  :Contents.	test WHDLoad's emulation of unsupported interger instructions on 68060
;  :Author.	Wepl
;  :History.	09.11.25 imported to winstalls
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
 BITDEF AF,68060,7

	IFD BARFLY
	;OUTPUT	"wart:.debug/emul60.slave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	ELSE
QUAD	MACRO
	CNOP	0,16
	ENDM
	ENDC

	MC68040
	
	STRUCTURE globals,$400
		LONG	_resload

;======================================================================

	IFEQ 0

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_NoDivZero	;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	$58			;ws_keydebug = F9
		dc.b	$59			;ws_keyexit = F10
EXPMEMLEN = $10000
_expmem		dc.l	EXPMEMLEN		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Test Slave",0
_copy		dc.b	"Wepl",0
_info		dc.b	"done by Wepl "
	INCBIN	".date"
		dc.b	0
	EVEN

	ELSE

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	1			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache

	ENDC

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(_resload)		;save for later use
	IFD EXPMEMLEN
		move.l	(_expmem),a7
		add.l	#EXPMEMLEN-$200,a7	;because hrtmon
	ENDC

	;check div64

_1		moveq	#1,d7
		move.l	#$10000,d1
		move.l	#$1,d2
		divs.l	#$100,d1:d2
		move	ccr,d0
		cmp.w	#2,d0		;v
		bne	.i
		cmp.l	#$10000,d1
		bne	.i
		cmp.l	#$1,d2
		beq	.o
.i		illegal
.o

_2		moveq	#2,d7
		move.l	#$1,d1
		move.l	#$1,d2
		divs.l	#$100,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#1,d1
		bne	.i
		cmp.l	#$1000000,d2
		beq	.o
.i		illegal
.o

_3		moveq	#3,d7
		move.l	#$1,d1
		move.l	#$23456789,d2
		divs.l	#$345,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#$90,d1
		bne	.i
		cmp.l	#$591625,d2
		beq	.o
.i		illegal
.o

_4		moveq	#4,d7
		move.l	#$789abcde,d1
		move.l	#$f1234567,d2
		divs.l	#$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#2,d0		;v
		bne	.i
		cmp.l	#$789abcde,d1
		bne	.i
		cmp.l	#$f1234567,d2
		beq	.o
.i		illegal
.o

_5		moveq	#5,d7
		move.l	#$389abcde,d1
		move.l	#$f1234567,d2
		divs.l	#$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#$740bf8e6,d1
		bne	.i
		cmp.l	#$7718fc8f,d2
		beq	.o
.i		illegal
.o

_6		moveq	#6,d7
		move.l	#$389abcde,d1
		move.l	#$f1234567,d2
		divs.l	#-$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#%1000,d0	;n
		bne	.i
		cmp.l	#$740bf8e6,d1
		bne	.i
		cmp.l	#-$7718fc8f,d2
		beq	.o
.i		illegal
.o

_7		moveq	#7,d7
		move.l	#$389abcde,d1
		move.l	#$f1234567,d2
		move	#0,ccr
		negx.l	d2
		negx.l	d1
		move	#0,ccr
		divs.l	#-$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#%00,d0
		bne	.i
		cmp.l	#-$740bf8e6,d1
		bne	.i
		cmp.l	#$7718fc8f,d2
		beq	.o
.i		illegal
.o

_8		moveq	#8,d7
		move.l	#$389abcde,d1
		move.l	#$f1234567,d2
		move	#0,ccr
		negx.l	d2
		negx.l	d1
		move	#0,ccr
		divs.l	#$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#%1000,d0	;n
		bne	.i
		cmp.l	#-$740bf8e6,d1
		bne	.i
		cmp.l	#-$7718fc8f,d2
		beq	.o
.i		illegal
.o

_9		moveq	#9,d7
		move.l	#0,d1
		move.l	#0,d2
		divs.l	#$79abcdef,d1:d2
		move	ccr,d0
		cmp.w	#%100,d0	;z
		bne	.i
		cmp.l	#0,d1
		bne	.i
		cmp.l	#0,d2
		beq	.o
.i		illegal
.o

_10		moveq	#10,d7
		move.l	#0,d1
		move.l	#$222222,d2
		divs.l	#$22222,d1:d2
		move	ccr,d0
		cmp.w	#%00,d0	
		bne	.i
		cmp.l	#2,d1
		bne	.i
		cmp.l	#16,d2
		beq	.o
.i		illegal
.o

_51		moveq	#51,d7
		move.l	#$10000,d1
		move.l	#$1,d2
		divu.l	#$100,d1:d2
		move	ccr,d0
		cmp.w	#2,d0		;v
		bne	.i
		cmp.l	#$10000,d1
		bne	.i
		cmp.l	#$1,d2
		beq	.o
.i		illegal
.o

_52		moveq	#52,d7
		move.l	#$1,d1
		move.l	#$1,d2
		divu.l	#$100,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#1,d1
		bne	.i
		cmp.l	#$1000000,d2
		beq	.o
.i		illegal
.o

_53		moveq	#53,d7
		move.l	#$1,d1
		move.l	#$23456789,d2
		divu.l	#$345,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#$90,d1
		bne	.i
		cmp.l	#$591625,d2
		beq	.o
.i		illegal
.o

_54		moveq	#54,d7
		move.l	#$fedcba98,d1
		move.l	#$76543210,d2
		divu.l	#$ffff7777,d1:d2
		move	ccr,d0
		cmp.w	#%1000,d0	;n
		bne	.i
		cmp.l	#$6613fbc6,d1
		bne	.i
		cmp.l	#$fedd4286,d2
		beq	.o
.i		illegal
.o

_60		moveq	#60,d7
		move.l	#0,d1
		move.l	#$222222,d2
		divu.l	#$22222,d1:d2
		move	ccr,d0
		cmp.w	#%00,d0
		bne	.i
		cmp.l	#2,d1
		bne	.i
		cmp.l	#16,d2
		beq	.o
.i		illegal
.o

_99		moveq	#99,d7
		move.l	#$1,d1
		move.l	#$1,d2
		moveq	#0,d3
		divs.l	d3,d1:d2
		move	ccr,d0
		cmp.w	#0,d0
		bne	.i
		cmp.l	#1,d1
		bne	.i
		cmp.l	#1,d2
		beq	.o
.i		illegal
.o

		lea	(_ciaa),a4		;A4 = ciaa
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = custom

SCREEN		= $10000
SCREENWIDTH	= 320
CHARHEIGHT	= 5
CHARWIDTH	= 5

	;clear screen
		lea	(SCREEN),a0
		move.w	#256*320/8/4-1,d0
.cl		clr.l	(a0)+
		dbf	d0,.cl
	;init gfx
		lea	(_copper),a0
		lea	($f000),a1
		move.l	a1,(cop1lc,a6)
.n		move.l	(a0)+,(a1)+
		bpl	.n
		waitvb a6
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER,(dmacon,a6)
	;init timers
		lea	(_tags),a0
		jsr	(resload_Control,a5)
		move.l	(_freq),d0
		divu	#11,d0
		move.b	d0,(ciatalo,a4)
		lsr.w	#8,d0
		move.b	d0,(ciatahi,a4)
		move.b	#CIACRAF_RUNMODE,(ciacra,a4)
		bset	#CIACRAB_LOAD,(ciacra,a4)
		move.b	#$7f,(ciaicr,a4)
		move.b	#CIAICRF_SETCLR|CIAICRF_TA,(ciaicr,a4)
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena,a6)
		tst.b	(ciaicr,a4)
		move.w	#INTF_PORTS,(intreq,a6)

	;calculation start
CALC_S	MACRO
		move	#$2700,sr
		movem.l	d0-a7,$100
		movem.l	(_defregs),d0-a5
		lea	(_defregs),a0		;a0 = valid fast mem
		move.l	a0,a1
		lea	(_cnt),a6
		clr.l	(a6)			;(a6) = counter
		pea	\1
		move.l	(a7)+,$68
		tst.b	(ciaicr+_ciaa)
		tst.b	(ciaicr+_ciaa)
		move.w	#INTF_PORTS,(intreq+_custom)
		move	#$2000,sr
		bset	#CIACRAB_START,(ciacra+_ciaa)
	QUAD
	ENDM

	;calculation end
CALC_E	MACRO
		btst	#CIAICRB_TA,(ciaicr+_ciaa)
		bne	.1\@
		move.w	#INTF_PORTS,(intreq+_custom)
		rte
.1\@		move	#$2700,sr
		movem.l	$100,d0-a7
		move.l	(_cnt),d2
		bsr	_pi
	ENDM

	QUAD
_again
		move.l	#WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	;	move.l	#WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SB,d0
		move.l	d0,d1
		jsr	(resload_SetCPU,a5)
		moveq	#0,d0
		moveq	#0,d1
		jsr	(resload_SetCPU,a5)
		move.l	d0,d2

		moveq	#0,d0
		moveq	#0,d1
		lea	_top,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#6,d1
		lea	_top2,a0
		bsr	_ps
		bsr	_pi
		lea	_top3,a0
		bsr	_ps
		move.l	_freq,d2
		bsr	_pi
		lea	_top4,a0
		bsr	_ps
		lea	(_defregs),a0
		move.l	a0,d2
		bsr	_pi

		moveq	#0,d0			;x
		addq.w	#8,d1			;y
		lea	_movep1,a0
		bsr	_ps
		CALC_S	.q1
.l1		dc.l	$01880000		;movep.w d0,(0,a0)
		addq.l	#1,(a6)
		bra	.l1
.q1		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_movep2,a0
		bsr	_ps
		CALC_S	.q2
.l2		dc.l	$01c80000		;movep.l d0,(0,a0)
		addq.l	#1,(a6)
		bra	.l2
.q2		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_movep3,a0
		bsr	_ps
		CALC_S	.q3
.l3		dc.l	$01080000		;movep.w (0,a0),d0
		addq.l	#1,(a6)
		bra	.l3
.q3		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_movep4,a0
		bsr	_ps
		CALC_S	.q4
.l4		dc.l	$01480000		;movep.l (0,a0),d0
		addq.l	#1,(a6)
		bra	.l4
.q4		CALC_E

		moveq	#0,d0			;x
		addq.w	#8,d1			;y
		lea	_cmp1,a0
		bsr	_ps
		CALC_S	.qc1
.lc1		cmp2.b	(a1),d0
		addq.l	#1,(a6)
		bra	.lc1
.qc1		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp2,a0
		bsr	_ps
		CALC_S	.qc2
.lc2		cmp2.w	(a0),d1
		addq.l	#1,(a6)
		bra	.lc2
.qc2		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp3,a0
		bsr	_ps
		CALC_S	.qc3
.lc3		cmp2.l	(a0),d1
		addq.l	#1,(a6)
		bra	.lc3
.qc3		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp4,a0
		bsr	_ps
		CALC_S	.qc4
.lc4		cmp2.l	(2,a1),d1
		addq.l	#1,(a6)
		bra	.lc4
.qc4		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp5,a0
		bsr	_ps
		CALC_S	.qc5
.lc5		cmp2.l	(2,a1,d0.l),d1
		addq.l	#1,(a6)
		bra	.lc5
.qc5		CALC_E
	ifeq 1
		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp6,a0
		bsr	_ps
		CALC_S	.qc6
.lc6		cmp2.l	(-$d1d1d1d1.l,a0,d1.l),d2
		addq.l	#1,(a6)
		bra	.lc6
.qc6		CALC_E
	endc
		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp7,a0
		bsr	_ps
		CALC_S	.qc7
.lc7		cmp2.l	(_defregs,pc),d1
	;dc.w	$04f8,0,0
	;dc.w	$06f8,0,0
		addq.l	#1,(a6)
		bra	.lc7
.qc7		CALC_E
	ifeq 1
		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_cmp9,a0
		bsr	_ps
		CALC_S	.qc9
.lc9		cmp2.l	(_defregs.l,pc,d0.l),d1
		addq.l	#1,(a6)
		bra	.lc9
.qc9		CALC_E
	endc

		moveq	#0,d0			;x
		addq.w	#8,d1			;y
		lea	_mul1,a0
		bsr	_ps
		CALC_S	.q6
.l6		muls.l	d2,d3:d4
		addq.l	#1,(a6)
		bra	.l6
.q6		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_mul2,a0
		bsr	_ps
		CALC_S	.q7
.l7		muls.l	d2,d3
		addq.l	#1,(a6)
		bra	.l7
.q7		CALC_E

		moveq	#0,d0			;x
		addq.w	#6,d1			;y
		lea	_mul3,a0
		bsr	_ps
		CALC_S	.q8
.l8		muls.l	d2,d3:d4
		addq.l	#1,(a6)
		bra	.l8
.q8		CALC_E

		moveq	#0,d0
		addq.l	#8,d1
		lea	_quit,a0
		bsr	_ps

		btst	#6,$bfe001
		bne	_again

		lea	(SCREEN),a0
		lea	(_iff),a1
		lea	(_iff_),a2
.cpy		move.w	-(a2),-(a0)
		cmp.l	a1,a2
		bne	.cpy
		move.l	a0,a1
		lea	(_pic),a0
		move.l	#(_iff_-_iff)+320*256/8,d0
		jsr	(resload_SaveFile,a5)
		
		bra	_exit

	CNOP 0,4
_cnt		dc.l	0
_defregs	dc.l	$2,$d1d1d1d1,$d2d2d2d2,$d3d3d3d3,$d4d4d4d4,$d5d5d5d5,$d6d6d6d6,$d7d7d7d7
		dc.l	$a0a0a0a0,$a1a1a1a1,$a2a2a2a2,$a3a3a3a3,$a4a4a4a4,$a5a5a5a5
_tags		dc.l	WHDLTAG_ECLOCKFREQ_GET
_freq		dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attn		dc.l	0
		dc.l	TAG_DONE
_iff		dc.l	"FORM",4+8+$14+8+6+8+320*256/8,"ILBM"
		dc.l	"BMHD",$14
		dc.w	320,256,0,0
		dc.b	1,0,0,0
		dc.w	0
		dc.b	10,11
		dc.w	320,256
		dc.l	"CMAP",6
		dc.b	0,0,0,255,255,255
		dc.l	"BODY",320*256/8
_iff_
_pic		dc.b	"benchmark.ilbm",0
_sp		dc.b	" ",0

_movep1		dc.b	"movep.w d0,(d16,a0)     ",0
_movep2		dc.b	"movep.l d0,(d16,a0)     ",0
_movep3		dc.b	"movep.w (d16,a0),d0     ",0
_movep4		dc.b	"movep.l (d16,a0),d0     ",0
_cmp1		dc.b	"cmp2.b  (a1),d1         ",0
_cmp2		dc.b	"cmp2.w  (a0),d1         ",0
_cmp3		dc.b	"cmp2.l  (a0),d1         ",0
_cmp4		dc.b	"cmp2.l  (2,a0),d1       ",0
_cmp5		dc.b	"cmp2.l  (2,a0,d0.l),d1  ",0
_cmp6		dc.b	"cmp2.l  (-$d1d1d1d1,a0,d1.l),d2 ",0
_cmp7		dc.b	"cmp2.l  (d16,pc),d1     ",0
_cmp9		dc.b	"cmp2.l  (d16,pc,d0.l),d1 ",0
_mul1		dc.b	"muls.l  d2,d3:d4        ",0
_mul2		dc.b	"muls.l  d2,d3           ",0
_mul3		dc.b	"mulu.l  d2,d3:d4        ",0

_cacr		dc.b	"cacr=",0
_top		dc.b	">>speed<< - amount of executed instructions per 1/11 second",0
_top2		dc.b	"CPUFlags=",0
_top3		dc.b	"  Eclockfrequency=",0
_top4		dc.b	"  fast at ",0
_quit		dc.b	"hold lmb to quit and save pic  v1.3  wepl 17.09.1999",0
	EVEN

;--------------------------------
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

; IN:	d0 = word x
;	d1 = word y
;	d2 = long value
; OUT:	d0 = word new x

_pi		movem.l	d2-d4,-(a7)
		moveq	#7,d4
		move.l	d2,d3
.n		rol.l	#4,d3
		move.b	d3,d2
		and.w	#$f,d2
		add.w	#"0",d2
		cmp.w	#"9",d2
		bls	.g
		add.w	#"a"-"9"-1,d2
.g		bsr	_pc
		add.w	#CHARWIDTH,d0
		dbf	d4,.n
		movem.l	(a7)+,d2-d4
		rts

; IN:	d0 = word x
;	d1 = word y
;	d2 = byte digit (0..15)

_pc		movem.l	d0-d3/a0-a1,-(a7)
		lea	(SCREEN),a0
		mulu	#SCREENWIDTH/8,d1
		add.l	d1,a0
		sub.w	#32,d2
		mulu	#CHARWIDTH,d2
		lea	(_font),a1
		moveq	#CHARHEIGHT-1,d3
.cp		bfextu	(a1){d2:CHARWIDTH},d1
		bfins	d1,(a0){d0:CHARWIDTH}
		add.l	#(_font_-_font)*8/CHARHEIGHT,d2
		add.l	#SCREENWIDTH,d0
		dbf	d3,.cp
		movem.l	(a7)+,d0-d3/a0-a1
		rts

_copper		dc.w	diwstop,$29c1
		dc.w	bplcon0,$1200
		dc.w	bplpt+0,SCREEN>>16
		dc.w	bplpt+2,SCREEN&$ffff
		dc.w	color+0,0
		dc.w	color+2,$ddd
		dc.l	-2

_font		INCBIN	pic_font_5x6_br.bin
_font_

;======================================================================

_exit		move.l	#TDREASON_OK,-(a7)
		bra	_end
_debug		move	sr,-(a7)
		clr.w	-(a7)
		clr.l	-(a7)
		move.l	#TDREASON_DEBUG,-(a7)
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	END
