;*---------------------------------------------------------------------------
;  :Modul.	Exodus3010.asm
;  :Contents.	Exodus 3010
;  :Author.	CFou!, Wepl
;  :History.	2025-01-13 repo integration, increase ExpMem
;			removed unused code, add intro skip, move loader to ExpMem,
;			use patch lists, fix access fault in engine, fix intro end;
;			clean source code
;  :Requires.	kick13.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

	STRUCTURE globals,$100
		STRUCT	CLIST,3*4
		WORD	CODENUM
		BYTE	EN

;============================================================================

CHIPMEMSIZE	= $172000	;size of chip memory
FASTMEMSIZE	= $26f000	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0001		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
DEBUG				;add more internal checks
DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
;HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $120		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	0
slv_name	dc.b	"Exodus 3010 ",0
slv_copy	dc.b	"1993 Demonware/Telmet",0
slv_info	dc.b	"adapted for WHDLoad by CFou!, Wepl",10
		dc.b	"Version 1.1 "
		INCBIN	.date
		dc.b 	-1
		dc.b	"using Wepl's kick13 emul"
		dc.b	0
	IFGE slv_Version-17
slv_config	db	"C1:B:Skip Intro"
		dc.b	0
	ENDC
        EVEN


;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

	IFD BOOTBLOCK

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	;move	#$4e71,($3c,a4)			;clist
		clr.l	($4a,a4)			;MEMF_ANY, loader -> ExpMem
		patch	$84(a4),_loader
		jmp	(12,a4)

_loader		movem.l	a0-a1,-(a7)			;a0 = loader, a1 = ioreq
		move.l	a0,a3				;a3 = loader

		clr.l	-(a7)
		move.l	a0,-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		move.l	(_resload,pc),a2		;A2 = resload
		jsr	(resload_Control,a2)
		add	#12,a7

		move.l	a3,a0				;loader
		move.l	#$1800,d0
		jsr	(resload_CRC16,a2)

		move.l	#$c3700050,d1
		cmp.w	#$3bab,d0			;EN
		seq	EN
		beq	.common
		move.l	#$d9680050,d1
		cmp.w	#$cde7,d0			;DE
		bne	_wrongver
.common
		move.l 	d0,$2c8(a3) 			; crack, this gets overwritten -> never used

		lea	_pl_loader,a0
		move.l	a3,a1
		jsr	(resload_Patch,a2)

		movem.l	(a7)+,a0-a1
		jmp (a0)

_pl_loader	PL_START
		PL_IFC1
		PL_B	$14,$60				; beq -> bra, skip intro
		PL_ENDIF
		PL_S	$22,4				; skip protection
	;	PL_S	$46,4				; skip logos
		PL_P	$2ac,_callcode
		PL_W	$2c2,$200			; bplcon0.color
		PL_PS	$378,_setcodenum
		PL_P	$3a6,_patchcode
		PL_PS	$a74,_chgmem
		PL_P	$d62,_endloadseg
		PL_P	$d68,_freecode
		PL_P	$1338,_ChangeDSK
		PL_END

	; move one hunk of game to chip memory
	; to avoid that savegame contains addresses in fast memory
_chgmem		jsr	(a0)				;original
		move.l	d0,d4				;original
		move.l	d4,d7				;original
		cmp.l	#$91c/4,d0			;game de hunk #2
		beq	.chip
		cmp.l	#$8f8/4,d0			;game en hunk #2
		bne	.ret
.chip		or.l	#$40000000,d7
.ret		rts

_callcode	lea	CLIST,a0
		move.l	a0,a1
		move.l	#$1800000,(a1)+
		move.l	#$1000200,(a1)+
		move.l	#-2,(a1)
		waitvb
		move.l	a0,_custom+cop1lc
		movem.l	(a7)+,d0-a6			;original
		rts					;original

	;remember which exe got loaded
_setcodenum	move	d0,CODENUM
		mulu	#$1a,d0				;original
		add	d0,a0				;original
		rts

	; new routine because we changed the seglist to a standard one
_freecode	movem.l	d2/a6,-(a7)
		move.l	(_MOVEMBYTES+4,a7),d2
		subq.l	#4,d2
		lsr.l	#2,d2
.loop		lsl.l	#2,d2
		move.l	d2,a1
		move.l	(a1),d2				;next
		move.l	-(a1),d0
		move.l	4,a6
		jsr	(_LVOFreeMem,a6)
		tst.l	d2
		bne	.loop
		movem.l	(a7)+,_MOVEMREGS
		rts

_patchcode	move.l	d0,d2				;d2 = load address
		beq	.fail

	;transform to a standard dos seglist
	;so we can use PatchSeg & DBGSEG
		move.l	d2,a1
.segloop	move.l	-(a1),d0
		beq	.segend
		move.l	d0,d1
		lsr.l	#2,d0
		subq.l	#1,d0
		move.l	d0,(a1)
		move.l	d1,a1
		bra	.segloop
