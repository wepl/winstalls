;*---------------------------------------------------------------------------
;  :Program.	ddf.asm
;  :Contents.	test Slave to find correct ddfstrt/stop calculation for the SP (save picture) program
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

	IFD BARFLY
	;OUTPUT	"smbfs0:ddf.slave"
	BOPT	O+			;enable optimizing
	;BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	ENDC
	
	STRUCTURE globals,$400
		LONG	_resload
EXPMEM = $1000

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
_info		INCBIN  ".date"
		dc.b	0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,(_resload)		;save for later use

BLORES = $10000
BHIRES = $12000
BSHRES = $14000
BDUMMY = $20000

	;lores 320
_lores		lea	BLORES,a0
		moveq	#0,d0
			; 33222222222211111111110000000000
			; 10987654321098765432109876543210
		move.l	#%11111111111111111100001111001101,d1
		move.w	#3-1,d3
.b		move.l	d1,(a0)+		;32 pixel, 4 byte
		move.w	#40/4-2,d2
.c		move.l	d0,(a0)+
		dbf	d2,.c
		dbf	d3,.b
		move.w	#40/4-1,d2
.d		move.l	d0,(a0)+
		dbf	d2,.d
	;hires 640
_hires		lea	BHIRES,a0
		move.w	#3-1,d3
.b		move.l	d1,(a0)+		;64 pixel, 8 byte
		move.l	d1,(a0)+
		move.w	#80/4-3,d2
.c		move.l	d0,(a0)+
		dbf	d2,.c
		dbf	d3,.b
		move.w	#80/4-1,d2
.d		move.l	d0,(a0)+
		dbf	d2,.d
	;shres 1280
_shres		lea	BSHRES,a0
		move.w	#3-1,d3
.b		move.l	d1,(a0)+		;128 pixel, 16 byte
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
		move.l	#diwstrt<<16+$2981,(a5)+
		move.l	#diwstop<<16+$2dc1,(a5)+
		move.l	#color<<16,(a5)+
		move.l	#(color+2)<<16+$fff,(a5)+

DSB = $38	;ddfstrt init, start value
DEB = $d0	;ddfstop init, start value

DSI = DSB	;ddfstrt init, start value
DEI = DEB	;ddfstop init, start value

		move.l	#fmode<<16+0,(a5)+
		move.l	#bplcon0<<16+$1200,(a5)+
		move.l	#ddfstrt<<16+DSB,(a5)+
		move.l	#ddfstop<<16+DEB,(a5)+
		lea	BDUMMY,a3
		bsr	bpl
L SET 43	;vertical line for cwait
		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#fmode<<16+3,(a5)+

X	MACRO
	IFGT L-256
		move.l	#$ffe1fffe,(a5)+	;255,224
L SET L-256
	ENDC
		move.l	#L<<24+$1fffe,(a5)+	;wait
L SET L+4
		move.l	#ddfstrt<<16+DS,(a5)+
		move.l	#ddfstop<<16+DE,(a5)+
DS SET DS+1
;DE SET DE+1
		bsr	bpl
		move.l	#bpl1mod<<16,(a5)+
	ENDM
X4	MACRO
		X
		move.l	#color<<16+$700,(a5)+
		X
		move.l	#color<<16+$070,(a5)+
		X
		move.l	#color<<16+$000,(a5)+
		X
		move.l	#color<<16+$007,(a5)+
	ENDM
X16	MACRO
		X4
		X4
		X4
		X4
	ENDM
C	MACRO
		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#bplcon0<<16+\1,(a5)+
		move.l	#(color+2)<<16+$f8f,(a5)+
		lea	\2,a3
DS SET DSI	;ddfstrt
DE SET DEI	;ddfstop
		X16
		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#(color+2)<<16+$f88,(a5)+
		X16
		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#(color+2)<<16+$88f,(a5)+
		X16
		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#(color+2)<<16+$8f8,(a5)+
		X16
	ENDM

		C $1200,BLORES			;lores
	;	C $9200,BHIRES			;hires
	;	C $1240,BSHRES			;shres, hires bit must not be set!

		move.l	#L<<24+$1fffe,(a5)+	;wait
		move.l	#fmode<<16+0,(a5)+
		move.l	#bplcon0<<16+$1200,(a5)+
		move.l	#ddfstrt<<16+DSB,(a5)+
		move.l	#ddfstop<<16+DEB,(a5)+
		lea	BDUMMY,a3
		bsr	bpl
		move.l	#color<<16,(a5)+
		move.l	#(color+2)<<16+$fff,(a5)+
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

	INCLUDE	whdload/keyboard.s

;======================================================================

	END
