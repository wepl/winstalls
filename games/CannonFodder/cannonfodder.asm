;*---------------------------------------------------------------------------
;  :Program.	cannonfodder.asm
;  :Contents.	Slave for "CannonFodder"
;  :Author.	Wepl
;  :Version.	$Id: cannonfodder.asm 1.4 2018/04/04 01:25:09 wepl Exp wepl $
;  :History.	25.03.18 derrived from cannonfoddercd.asm
;		17.05.18 access fault fix improved
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:c/cannonfodder/CannonFodder.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

	STRUCTURE	globals,$100
		LONG	_resload

EXPMEMLEN = $b000

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	13			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEMLEN		;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Cannon Fodder",0
_copy		dc.b	"1993 Sensible Software",0
_info		dc.b	"installed and fixed by Wepl",10
		dc.b	"Version 2.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_data		dc.b	"data",0
_game		dc.b	"fodderc",0
_d1		dc.b	"DISK1",0
_d2		dc.b	"disk2",0
_d3		dc.b	"DISK3",0
_savepath	dc.b	"save",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,(_resload)			;save for later using
		move.l	a0,a2				;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		
	;set stack
		move.l	#EXPMEMLEN-8,a7
		add.l	(_expmem),a7			;stack in fastmem

	;load main
		lea	_game,a0
		lea	$80000,a1
		move.l	a1,a3				;A3 = main
		jsr	(resload_LoadFileDecrunch,a2)

	;check version
		move.l	#$2000,d0
		move.l	a3,a0
		jsr	(resload_CRC16,a2)
		lea	_plen1,a0
		cmp.w	#$b157,d0
		beq	.patch
		lea	_plen2,a0
		cmp.w	#$a1c0,d0
		beq	.patch
		lea	_plde,a0
		cmp.w	#$7b22,d0
		beq	.patch
		lea	_plfr,a0
		cmp.w	#$c3ce,d0
		beq	.patch
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

.patch		move.l	a3,a1
		jsr	(resload_Patch,a2)

		lea	(_custom),a6
		jmp	(a3)

		move.l	(_expmem),$89cf2	;buffer for iff conversion
		
_plen1		PL_START
		PL_W	$2c64,$4200		;bplcon0
		PL_S	$5d92,$5dc2-$5d92	;skip init stuff
		PL_P	$a2f8,_keyboard		;keyboard int umleiten
		PL_R	$a6a8			;copylock
		PL_P	$b3e8,_loader
		PL_P	$bd2e,_gettmp
		PL_W	$cc52,$1e		;htotal
		PL_W	$cf96,$200		;bplcon0
		PL_PS	$16d7c,_af0
		PL_W	$1ccf2,$4200		;bplcon0
		PL_W	$1cd92,$4200		;bplcon0
		PL_W	$1cda6,$5200		;bplcon0
		PL_R	$1d370			;skip disk2 check
		PL_W	$1d3a2,$5200		;bplcon0
		PL_W	$1d462,$4200		;bplcon0
		PL_PS	$1eb36,_af1
		PL_B	$24304,$6f		;beq -> ble
		PL_PS	$243ee,_s1
		PL_W	$276a8,$6600		;bplcon0
		PL_W	$2785e,$4200		;bplcon0
		PL_W	$28b52,$5200		;bplcon0
		PL_W	$28df8,$4200		;bplcon0
		PL_W	$29e7c,$2a4d4-$29e7c	;load/save game
		PL_S	$29e8a,6		;skip check "CFSDISK"
		PL_S	$29ea4,$e2-$a4		;skip file "CFSDISK"
		PL_PS	$29ffe,_loadgame
		PL_S	$2a130,4		;load/save game
		PL_W	$2a13c,$23a-$13c	;load/save game
		PL_S	$2a29e,10		;load/save game
		PL_PS	$2a2c8,_savegame
		PL_R	$2acfe			;"insert disk 3"
		PL_END

_plen2		PL_START
		PL_END

_plde		PL_START
		PL_END

_plfr		PL_START
		PL_END

_loader		movem.l	d2-d6/a1-a3/a5-a6,-(a7)
		pea	.ret
		tst.w	d0
		beq	.rts
		cmp.w	#8,d0
		beq	_loadname
		cmp.w	#$10,d0
		beq	_listfiles
		cmp.w	#$18,d0
		beq	_loadscatter
		cmp.w	#$20,d0
		beq	.rts
		illegal
.ret		movem.l	(a7)+,_MOVEMREGS
.rts		rts

; a0=name a1=dest
_loadname
		lea	_d1,a2		;"DISK1"
		bsr	.cmp
		beq	.ok
		lea	_d2,a2		;"DISK2"
		bsr	.cmp
		beq	.ok
		lea	_d3,a2		;"DISK3"
		bsr	.cmp
		beq	.ok

		move.l	_resload,a2
		jsr	(resload_LoadFileDecrunch,a2)
		exg	d0,d1				;size/success=0
		rts

