;*---------------------------------------------------------------------------
;  :Program.	linwuschallenge.asm
;  :Contents.	Slave for "Lin Wu's Challenge" by Lasersoft
;  :Author.	Wepl
;  :Originals.	v1 disk protection, CP=3958 STARTUP=4850 GAME=15850 MAP=22925
;		v2 password system, no disk protection, CP=22 STARTUP=4850
;		   GAME=15850 MAP=20301
;		v3 english release, password system, no 'CP' at all,
;		   STARTUP=4840 GAME=15858 MAP=20297
;  :History.	2026-09-13 started
;		2026-09-14 file system library at $c0 replaced by slave routines,
;			   'STARTUP' is loaded directly, disk protection of v1 removed,
;			   'CP' is provided by the slave and no longer loaded
;		2026-09-15 set CIA-B timer A like the loader, checked by 'GAME'
;			   keyboard handled by the slave, keyboard polling of the game
;			   redirected to a variable
;		2026-09-18 trainer for the time limit added, with an enabled trainer
;			   the highscores are no longer saved
;		2026-09-19 support for the english release (v3) added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :To Do.
;---------------------------------------------------------------------------*
;
;	The bootloader (tracks 78-79) decrypts a file system library to $c0.
;	($c0) contains the library base, the game only uses two functions:
;		-6	load file	a0=name d0=address, PP20 files are decrunched
;		-$c	save file	a0=name d0=address d1=length
;	Both return d0=0 (error code), d1=file length, a0=error text.
;	Registers d3-d7/a1-a6 are preserved.
;	The other functions (-$12 delete, -$18 nop, -$1e init, -$24 read
;	directory) are not used by the game and set to illegal.
;
;	The bootloader starts 'STARTUP' at $3000 with SSP=$80000 and SR=$2000.
;
;	v1 protection:
;	'CP' is loaded to $40000 and called, it performs a disk check and sets
;	($84)=0 and ($88)=$500 on success, 'MAP' checks both values
;	'MAP' contains a second disk check at $41278 (trace obfuscated)
;	v2 contains 'CP' as stub setting the values and 'MAP' has no check
;	v3 has no 'CP' at all, 'STARTUP' never loads it
;	the slave always provides the 'CP' of v2 (the imager does not save 'CP')
;
;	both versions: the loader writes CIA-B TALO=$aa TAHI=$e1, 'GAME' checks
;	TAHI=$e1 at $40a72, $40c42 and $414a0 (read via $f0500+$b0d000)
;	'GAME' $41c92 checksums 'STARTUP' $3000-$36ff (=$16e0) at the end of a
;	level, on mismatch it jumps to $c0 with a movem frame on the stack
;	(v3 has the checksum code but the conditional branch was removed)
;
;	keyboard: 'STARTUP' installs a level 2 handler ($38a2 -> $68) which writes
;	the received raw byte back into CIA-A SDR (with a too short handshake),
;	'GAME' and 'MAP' poll and clear $bfec01 directly (raw format, e.g. $75 = Esc)
;	the slave uses whdload/keyboard.s, stores the key in raw SDR format into
;	_keybuf, and all game accesses to $bfec01 are redirected to _keybuf
;
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	;global variables in base memory, the area $c0-$1473 was used by the
	;original file system library and is not used by the game
	STRUCTURE	globals,$100
		LONG	_resload
		BYTE	_keybuf			;last key in raw CIA SDR format

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_crc
		dc.w	_config-_base		;ws_config

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Lin Wu's Challenge",0
_copy		dc.b	"1990 Lasersoft",0
_info		dc.b	"installed and fixed by Wepl",10
		dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_config		dc.b	"C1:B:Double time limit;"
		dc.b	"C2:B:No time limit",0

_data		dc.b	"data",0
_startup	dc.b	"STARTUP",0
_ok		dc.b	"OK",0
	EVEN

