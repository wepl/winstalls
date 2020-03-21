;*---------------------------------------------------------------------------
;  :Program.	speed.asm
;  :Contents.	Slave to benchmark the memory speed under different cpu/mmu
;		setups, upper half of the screen shows performance with test
;		code located in Chip memory, lower half code in ExpMem (Fast)
;  :Author.	Wepl
;  :Version.	$Id: speed.asm 1.10 2020/03/21 00:51:09 wepl Exp wepl $
;  :History.	xx.xx.xx started
;		12.12.00 cleanup for public release
;		20.02.01 slave is also cacheable, more clear results with NoMMU
;		17.02.03 WHDLTAG_Private5 added
;		13.04.11 made 68000 compatible
;		14.03.20 using VSNPrintF, requires WHDLoad v18
;			 options added to control repeat etc.
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

 BITDEF AF,68060,7

	OUTPUT	"ram:speed.slave"

	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	18
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug
		dc.b	$59			;ws_keyexit = F10
EXPMEMLEN = $3000
_expmem		dc.l	EXPMEMLEN		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Memory Speed Benchmark Slave",0
_copy		dc.b	"2000-2003,2011,2020 Wepl",0
_info		dc.b	"done by Wepl "
	DOSCMD	"WDate  >T:date"
	INCBIN	"T:date"
		dc.b	0
_config		dc.b	"C1:B:Run in Usermode;"
		dc.b	"C2:L:Test period:1/11s,1s,2s,10s;"
		dc.b	"C3:B:Only Custom Registers",0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_ciaa),a4		;A4 = ciaa
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = custom
		move.l	(_expmem),a7
		add.l	#EXPMEMLEN-$200,a7	;because hrtmon
		lea	(_ssp),a0
		move.l	a7,(a0)

SCREENWIDTH	= 320
SCREENHEIGHT	= 279
CHARHEIGHT	= 5
CHARWIDTH	= 5

MEMRCHIP	= $4000
MEMCOPPER	= $e000
MEMCHIP		= $f000
MEMSCREEN	= $10000

nc=WCPUF_Slave_NCS|WCPUF_Base_NCS|WCPUF_Exp_NCS
ic=WCPUF_Slave_WT|WCPUF_Base_WT|WCPUF_Exp_WT|WCPUF_IC
bc=ic|WCPUF_BC|WCPUF_SS
wt=bc|WCPUF_DC
cb=WCPUF_Slave_CB|WCPUF_Base_CB|WCPUF_Exp_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS
sb=cb|WCPUF_SB|WCPUF_NWA

	;clear screen
		lea	(MEMSCREEN),a0
		move.w	#SCREENHEIGHT*SCREENWIDTH/8/4-1,d0
.cl		clr.l	(a0)+
		dbf	d0,.cl
	;init gfx
		lea	(_copper),a0
		lea	(MEMCOPPER),a1
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
	;set extra loops
		move.l	_custom2,d0
		beq	.nc2
		moveq	#11-1,d1
		subq.l	#1,d0
		beq	.sc2
		moveq	#22-1,d1
		subq.l	#1,d0
		beq	.sc2
		moveq	#110-1,d1
		subq.l	#1,d0
		bne	.nc2
.sc2		lea	_loops,a0
		move.l	d1,(a0)
.nc2
	;copy code to chip
		lea	_rchip,a0
		lea	_stuffend,a1
		lea	MEMRCHIP,a2
.cp		move.l	(a0)+,(a2)+
		cmp.l	a0,a1
		bhi	.cp
	;copy code to fast
		lea	_rfast,a0
		lea	_stuffend,a1
		move.l	(_expmem),a2
		add.l	#16,a2
.cp2		move.l	(a0)+,(a2)+
		cmp.l	a0,a1
		bhi	.cp2
	;set expmem/slave
		lea	(_var),a2			;A2 = slave
		move.l	(_expmem),a3			;A3 = expmem

	;print screen text
		moveq	#0,d0
		move.l	#SCREENHEIGHT-CHARHEIGHT,d1
		lea	_quit,a0
		bsr	_ps

		moveq	#0,d0
		moveq	#1,d1
		move.l	_loops,-(a7)
		addq.l	#1,(a7)
		move.l	a7,a1
		lea	_top1,a0
		bsr	_ps
		addq.l	#4,a7

		moveq	#0,d0
		add.l	#CHARHEIGHT+1,d1
		lea	_top2,a0
		move.l	_build,-(a7)
		move.l	_rev,-(a7)
		move.l	_ver,-(a7)
		move.l	_freq,-(a7)
		move.l	_attn,-(a7)
		move.l	a7,a1
		bsr	_ps
		add.w	#5*4,a7

		moveq	#0,d0
		add.l	#CHARHEIGHT+1,d1
		lea	_top3,a0
		move.l	a2,-(a7)
		move.l	a3,-(a7)
		pea	MEMCHIP
		move.l	a7,a1
		bsr	_ps
		add.w	#3*4,a7

		move.l	#7*CHARWIDTH,d0
		add.w	#7+CHARHEIGHT+1,d1
		lea	_leg2,a0
		bsr	_ps
		move.l	#9*CHARWIDTH,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg3,a0
		bsr	_ps
		move.l	#10*CHARWIDTH,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg4,a0
		bsr	_ps

		moveq	#13*CHARWIDTH,d0
		sub.l	#3*(CHARHEIGHT+1),d1
