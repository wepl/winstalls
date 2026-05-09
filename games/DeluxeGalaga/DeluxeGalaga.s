;_Flash
	INCDIR	Includes:
	INCLUDE whdload.i
	INCLUDE whdmacros.i
	INCLUDE	libraries/lowlevel.i
	INCLUDE lvo/dos.i


	IFD BARFLY
	IFNE AGA
	OUTPUT	"DeluxeGalagaAga.Slave"
	else
	OUTPUT	"DeluxeGalagaEcs.Slave"
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
DOSASSIGN			;enable _dos_assign routine
FONTHEIGHT	= 8		;enable 80 chars per line
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
POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
;SEGTRACKER			;add segment tracker
SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

QUIT_AFTER_PROGRAM_EXIT
; affects lowlevel.s: if button combination pressed, quits to wb
QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY

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

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate	>T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	
slv_CurrentDir	dc.b	"data",0
 IFNE AGA
slv_name	dc.b	"Deluxe Galaga (AGA)"
 else
slv_name	dc.b	"Deluxe Galaga (ECS)"
 ENDC
 IFD CHIPDEBUG
	dc.b	" (DEBUG MODE)"
 ENDC
 dc.b " V2.6",0
 
slv_copy	dc.b	"1995 Edgar M.Vigdal.",0
slv_info	dc.b	"Patch coded by CFou! & JOTD",10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0
slv_config
		DC.B	"C1:X:Enter config menu:0"
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

   ;get tags
      	lea   	(_tag,pc),a0
      	move.l 	_resload(pc),a2
      	jsr   	(resload_Control,a2)

	;open doslib
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	lea	(dosbase,pc),a0
	move.l	d0,(a0)
	move.l	d0,a6	;A6 = dosbase

	;assigns
	lea	(_disk1,pc),a0
	sub.l	a1,a1
	bsr	_dos_assign

	;check version
	bsr	check_version

	;load exe
	lea	(_program,pc),a0
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7	;D7 = segment
	beq	_program_err


	IFD DEBUG
	;set debug
	clr.l	-(a7)
	move.l	d7,-(a7)
	pea	WHDLTAG_DBGSEG_SET
	move.l	a7,a0
	jsr	(resload_Control,a2)
	add.w	#12,a7
	ENDC

	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	cmp.l	#$487a0178,4(a1)
	bne	.not_crunched


	pea	_AfterDecunch(pc)
	move.w  #$4ef9,$17a(a1)
	move.l	(a7)+,$17a+2(a1)
	bsr	_flushcache
	bra.b	.launch
.not_crunched
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	add.l	#4,a1
	move.l	a1,d0
	bsr	Patch
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
.launch
	moveq	#_args_end-_args,d0
	lea	(_args,pc),a0
	movem.l	(_saveregs,pc),d1-d6/a2-a6
	addq.l	#4,a1
	IFD	CHIPDEBUG
	move.l	a1,$100.W
	ENDC


	jsr	(a1)
_fin

	IFD QUIT_AFTER_PROGRAM_EXIT
	pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)
	ELSE
	;remove exe
	move.l	d7,d1
	move.l	(dosbase,pc),a6
	jsr	(_LVOUnLoadSeg,a6)

	;return to CLI
	moveq	#0,d0
	move.l	(_saverts,pc),-(a7)
	rts


	ENDC
check_version:
	; only check executable sizes
	movem.l	d0-d1/a1,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)
	
	IFNE AGA
	cmp.l	#409940,D0
	beq.b	.ok  ; aga_unpacked
	cmp.l	#246892,D0
	beq.b	.ok	;  aga_packed
	ELSE
	cmp.l	#287256,d0
	beq.b	.ok	;  ecs_unpacked
	cmp.l	#125096,d0
	beq.b	.ok	;  ecs_packed
	ENDC

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	movem.l	(a7)+,d0-d1/a1
	rts
_program_err	jsr	(_LVOIoErr,a6)
	pea	(_program,pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	jmp	(resload_Abort,a2)

_AfterDecunch
	movem.l	(a7)+,d0-a6
	move.l	(a7),d0
	move.l	a0,a5

Patch
	IFD	_Flash
.t 		move.w	#$f0,$dff180		; just for test
		btst	#$6,$bfe001
		bne 	.t
	ENDC

	movem.l	d0-d1/a0-a2,-(a7)
	move.l	d0,a0
	bsr	_removeHelpECSAGA
	move.l	-4(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	cmp.l	#$01fc0003,$2d28(a0)
	bne	.aga
	; ECS version
	move.l	#$01fc0000,$2d28(a0) ; debug ecs version (gfx bug)
	bra.b	.end
.aga
	lea	_pl_main(pc),a0
	move.l	_resload(pc),a2
	IFD	CHIPDEBUG
	move.l	A1,$100.W
	ENDC
	jsr	resload_Patch(a2)
.end
	movem.l	(a7)+,d0-d1/a0-a2

	rts

_removeHelpECSAGA
	movem.l	d0,-(a7)
	move.l	_custom1(pc),d0
; ECS
	cmp.w	#$23f9,$1ec6(a0)
	bne 	.noECS
	cmp.w	#$23f9,$1ec6+10(a0)
	bne 	.noECS
	patch	$1ec6(a0),_HelpPressed		; remove workbench menu if help pressed
	tst.l 	d0	
	beq 	.noECS
	move.w 	#$6000,$5c2(a0)			; force config menu
.noECS
; AGA
	cmp.w	#$23f9,$1f3a(a0)
	bne 	.noAGA
	cmp.w	#$23f9,$1f3a+10(a0)
	bne 	.noAGA
	patch	$1f3a(a0),_HelpPressed		; remove workbench menu if help pressed
	tst.l 	d0	
	beq 	.noAGA
	move.w 	#$6000,$622(a0)			; force config menu
.noAGA	movem.l	(a7)+,d0
	rts


_HelpPressed
	move.w	#$f0,$dff180		; just for test
	move.w	#$f00,$dff180		; just for test
	move.w	#$f0,$dff180		; just for test
	rts
_pl_main
	PL_START
	; skip loop which reads the controllers 500 times for what??
	; and configures the ports to nonsense/nonworking
	PL_S	$036e4,$373e-$36e4
	; force joypad flag
	;PL_S	$16222,$16298-$16222
	PL_END

_disk1		dc.b	"df0",0	;for Assign
_program	dc.b	"GALAGA",0
_args		dc.b	10
_args_end	dc.b	0
	EVEN

_saveregs	ds.l	11
_saverts	dc.l	0
dosbase		dc.l	0
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0       ; End

	ENDC