_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	TAG_DONE

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,a2				;A2 = resload
		move.l	a0,(_resload).w			;save for later using

	;get the state of the trainer options
		lea	(_tags,pc),a0
		jsr	(resload_Control,a2)

	;hardware state as left by the bootloader
		lea	_custom,a6
		move.w	#$7fff,(intena,a6)
		move.w	#$7fff,(intreq,a6)
		move.w	#$7fff,(dmacon,a6)
		move.w	#$7fff,(adkcon,a6)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER|DMAF_BLITTER|DMAF_SPRITE|DMAF_DISK,(dmacon,a6)
		move.w	#$200,(bplcon0,a6)
	;the loader sets CIA-B timer A, 'GAME' checks TAHI = $e1
		move.b	#$aa,(_ciab+ciatalo)
		move.b	#$e1,(_ciab+ciatahi)

		bsr	_SetupKeyboard

	;install file system library
		lea	(_libbase,pc),a0
		move.l	a0,$c0

	;load main program like the bootloader does
		lea	(_startup,pc),a0
		lea	$3000,a3			;A3 = STARTUP
		move.l	a3,d0
		bsr	_load
		lea	(_pl_startup3,pc),a0		;v3
		cmp.l	#4840,d1
		beq	.plstartup
		lea	(_pl_startup,pc),a0		;v1/v2
.plstartup	move.l	a3,a1
		jsr	(resload_Patch,a2)

		lea	$80000,a7
		move.w	#$2000,sr
		jmp	(a3)

;============================================================================
; replacement for the file system library
; the jump table entries are 6 bytes each, padded with 0

		illegal					;-$24 read directory
		ds.b	4
		illegal					;-$1e init
		ds.b	4
		illegal					;-$18 nop
		ds.b	4
		illegal					;-$12 delete file
		ds.b	4
		bra.b	_save				;-$0c save file
		ds.b	4
		bra.b	_load				;-$06 load file
		ds.b	4
_libbase

;============================================================================
; save file
; IN:	a0 = name
;	d0 = address
;	d1 = length
; OUT:	d0 = error code (0)
;	d1 = file length
;	a0 = error text

_save		movem.l	d2-d7/a1-a6,-(a7)
		move.l	d1,d6				;D6 = length

	;if a trainer is enabled nothing is saved, the game saves the
	;highscores only
		move.l	(_custom1,pc),d1
		or.l	(_custom2,pc),d1
		bne	.ret

		move.l	d0,a1
		move.l	d6,d0
		move.l	(_resload),a2
		jsr	(resload_SaveFile,a2)

.ret		move.l	d6,d1
		moveq	#0,d0
		lea	(_ok,pc),a0
		movem.l	(a7)+,d2-d7/a1-a6
		rts

;============================================================================
; load file
; IN:	a0 = name
;	d0 = address
; OUT:	d0 = error code (0)
;	d1 = file length (packed)
;	a0 = error text

_load		movem.l	d2-d7/a1-a6,-(a7)
		move.l	d0,a3				;A3 = address
		move.l	(_resload),a2

	;'CP' is the disk protection, install the version of v2
		cmp.w	#"CP",(a0)
		bne	.load
		tst.b	(2,a0)
		bne	.load
		lea	(_cp,pc),a0
		moveq	#_cpend-_cp,d6			;D6 = file length
		move	d6,d0
		subq	#1,d0
.cpcopy		move.b	(a0)+,(a3)+
		dbf	d0,.cpcopy
		bra	.ret

.load		move.l	a3,a1
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	d0,d6				;D6 = file length

		cmp.l	#"PP20",(a3)
		bne	.nopp
		move.l	a3,a0
		bsr	_pp20
.nopp
	;'GAME' and 'MAP' are loaded to $40000, identified by length
		cmp.l	#$40000,a3
		bne	.ret
		lea	(_pl_game,pc),a0
		cmp.l	#15858,d6			;GAME v3
		beq	.patch
		lea	(_pl_game12,pc),a0		;GAME v1/v2, continues with _pl_game
		cmp.l	#15850,d6
		beq	.patch
		lea	(_pl_map1,pc),a0
		cmp.l	#22925,d6			;MAP v1
		beq	.patch
		lea	(_pl_map2,pc),a0
		cmp.l	#20301,d6			;MAP v2
		beq	.patch
		lea	(_pl_map3,pc),a0
		cmp.l	#20297,d6			;MAP v3
		bne	.ret

.patch		move.l	a3,a1
		jsr	(resload_Patch,a2)

.ret		move.l	d6,d1
		moveq	#0,d0
		lea	(_ok,pc),a0
		movem.l	(a7)+,d2-d7/a1-a6
		rts

_pl_startup	PL_START		;v1/v2
		PL_R	$6d8				;floppy motor off/deselect
		PL_R	$716				;floppy motor on/select
		PL_R	$8a2				;keyboard handler install
		PL_W	$90e,$3ff7			;don't disable INTEN/PORTS
		PL_END