.segend
		move.l	d2,d3
		subq.l	#4,d3
		lsr.l	#2,d3				;d3 = bptr
		clr.l	-(a7)
		move.l	d3,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		move.l	_resload,a2
		jsr	(resload_Control,a2)
		add	#12,a7

		move	CODENUM,d1

		lea	_pl_music,a0
		cmp	#2,d1
		beq	.patch

	;de-intro is one hunk, but en-intro has 4 hunks!
		cmp	#3,d1
		bne	.not3
		lea	_pl_intro_de,a0
		tst.b	EN
		beq	.patch
		lea	_pl_intro_en,a0
		bra	.patch
.not3
		cmp	#4,d1
		bne	.ok
		lea	_pl_game_de,a0
		tst.b	EN
		beq	.patch
		lea	_pl_game_en,a0

.patch		move.l	d3,a1
		jsr	(resload_PatchSeg,a2)

.ok		move.l	d2,d0
		move.l	d2,a0
		bra	.end

.fail		moveq	#-1,d0
.end		movem.l	(a7)+,d1-d7/a1-a6
		rts

; flush caches after loading an executable

_endloadseg	move.l	d0,d5				;rc
		move.l	_resload,a0
		jsr	(resload_FlushCache,a0)
		move.l	d5,d0
		movem.l	(a7)+,d5-d7/a3/a6		;original
		rts					;original

_pl_music	PL_START
	;	PL_BKPT	$68				;init
		PL_DATA	$70,6				;fix d1 msw init
			moveq	#0,d1
			nop
			nop
		PL_PSS	$214,_stfix,4
		PL_END

_stfix		move	#$1f4/34,d1			;loop counter
.1		move.b	($dff006),d0
.2		cmp.b	($dff006),d0
		beq	.2
		dbf	d1,.1
		rts

_pl_intro_de	PL_START
	;	PL_S	$6a,$452-$6a			;skip to credits
	;	PL_BKPT	$4a0
	;	PL_L	$5f0,-1				;terminate credits
		PL_B	$4b4fd,$fd			;fix endless loop + af on credits end
		PL_END

_pl_intro_en	PL_START
		PL_B	$4b491,$fd			;fix endless loop + af on credits end
		PL_END

_pl_game	PL_START
		PL_PSS	$28e,_stfix,4
		PL_END

_pl_game_de	PL_START
		PL_PSS	$44c62,_af1,2
	;save game
		PL_DATA	$6b066,4			; remove alerte message
			moveq	#1,d7
			bra.b	*+$14
		PL_W	$6b07c,$5479			; addq.w #2,
		PL_PSS	$6b0d4,_InsertSaveDisk3,2
		PL_PS	$6b100,_InsertPreviousDsk
	;load game
		PL_DATA	$6b39a,4			; remove alerte message
			moveq	#1,d7
			bra.b	*+$14
		PL_W	$6b3b0,$5479			; addq.w #2,
		PL_PSS	$6b3ea,_InsertSaveDisk3,2
		PL_PS	$6b424,_InsertPreviousDsk
		PL_NEXT	_pl_game

_pl_game_en	PL_START
		PL_PSS	$44a74,_af1,2
	;save game
		PL_DATA	$6a762,4			; remove alerte message
			moveq	#1,d7
			bra.b	*+$14
		PL_W	$6a778,$5479			; addq.w #2,
		PL_PSS	$6a7d0,_InsertSaveDisk3,2
		PL_PS	$6a7fc,_InsertPreviousDsk
	;load game
		PL_DATA	$6aa12,4			; remove alerte message
			moveq	#1,d7
			bra.b	*+$14
		PL_W	$6aa28,$5479			; addq.w #2,
		PL_PSS	$6aa62,_InsertSaveDisk3,2
		PL_PS	$6aa9c,_InsertPreviousDsk
		PL_END

_af1		add	#$3c,a3				;original
		moveq	#0,d0				;original
		move.b	(a1),d0				;original
		cmp	#$3c,d0
		bls	.ok
		moveq	#-1,d0				;skip
.ok		tst	d0
		rts

_ChangeDSK
	movem.l	d0-a6,-(a7)
	clr.l 	d0		; drive
	move.l	#1,D1
	cmp.b	#'B',d7
	bne	.noD2
	move.l	#2,D1
.noD2
	bsr	 _trd_changedisk
	movem.l	(a7)+,d0-a6
	rts

_InsertSaveDisk3
	move.l	#$200,$24(a1)	; original code
	movem.l	d0-a6,-(a7)
	clr.l 	d0		; drive
	move.l	#3,D1
	bsr	 _trd_changedisk
	movem.l	(a7)+,d0-a6
	rts

_InsertPreviousDsk
	movem.l	d0-a6,-(a7)
	clr.l 	d0		; drive
	move.l	#2,D1
	bsr	 _trd_changedisk
	movem.l	(a7)+,d0-a6
	move.w	#$4,$1c(a1)		; original code
	rts

	ENDC

;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

	END

