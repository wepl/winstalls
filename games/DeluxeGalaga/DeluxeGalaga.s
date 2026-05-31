
	INCDIR	Includes:
	INCLUDE whdload.i
	INCLUDE whdmacros.i
	INCLUDE	libraries/lowlevel.i
	INCLUDE lvo/dos.i

	IFD BARFLY
	IFNE AGA
	OUTPUT	"HD2:util/dev/whdload/deluxegalagaAGA/DeluxeGalagaAga.Slave"
	else
	OUTPUT	"HD2:util/dev/whdload/deluxegalaga/DeluxeGalagaEcs.Slave"
	ENDC
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	BOPT	wo-	;disable optimize warnings
	SUPER
	ENDC

;============================================================================
 
	IFD CHIPDEBUG
	; debug mode
		IFNE AGA
CHIPMEMSIZE	= $80000*4
FASTMEMSIZE	= $0
		ELSE
CHIPMEMSIZE	= $80000*2
FASTMEMSIZE	= $0000
		ENDC
	ELSE
		IFNE AGA
CHIPMEMSIZE	= $80000*4
FASTMEMSIZE	= $10000*3
 		ELSE
CHIPMEMSIZE	= $80000+$10000*4
FASTMEMSIZE	= $10000*3
 		ENDC
 	ENDC

NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %1111		;write protection of floppy drives

BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
HRTMON				;add support for HrtMON
	IFNE AGA
INITAGA				;enable AGA features
	ENDC
;INIT_AUDIO			;enable audio.device
;INIT_GADTOOLS			;enable gadtools.library
INIT_LOWLEVEL			;init lowlevel.library
;INIT_MATHFFP			;enable mathffp.library
;INIT_NONVOLATILE		;init nonvolatile.library
;INIT_RESOURCE			;init whdload.resource
IOCACHE		= 1024		;cache for the filesystem handler (per fh)
;JOYPADEMU			;use keyboard for joypad buttons
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
NO68020				;remain 68000 compatible
;POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
;SEGTRACKER			;add segment tracker
SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

QUIT_AFTER_PROGRAM_EXIT

;============================================================================

slv_Version	= 19
slv_Flags	= WHDLF_NoError
slv_keyexit	= $59	;F10

;============================================================================

	IFNE AGA
		INCLUDE	whdload/kick31.s
	else
		INCLUDE whdload/kick13.s
	ENDC

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Deluxe Galaga "
	IFNE AGA
		dc.b	"(AGA)"
	ELSE
		dc.b	"(ECS)"
	ENDC
	IFD CHIPDEBUG
		dc.b	" (DEBUG MODE)"
	ENDC
		dc.b	" V2.6",0
slv_copy	dc.b	"1995 Edgar M.Vigdal.",0
slv_info	dc.b	"Patch coded by CFou!, JOTD, Wepl",10
		dc.b	"Trainer by Arise from Decay",10,10
		dc.b	"Press `HELP` to get 5000 Money P1+P2",10
		dc.b	"Version 1.5 "
	INCBIN	".date"
		dc.b	0
slv_config	dc.b	"C1:X:Enter config menu:0;"
		dc.b	"C2:X:Unlimited Lives P1+P2:0;"
		dc.b	"C2:X:Unlimited Armor P1+P2:1;"
		dc.b	"C2:X:Start with 5000 money P1+P2:2"
		dc.b	0
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

; the following example is extensive because it saves all registers and
;	restores them before executing the program, the reason for this that some
;	programs (e.g. MANX Aztec-C) require specific registers properly setup on
;	calling
; in most cases a simpler routine is sufficient :-)

	IFD BOOTDOS

_bootdos
	lea	(_saveregs,pc),a0
	movem.l	d1-d6/a2-a6,(a0)
	move.l	(a7)+,(44,a0)
	move.l	(_resload,pc),a2	;A2 = resload

	;open doslib
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	lea	(dosbase,pc),a0
	move.l	d0,(a0)
	move.l	d0,a6	;A6 = dosbase

	; only check executable sizes
	lea	_program(pc),A0
	jsr	resload_GetFileSize(a2)

	IFNE AGA
	cmp.l	#409940,D0		; aga_unpacked
	beq.b	.ok
	cmp.l	#246892,D0		; aga_packed
	beq.b	.ok
	ELSE
	cmp.l	#287256,d0		; ecs_unpacked
	beq.b	.ok
	cmp.l	#125096,d0		; ecs_packed
	beq.b	.ok
	ENDC

	pea	TDREASON_WRONGVER
	jmp	(resload_Abort,a2)
.ok
	;load exe
	lea	(_program,pc),a0
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	_program_err

	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	cmp.l	#$487a0178,4(a1)
	bne	.not_crunched

	patch	4+$176(a1),.after
	bsr	_flushcache
	jmp	(4,a1)