_pl_map3	PL_START		;v3
		PL_R	$1688				;floppy motor on/select
		PL_R	$16a2				;floppy seek to track 0
		PL_R	$1bd0				;floppy motor off/deselect
		PL_R	$1c0a				;floppy motor on/select
	;all accesses to CIA-A SDR
		PL_L	$1da,_keybuf
		PL_L	$248,_keybuf
		PL_L	$7ea,_keybuf
		PL_L	$892,_keybuf
		PL_L	$970,_keybuf
		PL_L	$982,_keybuf
		PL_L	$99e,_keybuf
		PL_L	$9b2,_keybuf
		PL_L	$d32,_keybuf
		PL_L	$d3e,_keybuf
		PL_L	$d8a,_keybuf
		PL_L	$db4,_keybuf
		PL_L	$dc6,_keybuf
		PL_L	$de2,_keybuf
		PL_L	$df6,_keybuf
		PL_L	$ea4,_keybuf
		PL_L	$f1c,_keybuf
		PL_END

_pl_startup3	PL_START		;v3
		PL_R	$6ce				;floppy motor off/deselect
		PL_R	$70c				;floppy motor on/select
		PL_R	$898				;keyboard handler install
		PL_W	$904,$3ff7			;don't disable INTEN/PORTS
		PL_END

	;'GAME' v1/v2 checksums 'STARTUP' at the end of a level, v3 does not
_pl_game12	PL_START
		PL_NOP	$1cb8,4				;checksum over STARTUP $3000-$36ff
		PL_NEXT	_pl_game

_pl_game	PL_START		;v1/v2/v3
	;the vertb interrupt counts 5 frames ($41a5e), then the displayed time
	;at $43dc4 is decremented by one (bcd) at $40a14, on zero the game ends
		PL_IFC1
		PL_W	$1a60,10			;trainer: double time
		PL_ENDIF
		PL_IFC2
		PL_NOP	$a14,4				;trainer: no time limit
		PL_ENDIF
	;all accesses to CIA-A SDR
		PL_L	$132,_keybuf
		PL_L	$13a,_keybuf
		PL_L	$146,_keybuf
		PL_L	$14e,_keybuf
		PL_L	$15a,_keybuf
		PL_L	$162,_keybuf
		PL_L	$16e,_keybuf
		PL_L	$176,_keybuf
		PL_L	$182,_keybuf
		PL_L	$18a,_keybuf
		PL_L	$196,_keybuf
		PL_L	$19e,_keybuf
		PL_L	$1aa,_keybuf
		PL_L	$1b2,_keybuf
		PL_L	$1be,_keybuf
		PL_L	$1c6,_keybuf
		PL_L	$1d2,_keybuf
		PL_L	$1da,_keybuf
		PL_L	$234,_keybuf
		PL_L	$23c,_keybuf
		PL_L	$248,_keybuf
		PL_L	$250,_keybuf
		PL_L	$25c,_keybuf
		PL_L	$264,_keybuf
		PL_L	$270,_keybuf
		PL_L	$278,_keybuf
		PL_L	$284,_keybuf
		PL_L	$28c,_keybuf
		PL_L	$2f0,_keybuf
		PL_L	$2f8,_keybuf
		PL_L	$304,_keybuf
		PL_L	$30c,_keybuf
		PL_L	$318,_keybuf
		PL_L	$320,_keybuf
		PL_L	$32c,_keybuf
		PL_L	$334,_keybuf
		PL_L	$340,_keybuf
		PL_L	$348,_keybuf
		PL_L	$5ce,_keybuf
		PL_L	$5da,_keybuf
		PL_L	$c80,_keybuf
		PL_L	$c88,_keybuf
		PL_L	$d78,_keybuf
		PL_L	$d80,_keybuf
		PL_L	$180c,_keybuf
		PL_END

	;v1
_pl_map1	PL_START
		PL_R	$1278				;disk check
		PL_R	$2614				;floppy motor off/deselect
		PL_R	$264e				;floppy motor on/select
		PL_L	$1da,_keybuf
		PL_L	$248,_keybuf
		PL_L	$4ce,_keybuf
		PL_L	$57a,_keybuf
		PL_L	$658,_keybuf
		PL_L	$66a,_keybuf
		PL_L	$686,_keybuf
		PL_L	$69a,_keybuf
		PL_L	$8aa,_keybuf
		PL_L	$8b6,_keybuf
		PL_L	$902,_keybuf
		PL_L	$92c,_keybuf
		PL_L	$93e,_keybuf
		PL_L	$95a,_keybuf
		PL_L	$96e,_keybuf
		PL_L	$a1c,_keybuf
		PL_L	$a94,_keybuf
		PL_END

	;v2
