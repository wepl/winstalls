;*---------------------------------------------------------------------------
;  :Program.	Millennium2-2.asm
;  :Contents.	Slave for "Millennium 2�2" from Electronic Dreams
;  :Author.	Mr.Larmer & Wepl
;  :Original	v1 Harry
;		v2 Carlo Pirri
;		v3 Wolfgang Unger PAL
;		v4 Wolfgang Unger NTSC
;		v5 de Retroplay
;  :Version.	$Id: Millennium.asm 1.9 2018/10/30 22:02:53 wepl Exp wepl $
;  :History.	22.02.01 ml adapted for kickemu
;		24.02.01 savegame support added, cleanup
;		13.03.01 extro works now
;			 length of loadgames fixed
;		19.04.01 support for v2 added
;		26.04.01 support for v3 added
;		26.02.05 support for v4 added
;		30.10.18 new random generator to avoid same asteroids sequence
;		26.01.25 support for v5 added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:me/millennium2�2/Millennium2-2.Slave"
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= $7000		;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0001		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
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

slv_Version	= 16
slv_Flags	= WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	0
slv_name	dc.b	"Millennium 2�2",0
slv_copy	dc.b	"1989 Ian Bird / Electric Dreams",0
slv_info	dc.b	"adapted by Mr.Larmer & Wepl & Harry",10
		dc.b	"Version 1.5 "
		INCBIN	.date
		dc.b	0
_savename	dc.b	"Disk.2",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;a1 = ioreq ($2c+a5)
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock	

	;add random to _rnd
		lea	_vbisav,a0
		move.l	($6c),(a0)
		lea	_rndvbi,a0
		move.l	a0,$6c

	;check for savedisk
		lea	(_savename,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	.saveok
	;create savedisk
		lea	(_savename,pc),a0	;name
		lea	$20000,a1		;address
		move.l	#$16c65710,($3fc,a1)	;diskid
		move.l	#$1600,d0		;length
		move.l	#0,d1			;offset
		jsr	(resload_SaveFileOffset,a2)
	;savedisk ok
.saveok

	IFD DEBUG
	;protect kickstart
		move.l	#$40000,d0
		move.l	(_expmem),a0
		jsr	(resload_ProtectWrite,a2)
	ENDC

	;check version
		move.l	#$400,d0
		move.l	a4,a0
		jsr	(resload_CRC16,a2)
		
		lea	_plb1,a0
		cmp.w	#$C367,D0		;v1 v2
		beq	_bootblock_ok
		lea	_plb3,a0
		cmp.w	#$4a80,d0		;v3
		beq	_bootblock_ok
		lea	_plb4,a0
		cmp.w	#$80f3,D0		;v4
		beq	_bootblock_ok
		lea	_plb5,a0
		cmp.w	#$ab62,D0		;v5
		beq	_bootblock_ok
		
_wrongver	pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

	;call bootblock
_bootblock_ok	move.l	a4,a1
		jsr	(resload_Patch,a2)
		lea	($2c,a5),a1
		jmp	(12,a4)

_plb1		PL_START
		PL_S	$24,6			;skip set stack
		PL_S	$326,6			;skip set stack
		PL_PA	$32e,_intro123
		PL_S	$356,6			;skip set stack
		PL_PA	$35e,_main123
		PL_END

_plb3		PL_START
		PL_S	$24,6			;skip set stack
		PL_S	$2d2,6			;skip set stack
		PL_PA	$2da,_intro123
		PL_S	$302,6			;skip set stack
		PL_PA	$30a,_main123
		PL_END

_plb4		PL_START
		PL_S	$2a,2			;empty loop
		PL_P	$9c,_pre4
		PL_END

_plb5		PL_START
		PL_S	$16,2			;empty loop
		PL_P	$82,_pre5
		PL_END

_pre4		lea	_plp4,a6
		bra	_pre

_pre5		lea	_plp5,a6

_pre		movem.l	d0/a0,-(a7)
		move.l	a0,a1			;address = $12800/v4 $61000/v5
		move.l	a6,a0
		move.l	_resload,a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,_MOVEMREGS
		rts

_plp4		PL_START
		PL_S	0,$242			;stack
		PL_PS	$2c2,_diskinsert
		PL_P	$314,.go
		PL_END

.go		move.w	$12800+$234,d0		;original
		move.l	(a7)+,d1
		cmp.l	#$41000,d1
		beq	_intro
		cmp.l	#$13000,d1
		beq	_main4
		illegal

_plp5		PL_START
		PL_S	0,$242			;stack
		PL_PS	$2ae,_diskinsert
		PL_P	$300,.go
		PL_END

.go		move.w	$12800+$234,d0		;original
		move.l	(a7)+,d1
		cmp.l	#$31000,d1
		beq	_intro
		cmp.l	#$61800,d1
		beq	_main5
		illegal

	;somehow: if the intro is running a bit longer the disk from
	;the drive is no longer inserted, so we make a disk change
	;which will reinsert the disk on the next trd_task (kick13.s)
_diskinsert	move.l	a1,-(a7)
		moveq	#0,d0			;unit
		moveq	#1,d1			;disk
		bsr	_trd_changedisk
		movem.l	(a7)+,a1
		rts

_intro123	move.l	#$41000,d1		;start address v1-4=41000 v5=31000
_intro		movem.l	d0-d1/a0-a2,-(a7)

		move.l	#$1000,d0
		move.l	d1,a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)

		lea	_pli1,a0
		cmp.w	#$7b78,d0
		beq	.go
		lea	_pli2,a0
		cmp.w	#$6ce7,d0
		beq	.go
		lea	_pli4,a0
		cmp.w	#$f056,d0
		beq	.go
		lea	_pli5,a0
		cmp.w	#$21c3,d0
		bne	_wrongver
