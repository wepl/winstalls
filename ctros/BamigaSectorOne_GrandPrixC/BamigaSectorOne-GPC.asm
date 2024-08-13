;*---------------------------------------------------------------------------
;  :Program.	BamigaSectorOne-GPC.asm
;  :Author.	Max Headroom, wepl <wepl@whdload.de>
;  :History.	2024-08-06 resourced Slave due lack of original source
;		2024-08-12 final
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9, vasm
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;======================================================================

ws	SLAVE_HEADER			;ws_Security + ws_ID
	dw	14			;ws_Version
	dw	WHDLF_NoError		;ws_Flags
	dl	$6b000			;ws_BaseMemSize
	dl	0			;ws_ExecInstall
	dw	slv_GameLoader-ws	;ws_GameLoader
	dw	0			;ws_CurrentDir
	dw	0			;ws_DontCache
_keydebug	db	$5F		;ws_keydebug
_keyexit	db	$5D		;ws_keyexit
	dl	0			;ws_ExpMem
	dw	slv_name-ws		;ws_name
	dw	slv_copy-ws		;ws_copy
	dw	slv_info-ws		;ws_info

;======================================================================

slv_name	db	'Grand Prix Circuit Crack-Intro',0
slv_copy	db	'198x Bamiga Sector One & Cybertech',0
slv_info	db	'-----------------------------',$A
		db	'Installed by',$A
		db	'Max Headroom',$A
		db	'of',$A
		db	'The Exterminators',$A
		db	'Updated by Wepl',10
		db	'-----------------------------',$A
		db	'Version 1.1 '
		INCBIN	.date
		db	0
	EVEN

;======================================================================

slv_GameLoader	lea	(_resload,pc),a1
	move.l	a0,(a1)
	movea.l	a0,a2

	move.l	#CACRF_EnableI,d0
	move.l	d0,d1
	jsr	(resload_SetCACR,a0)

	;install keyboard quitter
	bsr	_SetupKeyboard

	lea	(bs1crackgrand.MSG,pc),a0
	lea	$2000,a3
	move.l	a3,a1
	jsr	(resload_LoadFileDecrunch,a2)
	move.l	a3,a0
	sub.l	a1,a1
	jsr	(resload_Relocate,a2)

	move	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(_custom+dmacon)	; expected by ctro

	move.w	#$4EF9,($AA,a3)
	pea	(_patch,pc)
	move.l	(sp)+,($AC,a3)
	jmp	(a3)			;decrunch bytekiller

_patch	lea	$30000,a3
	lea	_pl,a0
	move.l	a3,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)

	moveq	#0,d0
	move.l	d0,d1
	jsr	(resload_SetCACR,a2)

	jsr	(a3)

_quit	pea	(TDREASON_OK).l
	movea.l	(_resload,pc),a0
	jmp	(resload_Abort,a0)

_pl	PL_START
	PL_W	$2680,$200			;bplcon0.color
	PL_W	$26fc,$200			;bplcon0.color
	PL_AW	$278e,~INTF_PORTS		;keep keyboard alive
	PL_S	$279e,$27b2-$279e		;cia access
	PL_PSS	$2824,_dmaon,2
	PL_R	$31b8				;restore gfx clist
	PL_W	$360e+4,9			;audvol
	PL_PSS	$36e8,_wait4lines,2
	PL_W	$37dc+4,9			;audvol
	PL_END

_dmaon	move.l	#$32616,(cop1lc,a0)		;original
	waitvb a0
	move	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER,(dmacon,a0)
	rts

_wait4lines	movem.l	d0-d1,-(sp)
	move.w	#3,d1
.loop	move.b	($DFF006).l,d0
.wait	cmp.b	($DFF006).l,d0
	beq.b	.wait
	dbra	d1,.loop
	movem.l	(sp)+,d0-d1
	rts

bs1crackgrand.MSG	db	'bs1-crackgrandprixcircuid',0

;======================================================================

	INCLUDE	whdload/keyboard.s

;======================================================================

_resload	dx.l	0		;address of resident loader

;======================================================================

	end