catcpu	MACRO
		move.l	#\1,d3
		lea	\2,a0
		bsr	_catcpu
	ENDM
		catcpu	nc,_nc
		catcpu	ic,_ic
		catcpu	bc,_bc
		catcpu	wt,_wt
		catcpu	cb,_cb
		catcpu	sb,_sb

	;switch to usermode
		move.l	_custom1,d0
		beq	.nc1
		lea	(-$200,a7),a0
		move	a0,usp
		move	#0,sr
.nc1
	;call routines
.again		moveq	#39,d1
		jsr	MEMRCHIP
		move.l	(_expmem),a0
		jsr	(16,a0)
		btst	#6,$bfe001
		bne	.again

	;save picture
		lea	(MEMSCREEN),a0
		lea	(_iff),a1
		lea	(_iff_),a2
.cpy		move.w	-(a2),-(a0)
		cmp.l	a1,a2
		bne	.cpy
		move.l	a0,a1
		lea	(_pic),a0
		move.l	#(_iff_-_iff)+SCREENWIDTH*SCREENHEIGHT/8,d0
		jsr	(resload_SaveFile,a5)
	;end
		pea	TDREASON_OK
		jmp	(resload_Abort,a5)

_catcpu		addq	#2,d0
		bsr	_ps
		sub.w	#CHARWIDTH*8,d0
		addq.w	#CHARHEIGHT+1,d1
		bsr	_setcpu
		movem.l	d0-d1/a0-a1,-(a7)
		moveq	#0,d0
		moveq	#0,d1
		jsr	(resload_SetCPU,a5)
		move.l	d0,d2
		movem.l	(a7)+,d0-d1/a0-a1
		bsr	_pi
		move.w	_attn+2,d7
		btst	#AFB_68020,d7
		beq	.q
	MC68020
		movec	cacr,d2
		sub.w	#CHARWIDTH*8,d0
		addq.w	#CHARHEIGHT+1,d1
		bsr	_pi
		sub.w	#CHARHEIGHT+1,d1
		btst	#AFB_68060,d7
		beq	.q
	MC68060
		movec	pcr,d2
		sub.w	#CHARWIDTH*8,d0
		add.w	#(CHARHEIGHT+1)*2,d1
		bsr	_pi
		sub.w	#(CHARHEIGHT+1)*2,d1
.q		sub.w	#CHARHEIGHT+1,d1
		rts
	MC68000

CALC_S	MACRO
		move.l	_loops,d4
		moveq	#0,d2			;counter
		lea	\2,a0			;test address
		pea	\1			;stop address
		move.l	(a7)+,$68
		move	sr,d5			;D5 = saved SR
		move.l	a7,d6			;D6 = saved SP
	CNOP 0,2
		bset	#CIACRAB_START,(ciacra,a4)
	ENDM

CALC_E	MACRO
		btst	#CIAICRB_TA,(ciaicr,a4)
		beq	_badint
		subq.w	#1,d4
		bmi	.quit\@
		move.w	#INTF_PORTS,(intreq,a6)
		tst.w	(dmaconr,a6)		;delay for intack
		bset	#CIACRAB_START,(ciacra,a4)
		rte
.quit\@		move.w	#INTF_PORTS,(intreq,a6)
		tst.w	(dmaconr,a6)		;delay for intack
		btst	#13,d5			;supervisor
		bne	.s\@
		move.l	(_ssp),a7
.s\@		move	d5,sr
		move.l	d6,a7
		bsr	_pi
		addq	#2,d0
	ENDM

CALCRR	MACRO
		btst	#6,$bfe001
		beq	.q\@
		move.l	#\3,d3
		bsr	_setcpu
		CALC_S	.go\@,\1
.loop\@		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		move.\2	(a0),d7
		addq.l	#8,d2
		bra	.loop\@
.go\@		CALC_E
.q\@
	ENDM

