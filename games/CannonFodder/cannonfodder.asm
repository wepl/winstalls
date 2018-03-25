;*---------------------------------------------------------------------------
;  :Program.	cannonfodder.asm
;  :Contents.	Slave for "CannonFodder"
;  :Author.	Wepl
;  :Version.	$Id: cannonfoddercd.asm 1.5 2013/11/20 00:52:34 wepl Exp wepl $
;  :History.	25.03.18 derrived from cannonfoddercd.asm
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
_save		dc.b	"savegame",0
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

		move.l	(_expmem),$89cf2		;buffer for iff conversion
		
_plen1		PL_START
		PL_W	$2c64,$4200		;bplcon0
		PL_S	$5d92,$5dc2-$5d92	;skip init stuff
		PL_W	$cc52,$1e		;htotal
		PL_W	$cf96,$200		;bplcon0
		PL_PS	$16d7c,_af1
		PL_R	$1d370			;skip disk2 check
		PL_PS	$1eb36,_af1

		PL_P	$98e6,_SetupKeyboard
		PL_PS	$9d02,_loader
		PL_PS	$9fcc,_loader
		PL_S	$a36c,2
		PL_S	$a370,$10

		PL_R	$26fcc			;loading screen
		PL_R	$27018			;loading screen
		PL_P	$27bfa,_sg
		PL_P	$27c9a,_lg

		PL_W	$1a6fe,$4200		;bplcon0
		PL_W	$1a79e,$4200		;bplcon0
		PL_W	$1a7b2,$5200		;bplcon0
		PL_W	$1adec,$5200		;bplcon0
		PL_W	$1aeac,$4200		;bplcon0
		PL_W	$2473e,$6600		;bplcon0
		PL_W	$24908,$4200		;bplcon0
		PL_W	$25bfc,$5200		;bplcon0
		PL_W	$25eae,$4200		;bplcon0
		
		PL_L	$27dab,"DISK"
		PL_L	$27de1,"DISK"
		PL_L	$27e17,"DISK"
		PL_END

_plen2		PL_START
		PL_END

_plde		PL_START
		PL_END

_plfr		PL_START
		PL_END

_loader		move.l	(_resload),a2
		jsr	(resload_LoadFileDecrunch,a2)
		exg	d0,d1				;size/success=0
		rts

_sg		move.l	#$80d4e-$80626,d0
		lea	_save,a0
		lea	$80626,a1
		move.l	_resload,a2
		jmp	(resload_SaveFile,a2)

_lg		clr.l	$a7bf6				;no valid save
		lea	_save,a0
		move.l	_resload,a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	.load
		jmp	$a7de6				;show text
.load		lea	_save,a0
		lea	$80626,a1
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	#-1,$a7bf6
		rts

_af1		move.w	$81556,d0			;actual player/team (0-5)
		bpl	.ok
		clr.w	d0
.ok		rts

_key_help	move.l	a0,-(a7)
		move.w	$81556,d0	;actual player/team
		lea	$821c0,a0
		st	(a0,d0.w)
		st	(6,a0,d0.w)
		lea	$81f4c,a0
		add.w	d0,a0
		add.w	d0,a0
		move.w	#42,(a0)	;grenades
		move.w	#42,(6,a0)	;bazookas
		move.l	(a7)+,a0
		rts

;============================================================================

_keycode = $8991b

	INCLUDE	sources:whdload/keyboard.s

;============================================================================

	END

