;*---------------------------------------------------------------------------
;  :Program.	speed.asm
;  :Contents.	Slave to benchmark the memory speed under different cpu/mmu
;		setups, upper half of the screen shows performance with test
;		code located in Chip memory, lower half code in ExpMem (Fast)
;  :Author.	Wepl
;  :Version.	$Id: speed.asm 1.5 2001/03/11 23:09:01 jah Exp jah $
;  :History.	xx.xx.xx started
;		12.12.00 cleanup for public release
;		20.02.01 slave is also cacheable, more clear results with NoMMU
;		17.02.03 WHDLTAG_Private5 added
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

	OUTPUT	"wart:.debug/speed.slave"

	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	MC68060

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
		dc.b	0			;ws_keydebug = F9
		dc.b	$59			;ws_keyexit = F10
EXPMEMLEN = $3000
_expmem		dc.l	EXPMEMLEN		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Memory Speed Benchmark Slave",0
_copy		dc.b	"2000-2003 Wepl",0
_info		dc.b	"done by Wepl "
	DOSCMD	"WDate  >T:date"
	INCBIN	"T:date"
		dc.b	0
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

setcpu	MACRO
		movem.l	d0-d1/a0-a1,-(a7)
		move.l	#\1,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)
		movem.l	(a7)+,d0-d1/a0-a1
	ENDM
catcpu	MACRO
		addq	#2,d0
		lea	\2,a0
		bsr	_ps
		sub.w	#CHARWIDTH*8,d0
		addq.w	#CHARHEIGHT+1,d1
		setcpu	\1
		movem.l	d0-d1/a0-a1,-(a7)
		moveq	#0,d0
		moveq	#0,d1
		jsr	(resload_SetCPU,a5)
		move.l	d0,d2
		movem.l	(a7)+,d0-d1/a0-a1
		bsr	_pi
		move.w	_attn+2,d7
		btst	#AFB_68020,d7
		beq	.q\@
		movec	cacr,d2
		sub.w	#CHARWIDTH*8,d0
		addq.w	#CHARHEIGHT+1,d1
		bsr	_pi
		sub.w	#CHARHEIGHT+1,d1
		btst	#AFB_68060,d7
		beq	.q\@
		movec	pcr,d2
		sub.w	#CHARWIDTH*8,d0
		add.w	#(CHARHEIGHT+1)*2,d1
		bsr	_pi
		sub.w	#(CHARHEIGHT+1)*2,d1
.q\@		sub.w	#CHARHEIGHT+1,d1
	ENDM

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
		moveq	#0,d1
		lea	_top,a0
		bsr	_ps

		moveq	#0,d0
		addq.l	#6,d1
		lea	_top2,a0
		bsr	_ps
		move.l	_attn,d2
		bsr	_pi1
		lea	_top3,a0
		bsr	_ps
		move.l	_freq,d2
		bsr	_pi1
		lea	_top5,a0
		bsr	_ps
		move.l	_ver,d2
		bsr	_pi1
		lea	_dot,a0
		bsr	_ps
		move.l	_rev,d2
		bsr	_pi1
		lea	_dot,a0
		bsr	_ps
		move.l	_build,d2
		bsr	_pi1

		moveq	#0,d0
		add.l	#CHARHEIGHT+1,d1
		lea	_chip,a0
		bsr	_ps
		lea	_equ,a0
		bsr	_ps
		move.l	#MEMCHIP,d2
		bsr	_pi1
		add.l	#2*CHARWIDTH,d0
		lea	_exp,a0
		bsr	_ps
		lea	_equ,a0
		bsr	_ps
		move.l	a3,d2
		bsr	_pi1
		add.l	#2*CHARWIDTH,d0
		lea	_slv,a0
		bsr	_ps
		lea	_equ,a0
		bsr	_ps
		move.l	a2,a0
		move.l	a0,d2
		bsr	_pi1

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