.after	movem.l	(a7)+,d0-a6		;original
	move.l	(a7)+,d7
	lsr.l	#2,d7
	sub.l	#1,d7

.not_crunched
	lea	_pl_main,a0
	move.l	d7,a1
	jsr	(resload_PatchSeg,a2)

	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	moveq	#_args_end-_args,d0
	lea	(_args,pc),a0
	movem.l	(_saveregs,pc),d1-d6/a2-a6
	addq.l	#4,a1
	IFD	CHIPDEBUG
	move.l	a1,$100.W
	ENDC

	jsr	(a1)

	IFD QUIT_AFTER_PROGRAM_EXIT
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)
	ELSE
	;remove exe
	move.l	d7,d1
	move.l	(_dosbase,pc),a6
	jsr	(_LVOUnLoadSeg,a6)

	;return to CLI
	moveq	#0,d0
	move.l	(_saverts,pc),-(a7)
	rts

	ENDC

_program_err	jsr	(_LVOIoErr,a6)
	pea	(_program,pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	jmp	(resload_Abort,a2)

_HelpPressed
_HelpPressedAGA
;	 move.w	 #$1388,$76(a0)	   ; add 5k money p1		; no help key at the moment AGA
;	 move.w	 #$1388,$853e4		 ; add 5k money p2
;	 sub.l	 #$20000,a0
;	 move.l	 #$60000088,$779c(a0)	 ; skip save scores
	move.w	#$f0,$dff180		; just for test
	move.w	#$f00,$dff180		; just for test
	move.w	#$f0,$dff180		; just for test
	rts
_HelpPressedECS
;	 move.w	 #$1388,$77732		 ; add 5k money p1		; no help key at the moment ECS
;	 move.w	 #$1388,$77856		 ; add 5k money p2
;	 move.l	 #$60000088,$59a10	 ; skip save scores

_pl_main
	PL_START
	IFEQ AGA
		PL_IFC1
			PL_W	$5c2,$6000	; beq->bra force config menu
		PL_ENDIF
		PL_P	$1ebc,_HelpPressed	; remove workbench menu if help pressed
		PL_IFC2X 0
			PL_B	$3230,$60	; beq->bra skip hiscore save routine
			PL_NOPS $26fd0,2	; trainer unlimited lives
		PL_ENDIF
		PL_IFC2X 1
			PL_B	$3230,$60	; beq->bra skip hiscore save routine
			PL_PSS	$4d86,.armor,2	; patch clear routine (armor) at gamestart
			PL_NOPS	$26f78,2	; trainer unlimited armor
		PL_ENDIF
		PL_IFC2X 2
			PL_B	$3230,$60	; beq->bra skip hiscore save routine
			PL_PSS	$4d0c,.money,2	; patch clear routine (money) at gamestart
		PL_ENDIF
		PL_CW	$3d4c6			; debug ecs version (gfx bug)
	ELSE
		PL_IFC1
			PL_W	$622,$6000	; beq->bra force config menu
		PL_ENDIF
		PL_P	$1f3a,_HelpPressed	; remove workbench menu if help pressed
		; skip loop which reads the controllers 500 times for what??
		; and configures the ports to nonsense/nonworking
		PL_S	$36e4,$373e-$36e4
		; force joypad flag
		;PL_S	$16222,$16298-$16222
		PL_IFC2X 0
			PL_B	$32ae,$60	; beq->bra skip hiscore save routine
			PL_NOPS $21e54,2	; trainer unlimited lives
		PL_ENDIF
		PL_IFC2X 1
			PL_B	$32ae,$60	; beq->bra skip hiscore save routine
			PL_PSS	$4e38,.armor,2	; patch clear routine (armor) at gamestart
			PL_NOPS	$21dfc,2	; trainer unlimited armor
		PL_ENDIF
		PL_IFC2X 2
			PL_B	$32ae,$60	; beq->bra skip hiscore save routine
			PL_PSS	$4dbe,.money,2	; patch clear routine (money) at gamestart
		PL_ENDIF
	ENDC
	PL_END

.armor	clr.w	($3c,a3)
	move.b	#4,$ad(a3)			; add max armor p1
	move.b	#4,$161(a3)			; add max armor p2
	rts

.money	clr.l	($44,a3)
	clr.w	($48,a3)
	move.w	#5000,$46(a3)			; add 5k money
	rts

_program	dc.b	"GALAGA",0
_args		dc.b	10
_args_end	dc.b	0
	EVEN

_saveregs	dx.l	11
_saverts	dx.l	1
dosbase		dx.l	1

	ENDC

