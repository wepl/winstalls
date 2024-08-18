;*---------------------------------------------------------------------------
;  :Program.    Unit-A
;  :Contents.   "F/A 18 Interceptor" Crack-Intro (02/06/1988)
;  :Author.     Stefano "Max Headroom/TEX" Pucino, Wepl
;  :Requires.   Unit-A Intro (uncompressed, 57.844 bytes)
;  :Copyright.  Open Source (like GNU)
;  :Language.   68000 Assembler
;  :Translator. ASM-One v1.46 / Barfly v2.00
;  :To Do.
;  :History.    03.10.2001 - Version 1.0
;                NEW: Removed SoundTracker-Bug
;                     Removed useless UNIT-check
;		2024-08-18 Wepl:
;		  changed from osemu to kickemu
;		  added text message output
;---------------------------------------------------------------------------*
;======================================================================
; Load all includes and macros
;======================================================================

	INCLUDE whdload.i
	INCLUDE	lvo/dos.i

;======================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= $0		;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %0000		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;======================================================================
; The description part
; Strings are zero terminated. 10 means Carricage Return (CR)
;======================================================================

slv_CurrentDir	dc.b	0
slv_name
    dc.b    "F/A 18 Interceptor Crack-Intro",0  ; Full name of the intro
slv_copy
    dc.b    "1988 Unit-A",0                 ; Copyright information
slv_info                                       ; Who am I ? ;)
    dc.b    "--------Installed by:--------",10
    dc.b    "Max Headroom",10
    dc.b    "of",10
    dc.b    "The Exterminators",10
    db	    "Updated by Wepl",10
    dc.b    "-----------------------------",10

    dc.b    "Version 1.1 "                  ; Installer-version
	INCBIN	.date
    dc.b    0                               ; End this string
    even

;======================================================================
; The magic part. Now we start the slave ;)
;======================================================================

_bootdos

	;print text message
		lea	$20000,a3
		lea	_text,a0
		move.l	a3,a1
		move.l	_resload,a2
		jsr	(resload_LoadFileDecrunch,a2)
		move.l	d0,d3			;length

		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		jsr	(_LVOOutput,a6)
		move.l	d0,d1
		move.l	a3,d2
		jsr	(_LVOWrite,a6)

;======================================================================
; Load the intro
;======================================================================

    lea     _exe(pc),A0                     ; Get executable-filename
	move.l	a3,a1
	jsr	(resload_LoadFileDecrunch,a2)
	move.l	a3,a0
	sub.l	a1,a1
	jsr	(resload_Relocate,a2)

	lea	_pl,a0
	move.l	a3,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)

	jsr	(a3)

	; wait for releasing RMB
.wait	btst	#10-8,(_custom+potinp)
	beq	.wait

;======================================================================
; Exit slave
;======================================================================

; We put the "OK" reason to the stack and load the resident-base to a0.
; Then we abort the whole show giving WHD the reason.

    pea     TDREASON_OK                     ; Everything went O.K.
    move.l  (_resload,pc),a0                ; Put base to a0 for use
    jmp     (resload_Abort,a0)              ; Exit the slave

;======================================================================
; FIX Routines
;======================================================================

_pl	PL_START
	PL_PSS	$8f6,_dbra,4
	PL_S	$420,4				; Remove call to "UNIT"-test and infinite loop
	PL_END

;======================================================================
; We have to fix an empty DBRA-loop at $2e27e !
; It's the well-known SoundTracker bug ;)
; But for a better understanding of WHAT a _dbra_ loop is, we will step
; back in time...
;
; Remember old BASIC days ? ...
;
; 10 FOR a = 0 TO 10000
; 20 NEXT a
; 30 PRINT "Some time has passed"
;
; This will count up the variable "a" from 0 to 10.000 and print out a text.
; On the C64 you could be sure that this count-up would take a specific
; time. And this time is the same on ALL C64 computers sold.
; This also happened on the Amiga. On the old 7.14 MHz CPU you could be
; sure that such a loop will do the work on every Amiga sold.
; But there is a "small" problem... How about a faster processor ? >7 MHz ?
; The loop will reach the end MUCH faster than previsted and the routine
; will be f+cked up faster than you can think of. So we have to replace
; this good-ol' bad habit with a more real one.
;
; This is the ASM-pendant of the BASIC example:
;
; wait_now:
;   move.l  #$12c,d0            ; Ammount of time to wait
; dbra_loop:
;   dbra    d0,dbra_loop        ; Decrease d0 and branch again to loop
;                                 if not zero !
;
; On FAST processors (>7,14 MHz) this will surely cause problems. In this
; case, the SoundTracker-player will hick and skip some samples from time
; to time. ;)
;
; This will be replaced by a more nice vertical-beam-wait routine...
;======================================================================

_dbra:
    movem.l d0-d7/a0-a6,-(a7)               ; Save registers
    move.w  #10,d1                          ; How many loop-runs ? (=10)
.1  move.b  ($dff006),d0                    ; Get beam-position from VHPOSR
.2  cmp.b   ($dff006),d0                    ; Compare actual position with d0
    beq.b   .2                              ; If found, test again (old bug)
    dbf     d1,.1                           ; Repeat the loop (10 times)
    movem.l (a7)+,d0-d7/a0-a6               ; Restore registers
    rts                                     ; And return to old code

;======================================================================
; Additional data and variables
;======================================================================

_exe        dc.b    "Unit-A",0              ; Name of the Intro
_text		db	"rage",0		; text message file