.go
		move.l	(4,a7),a1		; d1 = start address
		jsr	(resload_Patch,a2)

		movem.l	(a7)+,_MOVEMREGS
		move.l	#$a8d398fb,d0		; copylock id
		move.l	d1,-(a7)
		rts

_pli1		PL_START
		PL_PS	$96A,.remint
		PL_S	$f26,14			; green screen & stack
		PL_S	$F40,$1e		; stack
		PL_S	$10AA,4			; stack
		PL_S	$7fc,$41808-$417fc	; color
		PL_R	$810			; color
		PL_END

.remint		move.l	#$4191A,a1
		moveq	#5,d0
		rts

_pli2		PL_START
		PL_S	0,$14f6			; skip protection
		PL_PS	$f40,.remint
		PL_S	$14fc,14		; green screen & stack
		PL_S	$1510,$1e		; stack
		PL_S	$167a,4			; stack
		PL_S	$dd2,$41808-$417fc	; color
		PL_R	$de6			; color
		PL_END

.remint		move.l	#$41ef0,a1
		moveq	#5,d0
		rts

_pli4		PL_START
		PL_PS	$876,.remint
		PL_S	$b42,$1e		; stack
		PL_S	$c14,4			; stack
		PL_END

.remint		move.l	#$41826,a1
		moveq	#5,d0
		rts

_pli5		PL_START
		PL_PS	$7b4,.remint
		PL_S	$a88,$1e		; stack
		PL_S	$b82,4			; stack
		PL_END

.remint		move.l	#$31764,a1
		moveq	#5,d0
		rts

_change2	movem.l	d0-d1,-(a7)
		moveq	#0,d0			;unit
		moveq	#2,d1			;disk
		bsr	_trd_changedisk
		movem.l	(a7)+,d0-d1
		moveq	#0,d7
		rts

_change1	moveq	#0,d0			;unit
		moveq	#1,d1			;disk
		bsr	_trd_changedisk
		add.l	#$7696c-$7692c-6,(a7)	;same for v4
		rts

_loadgame	move.l	d1,d2
		lea	(_savename),a0
		move.l	(_resload),a1
		jsr	(resload_GetFileSize,a1)
		move.l	d2,d1
		sub.l	d7,d0			;d7 = offset
		cmp.l	#$4e20,d0
		blo	.q
		move.l	#$4e20,d0
.q		rts

_main123	lea	$68000,a3
		lea	_plm123,a0
		bra	_main

_main5		lea	_plm5,a0
		bra	_main45

_main4		lea	_plm4,a0
_main45		move.l	d1,a3			;v4=$13000 v5=$61800

_main		move.l	(_expmem),d0		;kickstart
		add.l	#$d300,d0		;offset used by game
		move.l	(-4,a0),d1
		move.l	d0,(a3,d1.l)
		move.l	(-8,a0),d1		;obsolete because _rnd patch!
		move.l	d0,(a3,d1.l)

		move.l	a3,a1
		move.l	_resload,a2
		jsr	(resload_Patch,a2)

		jmp	(a3)

		dc.l	$e7c,$110f2		;random generator patches
_plm123		PL_START
	;	move.w	#$7001,$68f68		;df1:
	;	move.b	#0,$6e1fd
		PL_P	$e78,_rnd
		PL_S	$e6e4,$700-$6e4		;skip set stack
		PL_PS	$1174,_change2
		PL_W	$856e,3			;disable format savedisk
		PL_PS	$e38e,_loadgame
		PL_PS	$e92c,_change1
		PL_END

		dc.l	$af2,$10c92		;random generator patches
_plm4		PL_START
		PL_P	$aee,_rnd
		PL_S	$e384,$a0-$84		;skip set stack
		PL_PS	$dea,_change2
		PL_W	$820c,3			;disable format savedisk
		PL_PS	$e02c,_loadgame
		PL_PS	$e590,_change1
		PL_END

		dc.l	$9a0,$10f1c		;random generator patches
_plm5		PL_START
		PL_P	$99c,_rnd
		PL_S	$e5c2,$a0-$84		;skip set stack
		PL_PS	$c98,_change2
		PL_W	$842c,3			;disable format savedisk
		PL_PS	$e26e,_loadgame
		PL_PS	$e7ce,_change1
		PL_END

_rnd	movem.l	d1-d3/a0,-(a7)
	lea	.RNDNUM(pc),a0
	moveq	#8-1,d3
	move.l	(a0),d0
.rndloop
	move.b	d0,d1
	move.b	d0,d2
	lsr.b	#3,d1
	lsr.b	#1,d2
	eor.b	d1,d2
	lsr.b	#1,d2
	roxr.l	#1,d0
	move.l	d0,(a0)
	dbf	d3,.rndloop
	movem.l	(a7)+,d1-d3/a0
	bclr	#0,d0
	rts

.RNDNUM	dc.l	20180921

_rndvbi		move.l	d0,-(a7)
		bsr	_rnd
		move.l	(a7)+,d0
		move.l	_vbisav,-(a7)
		rts

_vbisav		dx.l	1

;============================================================================

	END