_pl_map2	PL_START
		PL_R	$168c				;floppy motor on/select
		PL_R	$16a6				;floppy seek to track 0
		PL_R	$1bd4				;floppy motor off/deselect
		PL_R	$1c0e				;floppy motor on/select
		PL_L	$1da,_keybuf
		PL_L	$248,_keybuf
		PL_L	$7ee,_keybuf
		PL_L	$896,_keybuf
		PL_L	$974,_keybuf
		PL_L	$986,_keybuf
		PL_L	$9a2,_keybuf
		PL_L	$9b6,_keybuf
		PL_L	$d36,_keybuf
		PL_L	$d42,_keybuf
		PL_L	$d8e,_keybuf
		PL_L	$db8,_keybuf
		PL_L	$dca,_keybuf
		PL_L	$de6,_keybuf
		PL_L	$dfa,_keybuf
		PL_L	$ea8,_keybuf
		PL_L	$f20,_keybuf
		PL_END

	;'CP' of v2, copied to the load address, must be position independent
_cp		clr.l	$84
		move.l	#$500,$88
		rts
_cpend

;============================================================================
; decrunch PP20 file like the original library
; the data is decrunched to address+$180 and then moved down
; IN:	a0 = address of packed data
;	d0 = packed length

_pp20		movem.l	d0-d7/a0-a5,-(a7)
		move.l	a0,a3				;A3 = address
		lea	($180,a0),a1
		move.l	(-4,a0,d0.l),d6			;unpacked length<<8
		bsr	_ppdecrunch
		lsr.l	#8,d6
		lea	($180,a3),a0
		move.l	a3,a1
.copy		move.b	(a0)+,(a1)+
		subq.l	#1,d6
		bne	.copy
		movem.l	(a7)+,d0-d7/a0-a5
		rts

; IN:	a0 = packed data
;	a1 = destination
;	d0 = packed length

_ppdecrunch	move.l	a1,a2
		lea	(4,a0),a5			;efficiency table
		add.l	d0,a0
		move.l	-(a0),d5
		moveq	#0,d1
		move.b	d5,d1				;bits to skip
		lsr.l	#8,d5
		add.l	d5,a1				;end of unpacked data
		move.l	-(a0),d5
		lsr.l	d1,d5
		move.b	#32,d7
		sub.b	d1,d7

.loop		bsr	.getbit
		tst.b	d1
		bne	.match
	;literal bytes
		moveq	#0,d2
.litlen		moveq	#2,d0
		bsr	.getbits
		add.w	d1,d2
		cmp.w	#3,d1
		beq	.litlen
.lit		moveq	#8,d0
		bsr	.getbits
		move.b	d1,-(a1)
		dbf	d2,.lit
		cmp.l	a1,a2
		bcs	.match
		rts

	;copy from already decrunched data
.match		moveq	#2,d0
		bsr	.getbits
		moveq	#0,d0
		move.b	(a5,d1.w),d0
		move.l	d0,d4				;D4 = offset bits
		move.w	d1,d2
		addq.w	#1,d2				;D2 = length
		cmp.w	#4,d2
		bne	.short
		bsr	.getbit
		move.l	d4,d0
		tst.b	d1
		bne	.long
		moveq	#7,d0
.long		bsr	.getbits
		move.w	d1,d3				;D3 = offset
.len		moveq	#3,d0
		bsr	.getbits
		add.w	d1,d2
		cmp.w	#7,d1
		beq	.len
		bra	.copy
.short		bsr	.getbits
		move.w	d1,d3
.copy		move.b	(a1,d3.w),d0
		move.b	d0,-(a1)
		dbf	d2,.copy
		cmp.l	a1,a2
		bcs	.loop
		rts

.getbit		moveq	#1,d0
; IN:	d0 = number of bits
; OUT:	d1 = bits
.getbits	moveq	#0,d1
		subq.w	#1,d0
.bit		lsr.l	#1,d5
		roxl.l	#1,d1
		subq.b	#1,d7
		bne	.next
		move.b	#32,d7
		move.l	-(a0),d5
.next		dbf	d0,.bit
		rts

;============================================================================

; keyboard, convert rawkey back to the raw format of CIA-A SDR for the game
; IN:	d0 = rawkey

_key_check	move.l	d0,-(a7)
		rol.b	#1,d0
		not.b	d0
		move.b	d0,(_keybuf).w
		move.l	(a7)+,d0
		rts

	INCLUDE	whdload/keyboard.s

;============================================================================

	END