CALCR	MACRO
		moveq	#0,d0
		addq.w	#6,d1
		lea	\1,a0
		bsr	_ps
		addq	#2,d0
		lea	\3,a0
		bsr	_ps
		addq	#2,d0
		lea	_read,a0
		bsr	_ps
		addq	#2,d0
		CALCRR	\2,\4,nc
		CALCRR	\2,\4,ic
		CALCRR	\2,\4,bc
		CALCRR	\2,\4,wt
		CALCRR	\2,\4,cb
		CALCRR	\2,\4,sb
	ENDM

CALCWW	MACRO
		btst	#6,$bfe001
		beq	.q\@
		move.l	#\3,d3
		bsr	_setcpu
		CALC_S	.go\@,\1
.loop\@		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		move.\2	d7,(a0)
		addq.l	#8,d2
		bra	.loop\@
.go\@		CALC_E
.q\@
	ENDM

CALCW	MACRO
		moveq	#0,d0
		addq.w	#6,d1
		lea	\1,a0
		bsr	_ps
		addq	#2,d0
		lea	\3,a0
		bsr	_ps
		addq	#2,d0
		lea	_writ,a0
		bsr	_ps
		addq	#2,d0
		CALCWW	\2,\4,nc
		CALCWW	\2,\4,ic
		CALCWW	\2,\4,bc
		CALCWW	\2,\4,wt
		CALCWW	\2,\4,cb
		CALCWW	\2,\4,sb
	ENDM

;************** following code is copied to chip/fast

	CNOP 0,4
_rchip		move.l	_custom3,d3
		bne	.nocia
		CALCR	_cia,$bfe001,_byte,b
		CALCW	_cia,$bfec01,_byte,b

		addq	#2,d1
.nocia
		CALCR	_cust,vposr(a6),_byte,b
		CALCR	_cust,vposr(a6),_word,w
		CALCR	_cust,vposr(a6),_long,l
		CALCW	_cust,$184(a6),_word,w
		CALCW	_cust,$184(a6),_long,l
		move.l	_custom3,d3
		bne	.rts

		addq	#2,d1
		CALCR	_chip,MEMCHIP,_byte,b
		CALCR	_chip,MEMCHIP,_word,w
		CALCR	_chip,MEMCHIP,_long,l
		CALCW	_chip,MEMCHIP,_byte,b
		CALCW	_chip,MEMCHIP,_word,w
		CALCW	_chip,MEMCHIP,_long,l

		addq	#2,d1
		CALCR	_exp,(a3),_byte,b
		CALCR	_exp,(a3),_word,w
		CALCR	_exp,(a3),_long,l
		CALCW	_exp,(a3),_byte,b
		CALCW	_exp,(a3),_word,w
		CALCW	_exp,(a3),_long,l

		addq	#2,d1
		CALCR	_slv,(a2),_byte,b
		CALCR	_slv,(a2),_word,w
		CALCR	_slv,(a2),_long,l
		CALCW	_slv,(a2),_byte,b
		CALCW	_slv,(a2),_word,w
		CALCW	_slv,(a2),_long,l

.rts		rts

_rfast		move.l	_custom3,d3
		bne	.nocia
		addq	#2,d1
		CALCR	_cia,$bfe001,_byte,b
		CALCW	_cia,$bfec01,_byte,b
.nocia
		addq	#2,d1
		CALCR	_cust,vposr(a6),_word,w
		CALCW	_cust,$184(a6),_word,w
		move.l	_custom3,d3
		bne	.rts

		addq	#2,d1
		CALCR	_chip,MEMCHIP,_word,w
		CALCW	_chip,MEMCHIP,_word,w

		addq	#2,d1
		CALCR	_exp,(a3),_word,w
		CALCW	_exp,(a3),_word,w

		addq	#2,d1
		CALCR	_slv,(a2),_word,w
		CALCW	_slv,(a2),_word,w

.rts		rts

_setcpu		movem.l	d0-d1/a0-a1,-(a7)
		move.l	d3,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)
		movem.l	(a7)+,d0-d1/a0-a1
		rts

_badint		move.w	#INTF_PORTS,(intreq,a6)
		move.w	#$f00,(color,a6)	;signal unexpected interrupt & delay for intack
		rte

	CNOP 0,4
_ssp		dc.l	0
_loops		dc.l	0
_tags		dc.l	WHDLTAG_ECLOCKFREQ_GET
_freq		dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attn		dc.l	0
		dc.l	WHDLTAG_VERSION_GET
_ver		dc.l	0
		dc.l	WHDLTAG_REVISION_GET
_rev		dc.l	0
		dc.l	WHDLTAG_BUILD_GET
_build		dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_custom3	dc.l	0
		dc.l	WHDLTAG_Private5	;allows free modifications using SetCPU
		dc.l	-1
		dc.l	TAG_DONE