CALC_S	MACRO
		moveq	#0,d2
		lea	\2,a0			;test address
		pea	\1
		move.l	(a7)+,$68
		move	sr,d5			;D5 = saved SR
		move.l	a7,d6			;D6 = saved SP
		bset	#CIACRAB_START,(ciacra,a4)
	QUAD
	ENDM

CALC_E	MACRO
.quit0\@	btst	#CIAICRB_TA,(ciaicr,a4)
		bne	(.quit\@)
		move.w	#INTF_PORTS,(intreq,a6)
		rte
.quit\@		move.w	#INTF_PORTS,(intreq,a6)
		btst	#13,d5			;supervisor
		bne	.s\@
		move.l	(_ssp),a7
.s\@		move	d5,sr
		move.l	d6,a7
		bsr	_pi
		addq	#2,d0
	ENDM

CALCRR	MACRO
		setcpu	\3
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
	ENDM

CALCR	MACRO
		btst	#6,$bfe001
		beq	.q\@
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
.q\@
	ENDM

CALCWW	MACRO
		setcpu	\3
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
	ENDM

CALCW	MACRO
		btst	#6,$bfe001
		beq	.q\@
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
.q\@
	ENDM

_rchip		CALCR	_cia,$bfe001,_byte,b
		CALCW	_cia,$bfec01,_byte,b

		addq	#2,d1
		CALCR	_cust,vposr(a6),_byte,b
		CALCR	_cust,vposr(a6),_word,w
		CALCR	_cust,vposr(a6),_long,l
		CALCW	_cust,$184(a6),_word,w
		CALCW	_cust,$184(a6),_long,l

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

		rts

_rfast		addq	#2,d1
		CALCR	_cia,$bfe001,_byte,b
		CALCW	_cia,$bfec01,_byte,b

		addq	#2,d1
		CALCR	_cust,vposr(a6),_word,w
		CALCW	_cust,$184(a6),_word,w

		addq	#2,d1
		CALCR	_chip,MEMCHIP,_word,w
		CALCW	_chip,MEMCHIP,_word,w

		addq	#2,d1
		CALCR	_exp,(a3),_word,w
		CALCW	_exp,(a3),_word,w

		addq	#2,d1
		CALCR	_slv,(a2),_word,w
		CALCW	_slv,(a2),_word,w

		rts

	CNOP 0,4
_ssp		dc.l	0
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
		dc.l	WHDLTAG_Private5	;allowing free modifications using SetCPU
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
;	d6 = leading spaces?
; OUT:	d0 = word new x

_pi		move.l	d6,-(a7)
		st	d6
		bsr	_pi2
		move.l	(a7)+,d6
		rts

_pi1		move.l	d6,-(a7)
		sf	d6
		bsr	_pi2
		move.l	(a7)+,d6
		rts

_pi2		movem.l	d2-d5,-(a7)
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
		tst.b	d6
		beq	.l
		moveq	#" ",d2
		bra	.g

.a		add.w	#"a"-10,d2

.g		bsr	_pc
		add.w	#CHARWIDTH,d0
.l		dbf	d4,.n
		movem.l	(a7)+,d2-d5
		rts

; IN:	d0 = word x
;	d1 = word y
;	d2 = byte digit (0..15)

_pc		movem.l	d0-d3/a0-a1,-(a7)
		lea	(MEMSCREEN),a0
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

_font		INCBIN	sources:pics/pic_font_5x6_br.bin
_font_
_stuffend

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
_top		dc.b	">>speed<< - amount of memory accesses per 1/11 second",0
_top2		dc.b	"AttnFlags=",0
_top3		dc.b	"  Eclock=",0
_top5		dc.b	"  whdload"
_equ		dc.b	"=",0
_dot		dc.b	".",0
_quit		dc.b	"hold lmb to quit and save pic  v1.9  wepl "
	INCBIN	t:date
		dc.b	0
	EVEN

;======================================================================

	END
