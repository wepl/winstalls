;*---------------------------------------------------------------------------
;  :Program.	readjoyport.asm
;  :Contents.	Slave to check resload_ReadJoyPort
;  :Author.	Wepl
;  :Version.	$Id: speed.asm 1.14 2020/10/26 00:11:23 wepl Exp wepl $
;  :History.	2024-05-18 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	OUTPUT	"ram:readjoyport.slave"

	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	19
		dc.w	0			;ws_flags
		dc.l	$70000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Test ReadJoyPort Slave",0
_copy		dc.b	"2024 Wepl",0
_info		dc.b	"done by Wepl "
	DOSCMD	"WDate  >T:date"
	INCBIN	"T:date"
_config		dc.b	0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		lea	(_ciaa),a4		;A4 = ciaa
		move.l	a0,a5			;A5 = resload
		lea	(_custom),a6		;A6 = custom
		sub	#16,a7			;hrtmon
		bsr	_SetupKeyboard

SCREENWIDTH	= 320
SCREENHEIGHT	= 200
CHARHEIGHT	= 5
CHARWIDTH	= 5

MEMCOPPER	= $e000
MEMSCREEN	= $10000

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
	;get whdload
		lea	(_tags),a0
		jsr	(resload_Control,a5)

	;print screen text
		moveq	#0,d0
		move.l	#SCREENHEIGHT-CHARHEIGHT,d1
		lea	_bottom,a0
		bsr	_ps

		moveq	#0,d0
		moveq	#1,d1
		lea	_top1,a0
		bsr	_ps

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
		add.l	#2*CHARHEIGHT,d1
		lea	_leg1,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg2,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg3,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg4,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg5,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg6,a0
		bsr	_ps
		moveq	#0,d0
		addq.l	#CHARHEIGHT+1,d1
		lea	_leg7,a0
		bsr	_ps

	;main loop
.again		waitvb	a6
		moveq	#0,d7			;port

		move.l	d1,d2
		lea	_nodetect,a0
		move.b	_keycode,d0
		cmp.b	#$22,d0
		seq	d6			;detect = active
		bne	.nodetectps
		lea	_detect,a0
.nodetectps	moveq	#CHARWIDTH*25,d0
		move.l	#SCREENHEIGHT-CHARHEIGHT,d1
		bsr	_ps
		move.l	d2,d1

.loop		move.l	d1,d2			;y
		move.l	d7,d0
		tst.b	d6
		beq	.nodetect
		bset	#RJPB_DETECT,d0
.nodetect	jsr	(resload_ReadJoyPort,a5)

		moveq	#0,d1

		btst	#RJPB_RIGHT,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_LEFT,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_DOWN,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_UP,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_PLAY,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_REVERSE,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_FORWARD,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_GREEN,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_YELLOW,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_RED,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		btst	#RJPB_BLUE,d0
		sne	d1
		and	#1,d1
		move	d1,-(a7)

		move.l	d0,d1
		rol.l	#4,d1
		and	#%1111,d1
		move	d1,-(a7)		;type

		move.l	d0,-(a7)		;result
		move.l	d7,-(a7)		;port

		moveq	#0,d0			;x
		move.l	d2,d1
		addq.l	#CHARHEIGHT+1,d1	;y
		lea	_data,a0
		move.l	a7,a1
		bsr	_ps
		add	#4+4+12*2,a7

		addq.l	#1,d7
		cmp	#5,d7
		bne	.loop

		sub.l	#5*(CHARHEIGHT+1),d1

		bra	.again

	;end
		pea	TDREASON_OK
		jmp	(resload_Abort,a5)

	CNOP 0,4
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
		dc.l	TAG_DONE
	EVEN

;--------------------------------
; print formatted string (printf)
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

;--------------------------------
; print integer
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

;--------------------------------
; print char
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

;============================================================================

	INCDIR	Sources:whdload
	INCLUDE	keyboard.s

;============================================================================

_copper		dc.w	diwstrt,$1a81
		dc.w	diwstop,$1ac1+((SCREENHEIGHT-256)*$100)
		dc.w	bplcon0,$1200
		dc.w	bplpt+0,MEMSCREEN>>16
		dc.w	bplpt+2,MEMSCREEN&$ffff
		dc.w	bpl1mod,0
		dc.w	color+0,0
		dc.w	color+2,$ddd
		dc.l	-2

_top1		dc.b	"ReadJoyPort Testslave "
	INCBIN	t:date
		dc.b	0
_top2		dc.b	"AttnFlags=%lx  Eclock=%ld  whdload=%ld.%ld.%ld",0
_leg1		dc.b	"                               play/pause/mmb/fb3",0
_leg2		dc.b	"                             reverse",0
_leg3		dc.b	"                           forward",0
_leg4		dc.b	"                         green/shuffle",0
_leg5		dc.b	"                       yellow/repeat   right",0
_leg6		dc.b	"                     red/lmb/fb    down",0
_leg7		dc.b	"port   result type blue/rmb/fb2  up  left",0
_data		dc.b	"%4ld %08lx %4d%2d%2d%2d%2d%2d%2d%2d%2d%2d%2d%2d",0
_detect		db	"detect",0
_nodetect	db	"      ",0
_bottom		db	"hold D for detection",0
	EVEN

;============================================================================

_keycode	dx.b	1	;rawkey code
	CNOP 0,4
_resload	dx.l	1	;address of resident loader

;============================================================================

	END

