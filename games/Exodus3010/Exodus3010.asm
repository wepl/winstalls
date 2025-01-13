_DSK

;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter example
;  :Author.	Wepl, JOTD
;  :Version.	$Id: kick13.asm 1.23 2019/01/19 18:53:35 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;		23.07.02 RUN patch added
;		04.03.03 full caches
;		20.06.03 rework for whdload v16
;		17.02.04 WHDLTAG_DBGSEG_SET in _cb_dosLoadSeg fixed
;		25.05.04 error msg on program loading
;		23.02.05 startup init code for BCPL programs fixed
;		04.11.05 Shell-Seg access fault fixed
;		03.05.06 made compatible to ASM-One
;		20.11.08 SETSEGMENT added (JOTD)
;		20.11.10 _cb_keyboard added
;		08.01.12 v17 config stuff added
;		10.11.13 possible endless loop in _cb_dosLoadSeg fixed
;		30.01.14 version check optimized
;		01.07.14 fix for Assign command via _cb_dosLoadSeg added
;		03.10.17 new options CACHECHIP/CACHECHIPDATA
;		28.12.18 segtracker added
;		19.01.19 test code for keyrepeat on osswitch added
;  :Requires.	kick13.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;		Wings of Fury slave
;		V1.0 done by cfou
;		- only password protection removed
;		V1.1
;		- support for Rob Northen encrypted version (SPS 599)		
;	
;---------------------------------------------------------------------------*
;_Flash
;_Flash2
;_Flash3
QUIT_AFTER_PROGRAM_EXIT

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
		OUTPUT	"exodus3010.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000*2	;size of chip memory
FASTMEMSIZE	= $20000*0		;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0001		;write protection of floppy drives

BLACKSCREEN			;set all initial colors to black

	IFD _DSK
BOOTBLOCK			;enable _bootblock routine
DISKSONBOOT			;insert disks in floppy drives
	ELSE
BOOTDOS				;enable _bootdos routine
CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
HDINIT				;initialize filesystem handler
DOSASSIGN			;enable _dos_assign routine

	ENDC

;BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSREAD			;enable _cb_dosRead routine
CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;FONTHEIGHT	= 8		;enable 80 chars per line
;HRTMON				;add support for HrtMON
;IOCACHE		= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulPriv	;|WHDLF_ClearMem 
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"",0
slv_name	dc.b	"Exodus 3010 ",0
slv_copy	dc.b	"1993 Demonware/Telmet.",0
slv_info	dc.b	"adapted for WHDLoad by CFou!",-1
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
		dc.b 	-1
	ENDC
		dc.b	"using Wepl's kick13 emul"
		dc.b	0
	IFGE slv_Version-17
slv_config	;dc.b	"C1:B:Unlimited lives for Bono & his friend;"
		;dc.b	"C2:L:Start Level:Default,L02,L03,L04,L05,L06,L07,L08,L09,L10,L11,L12,L13,L14,L15,L16,L17,L18,L19,L20,L21,L22;"
	ENDC
		dc.b	0
        EVEN


;============================================================================
; entry before any diskaccess is performed, no dos.library available

	IFD BOOTEARLY

_bootearly	blitz
		rts

	ENDC

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

	IFD BOOTBLOCK

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock	;blitz

		patch	$82(a4),_Patch
		bsr	_FlushCache
		
		jmp	(12,a4)

_Patch
	; crack

		movem.l	d1/a0-a2,-(a7)
		move.l	a0,a0
		move.l	#$1800,d0
		move.l	(_resload,pc),a2	;A2 = resload
		jsr	(resload_CRC16,a2)

		cmp.w	#$3bab,d0	;EN
		beq	.EN
		cmp.w	#$cde7,d0	
		beq	.DE
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.EN
		move.l	#$c3700050,d0
		bra.b	.common
.DE
		move.l	#$d9680050,d0
.common
		movem.l	(a7)+,d1/a0-a2
		nop

		;patchs	$22(a0),_Crack
		move.l	#$4e714e71,$22(a0)		; crack	
		move.l 	d0,$a760-$a498(a0) 		; crack
		movem.l	a0,-(a7)
		lea 	$a754-$a498(a0),a0
		move.l	a0,$dff080
		movem.l	(a7)+,a0	
	; end crack
		patch	$b7d0-$a498(a0),_ChangeDSK


		patch	$B006-$a498(a0),_PatchGame
	
		bsr	_FlushCache
	; end crack
	move.l	(a2),a1		;TrackDisk Handler
	jmp (a0)



