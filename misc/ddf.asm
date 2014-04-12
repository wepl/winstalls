;*---------------------------------------------------------------------------
;  :Version.	$Id: ddf.asm 1.1 2001/01/03 23:58:20 jah Exp jah $
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	OUTPUT	"ram:ddf.slave"

	BOPT	O+			;enable optimizing
	;BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	
	STRUCTURE globals,$400
		LONG	_resload
EXPMEM = $10000

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	18			;ws_Version
		dc.w	0			;ws_flags
		dc.l	$40000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	0			;ws_config

_name		dc.b	"DDF Test Slave",0
_copy		dc.b	"Wepl",0
_info
	DOSCMD	"WDate  >T:date"
	INCBIN	"T:date"
		dc.b	0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(_resload)		;save for later use

		lea	$10000,a3		;A3 biplane
	;lores 320
		move.l	a3,a0
		moveq	#0,d0
		moveq	#-1,d1
		move.w	#3-1,d3
.b		move.l	d1,(a0)+
		move.w	#40/4-2,d2
.c		move.l	d0,(a0)+
		dbf	d2,.c
		dbf	d3,.b
		move.w	#40/4-1,d2
.d		move.l	d0,(a0)+
		dbf	d2,.d
	;hires 640
_hires		lea	($2000,a3),a0
		move.w	#3-1,d3
.b		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.w	#80/4-3,d2
.c		move.l	d0,(a0)+
		dbf	d2,.c
		dbf	d3,.b
		move.w	#80/4-1,d2
.d		move.l	d0,(a0)+
		dbf	d2,.d
	;shres 1280
_shres		lea	($4000,a3),a0
		move.w	#3-1,d3
.b		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.l	d1,(a0)+
		move.w	#160/4-5,d2
.c		move.l	d0,(a0)+
		dbf	d2,.c
		dbf	d3,.b
		move.w	#160/4-1,d2
.d		move.l	d0,(a0)+
		dbf	d2,.d
		
		lea	_custom,a6
		move.l	#$FFF,(color,a6)
		lea	$1000,a5
		move.l	a5,(cop1lc,a6)
		move.w	#diwstrt,(a5)+
		move.w	#$2981,(a5)+
		move.w	#diwstop,(a5)+
		move.w	#$29c1,(a5)+

;		move.l	#fmode<<16+1,(a5)+

		move.l	#bplcon0<<16+$1200,(a5)+

L SET 41
DS SET $38
DE SET $d0

X MACRO
		move.l	#L<<24+$1fffe,(a5)+
L SET L+4
		move.w	#ddfstrt,(a5)+
		move.w	#DS,(a5)+
DS SET DS+1
DE SET DE+1
		move.w	#ddfstop,(a5)+
		move.w	#DE,(a5)+
		bsr	bpl
		move.w	#bpl1mod,(a5)+
		move.w	#0,(a5)+
	ENDM
		X
		X
		X
		X
		X
		X
		X
		X

		X
		X
		X
		X
		X
		X
		X
		X

		move.l	#L<<24+$1fffe,(a5)+
		move.l	#bplcon0<<16+$9200,(a5)+
		add.w	#$2000,a3
DS SET $38
		X
		X
		X
		X
		X
		X
		X
		X

		X
		X
		X
		X
		X
		X
		X
		X

		move.l	#L<<24+$1fffe,(a5)+
		move.l	#bplcon0<<16+$9240,(a5)+	;shres
		add.w	#$2000,a3
DS SET $38
		X
		X
		X
		X
		X
		X
		X
		X

		X
		X
		X
		X
		X
		X
		X
		X

		move.l	#L<<24+$1fffe,(a5)+
		move.l	#bplcon0<<16+$1240,(a5)+	;shres
DS SET $38
		X
		X
		X
		X

		move.l	#-2,(A5)+
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER,(dmacon,a6)
		waitvb	a6
		move.w	#DMAF_SETCLR|DMAF_RASTER,(dmacon,a6)
_2		bsr	_SetupKeyboard
.w		btst	#6,$bfe001
		bne	.w
		pea	TDREASON_OK
		move.l	_resload,a0
		jmp	(resload_Abort,a0)

bpl		move.l	a3,d0
		swap	d0
		move.w	#bplpt,(a5)+
		move.w	d0,(a5)+
		move.w	#bplpt+2,(a5)+
		swap	d0
		move.w	d0,(a5)+
		rts

;======================================================================

	INCLUDE	Sources:whdload/keyboard.s

;======================================================================

	END