.ok		moveq	#0,d0
		rts

.cmp		move.l	a0,a3
.lp		move.b	(a2)+,d0
		beq	.cmpok
		cmp.b	(a3)+,d0
		beq	.lp
		moveq	#-1,d0
.cmpok		rts

; in:  a0=name
; out: Z=1=success d7=data-in-buffer a4=data
_loadscatter	move.l	(_expmem),a1
		move.l	_resload,a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	(_expmem),a4
		move.l	d0,d7				;length
		moveq	#0,d0				;success
		rts

_gettmp		move.l	(_expmem),a4
		move.l	(a4)+,d7
		cmp.w	d0,d0				;set Z flag
		rts

_listfiles	lea	(_savepath),a0
		move.l	(_expmem),a1
		move.l	a1,a3				;A3 = buffer in
		move.l	#$2000,d0			;buffer length
		lea	(a3,d0.l),a4			;A4 = buffer out
		move.l	(_resload),a2
		jsr	(resload_ListFiles,a2)
		move.l	d0,d7				;d7 = how many entries

		move.l	a4,a0
		bra	.next

.loop		move.l	a0,a1
.copy		move.b	(a3)+,(a1)+
		bne	.copy
		
.next		add.w	#$20,a0
		subq.l	#1,d7
		bcc	.loop
		clr.b	(a0)				;end of table
		clr.b	($20,a0)			;end of table
		clr.b	($40,a0)			;end of table
		clr.b	($60,a0)			;end of table
		clr.b	($80,a0)			;end of table

		move.l	a4,a0
		rts

; a0=name a1=dest
_loadgame	move.l	_expmem,a2
		lea	_savepath,a3
.copypath	move.b	(a3)+,(a2)+
		bne	.copypath
		move.b	#"/",(-1,a2)
.copyname	move.b	(a0)+,(a2)+
		bne	.copyname
		move.l	_expmem,a0
		moveq	#8,d0
		bra	_loader

; a0=name a1=src d1=length
_savegame	move.l	_expmem,a2
		lea	_savepath,a3
.copypath	move.b	(a3)+,(a2)+
		bne	.copypath
		move.b	#"/",(-1,a2)
.copyname	move.b	(a0)+,(a2)+
		bne	.copyname
		move.l	_expmem,a0
		move.l	d1,d0				;length
		move.l	_resload,a2
		jsr	(resload_SaveFile,a2)
		moveq	#0,d0
		rts

_af0		move.w	$81556,d0			;actual player/team (0-5)
		bpl	.ok
		add.l	#$16dde-$16d82,(a7)
.ok		rts

_af1		move.w	$81556,d0			;actual player/team (0-5)
		bpl	.ok
		add.l	#$1eb52-$1eb3c,(a7)
.ok		rts

_s1		cmp.l	#$100000,d0
		bhs	.ret
		move.l	d0,a1				;original
		move.l	($20,a0),d0			;original
		rts
.ret		addq.l	#4,a7
		rts

;============================================================================

_keyboard	movem.l	d0-d1/a0-a2,-(a7)
		lea	_ciaa,a0
		lea	_custom,a2
		btst	#CIAICRB_SP,(ciaicr,a0)
		beq	.end
		lea	$814e5,a1		;lastkeycode
		move.b	(ciasdr,a0),d0
		or.b	#CIACRAF_SPMODE,(ciacra,a0)
		ror.b	#1,d0
		not.b	d0
		bpl	.down
		move.b	(a1),d1
		eor.b	d0,d1
		and.b	#$7f,d1
		bne	.down
		moveq	#0,d0
.down		move.b	d0,(a1)

		cmp.b	(_keyexit),d0
		beq	.exit
		cmp.b	#$5f,d0			;HELP ?
		bne	.wait
		move.w	$81556,d0		;aktuelles team
		lea	$821c0,a1
		st	(a1,d0.w)
		lea	$821c6,a1
		st	(a1,d0.w)
		lea	$81f4c,a1
		add.w	d0,a1
		add.w	d0,a1
		move.w	#42,(a1)		;grenades
		move.w	#42,(6,a1)		;bazookas

.wait		moveq	#3-1,d1
.wait1		move.b	(vhposr,a2),d0
.wait2		cmp.b	(vhposr,a2),d0
		beq	.wait2
		dbf	d1,.wait1

.end		and.b	#~(CIACRAF_SPMODE),(ciacra,a0)
		move.w	#INTF_PORTS,(intreq,a2)
		tst.w	(intreqr,a2)
		movem.l	(a7)+,_MOVEMREGS
		rte

.exit		pea	TDREASON_OK
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;============================================================================

	END