_PatchGame
	movem.l	a0,-(a7)

	; patch EN
	bsr	_PatchLoadGameGen
	bsr	_PatchSaveGameGen

	; patch DE
	lea	-$90(a0),a0
	bsr	_PatchLoadGameGen
	lea	 $90(a0),a0
	lea	-$114(a0),a0
	bsr	_PatchSaveGameGen
	lea	 $114(a0),a0

	movem.l	(a7)+,a0
	movem.l	(a7)+,d4-d7
	unlk	a5
	rts

_PatchLoadGameGen
	cmp.l	#'GAME',-$1e2(a0)
	bne .noL
	
		move.l	#$7e016012,-$28e(a0) 	;$7c6ea		; remove alerte message
		move.w	#$5479,-$278(a0)	;$7c450
		patchs	-$23e(a0),_InsertSaveDisk3		; save
		move.w	#$4e71,-$23e+6(a0)

		patchs	-$204(a0),_InsertPreviousDsk
		bsr	_FlushCache
.noL
	rts

_PatchSaveGameGen
	cmp.l	#'GAME',-$51a(a0)
	bne .noS
	
		move.l	#$7e016012,-$53e(a0) 	;$7c6ea		; remove alerte message
		move.w	#$5479,-$528(a0)	;$7c450
		patchs	-$4d0(a0),_InsertSaveDisk3		; save
		move.w	#$4e71,-$4d0+6(a0)

		patchs	-$4a4(a0),_InsertPreviousDsk
		bsr	_FlushCache
.noS

	rts

;*******************

;_Crack
;	move.l	a0,a6
;	move.l #$c3700050,$a760 	; crack EN
;	move.l #$d9680050,$a760 	; crack De
;	move.l	#$a754,$dff080
;	rts
;*******************

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
_cont	movem.l	d0-a6,-(a7)
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



_cb_keyboard
	cmp.B	#$58,d0
	bne	.no
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$f0,$dff180
	move.w #$0,$dff180

.no


	rts



_Keyboard
		move.b	$bfec01,d0
		not.b	d0		; original code
		movem.l	d0-d1/a0,-(sp)
		;not.b	d0
		ror.b	#1,d0
		cmp.b	_keyexit(pc),d0
		beq	_exit
		cmp.b	#$58,d0		; F9 pressed? (color test)
		bne	.noflash
		move.w	#$f0,$dff180
		move.w	#$f0,$dff180
		;move.w	#$0,$dff180
.noflash

		movem.l	(sp)+,d0-D1/a0
		rts

;======================================================================
_FlushCache
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_FlushCache(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts
;======================================================================

_END_VBL_INTERUPT:
	BSR	BEAM_DELAY
;	move.w	#$90,$dff180
	MOVE.W	#$70,$dff09c
	movem.l	(a7)+,d0-a6
	rte
_Delay=14

BEAM_DELAY
        move.l  d0,-(a7)
	;move.l	_custom2(pc),d0
	;beq	.skip
	subq	#1,d0
	beq	.exit
        mulu  #_Delay,D0
	bra	.loop1
.skip
        move  #_Delay,D0
.loop1
        move.w  d0,-(a7)
        move.b  $dff006,d0      ; VPOS
	;move.w	d0,$dff180

.loop2  cmp.b   $dff006,d0
        beq 	  .loop2
        move.w  (a7)+,d0
        dbf     d0,.loop1
.exit
        move.l  (a7)+,d0
     	rts

;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_debug		pea	TDREASON_DEBUG
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
		bra	_end
_mustregister	pea	TDREASON_MUSTREG
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_tag2
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
;		dc.l	WHDLTAG_CUSTOM3_GET
;_custom3	dc.l	0
;		dc.l	WHDLTAG_CUSTOM4_GET
;_custom4	dc.l	0
;		dc.l	WHDLTAG_CUSTOM5_GET
;_custom5	dc.l	0
;		dc.l	WHDLTAG_BUTTONWAIT_GET
;_ButtonWait	dc.l	0
		dc.l	0


	END


_DelayVBL_PAL
	move.w #$90,$dff180
	movem.l d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne .wait
	movem.l	(a7)+,d0
	move.w #$000,$dff180
	rts
	END


_DelayVBL_NTSC
;	move.w #$0f0,$dff180
	movem.l d0,-(a7)
.wait	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#262<<8,d0
	bne .wait
	movem.l	(a7)+,d0
;	move.w #$000,$dff180
	rts