_read		dc.b	"read",0
_writ		dc.b	"writ",0
_byte		dc.b	"byte",0
_word		dc.b	"word",0
_long		dc.b	"long",0
_cia		dc.b	"cia ",0
_cust		dc.b	"cust",0
_exp		dc.b	"exp ",0
_slv		dc.b	"slv ",0
_chip		dc.b	"chip",0
	EVEN

;--------------------------------
; IN:	d0 = word x
;	d1 = word y
;	a0 = cptr string
;	a1 = aptr args
; OUT:	d0 = word new x

_ps		movem.l	d0-d2/a2,-(a7)
		moveq	#100,d0		;buflen
		sub.l	d0,a7
		move.l	a1,a2		;args
		move.l	a0,a1		;fmt
		move.l	a7,a0		;buffer
		jsr	(resload_VSNPrintF,a5)
		movem.l	(100,a7),d0-d1
		move.l	a7,a0
		moveq	#0,d2
		bra	.in
.next		bsr	_pc
		add.w	#CHARWIDTH,d0
.in		move.b	(a0)+,d2
		bne	.next
		add.w	#104,a7
		movem.l	(a7)+,d1-d2/a2
		rts

; IN:	d0 = word x
;	d1 = word y
;	d2 = long value
; OUT:	d0 = word new x

_pi		movem.l	d2-d5,-(a7)
		moveq	#7,d4
		sf	d5
		move.l	d2,d3
.n		rol.l	#4,d3
		move.b	d3,d2
		and.w	#$f,d2
		beq	.0
		st	d5
		cmp.w	#$a,d2
		bhs	.a
		add.w	#"0",d2
		bra	.g

.0		moveq	#"0",d2
		tst.b	d5
		bne	.g
		tst.b	d4		;last?
		beq	.g
		moveq	#" ",d2
		bra	.g

.a		add.w	#"a"-10,d2

.g		bsr	_pc
		add.w	#CHARWIDTH,d0
		dbf	d4,.n
		movem.l	(a7)+,d2-d5
		rts

; IN:	d0 = word x
;	d1 = word y
;	d2 = ascii char

_pc		movem.l	d0-d5/a0-a1,-(a7)
		lea	(MEMSCREEN),a0
		mulu	#SCREENWIDTH/8,d1
		add.l	d1,a0
		sub.w	#32,d2				;starts at $20
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

		moveq	#-1,d5
		lsr.l	#CHARWIDTH,d5
		not.l	d5
		and.l	d5,d1
		not.l	d5

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
		add.l	#SCREENWIDTH,d0
		dbf	d3,.cp
		movem.l	(a7)+,d0-d5/a0-a1
		rts

_font		INCBIN	sources:pics/pic_font_5x6_br.bin
_font_
_stuffend

;************** end of copied code

_copper		dc.w	diwstrt,$1a81
		dc.w	diwstop,$1ac1+((SCREENHEIGHT-256)*$100)
		dc.w	bplcon0,$1200
		dc.w	bplpt+0,MEMSCREEN>>16
		dc.w	bplpt+2,MEMSCREEN&$ffff
		dc.w	bpl1mod,0
		dc.w	color+0,0
		dc.w	color+2,$ddd
		dc.l	-2

_var		dc.l	0

_iff		dc.l	"FORM",4+8+$14+8+6+8+SCREENWIDTH*SCREENHEIGHT/8,"ILBM"
		dc.l	"BMHD",$14
		dc.w	SCREENWIDTH,SCREENHEIGHT,0,0
		dc.b	1,0,0,0
		dc.w	0
		dc.b	10,11
		dc.w	SCREENWIDTH,SCREENHEIGHT
		dc.l	"CMAP",6
		dc.b	0,0,0,255,255,255
		dc.l	"BODY",SCREENWIDTH*SCREENHEIGHT/8
_iff_
_pic		dc.b	"benchmark.ilbm",0
_nc		dc.b	"      nc",0
_ic		dc.b	"      ic",0
_bc		dc.b	"   ss+bc",0
_wt		dc.b	"   dc-wt",0
_cb		dc.b	"   dc-cb",0
_sb		dc.b	"  sb/nwa",0
_leg2		dc.b	"setcpu",0
_leg3		dc.b	"cacr",0
_leg4		dc.b	"pcr",0
_top1		dc.b	">>speed<< - amount of memory accesses per %ld/11 second",0
_top2		dc.b	"AttnFlags=$%lx  Eclock=%ld  whdload=%ld.%ld.%ld",0
_top3		dc.b	"chip(code top)=$%lx  exp(code bottom)=$%lx  slv=$%lx",0
_quit		dc.b	"hold lmb to quit and save pic  v1.11 wepl "
	INCBIN	t:date
		dc.b	0
	EVEN

;======================================================================

	END
