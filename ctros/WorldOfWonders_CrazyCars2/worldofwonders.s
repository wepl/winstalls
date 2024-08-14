;*---------------------------------------------------------------------------
;  :Program.    World of Wonders
;  :Contents.   "Crazy Cars II" Cracktro
;  :Author.     Stefano "Max Headroom/TEX" Pucino
;  :Requires.   WoW-Cracktro (ByteKiller v1.3, 55.832 bytes)
;  :Copyright.  Open Source (like GNU)
;  :Language.   68000 Assembler
;  :Translator. ASM-One v1.21 / Barfly v2.00
;  :To Do.
;  :History.	06.10.2001 - Version 1.0
;                NEW: Fixed empty DBRA-loop (SoundTracker-bug)
;		2024-08-14 by Wepl
;		 fixed for 68000, _resload was at odd address
;		 remove osemu using
;		 add keyboard quitter
;		 some gfx fixes
;---------------------------------------------------------------------------*

;======================================================================
; Load all includes and macros
;======================================================================

    INCDIR  INCLUDE:
    INCLUDE whdload.i
    INCLUDE whdmacros.i

;======================================================================

_base   SLAVE_HEADER                        ; ws_Security + ws_ID
    dc.w    14                              ; WHDLoad version needed
    dc.w    WHDLF_NoError                   ; Flags
    dc.l    $80000                          ; BaseMem Size (512 KB)
    dc.l    $0                              ; Exec Install
    dc.w    _Start-_base                    ; Introloader
    dc.w    0                               ; Current Dir
    dc.w    0                               ; Don't Cache
_keydebug
    dc.b    $5f                             ; DebugKey = HELP
_keyexit
    dc.b    $5d                             ; Exit Key = PrtScr
_expmem
    dc.l    0                               ; ExpMem (No Fast-Mem)
    dc.w    _name-_base                     ; Name of file
    dc.w    _copy-_base                     ; Copyright
    dc.w    _info-_base                     ; Additional informations

;======================================================================
; The description part
; Strings are zero terminated. 10 means Carricage Return (CR)
;======================================================================

_name                                       ; Full name of the game
    dc.b    "Crazy Cars 2 Cracktro",0 
_copy                                       ; Copyright information
    dc.b    "1989 World of Wonders",0
_info                                       ; Who am I ? ;)
    dc.b    "--------Installed by:--------",10
    dc.b    "Max Headroom",10
    dc.b    "of",10
    dc.b    "The Exterminators",10
	db	'Updated by Wepl',10
    dc.b    "-----------------------------",10
    dc.b    "Version 1.1 "                  ; Installer-version
	INCBIN	.date
    dc.b    0                               ; End this string
    even

;======================================================================
; The magic part. Now we start the slave ;)
;======================================================================

_Start                                      ; A0 = resident loader

; This routine simply loads the empty variable '_resload' to a1 and
; puts the resident-loader (location=A0) to it.

    lea     _resload(pc),a1                 ; Get Slave-base
    move.l  a0,(a1)                         ; Save for later use
    move.l  a0,a2                           ; A2 = resload, too

; Now we enable the Instruction-Cache but disable the Data-Cache at the
; same time. This gives us a very huge compatibility.

    move.l  #CACRF_EnableI,d0               ; Enable CPU Instruction-Cache
    move.l  d0,d1                           ; Mask
    jsr     (resload_SetCACR,a0)            ; WHD SetCache()

	;install keyboard quitter
	bsr	_SetupKeyboard

;======================================================================
; Load the intro
;======================================================================

    lea     _exe(pc),A0                     ; Get executable-filename
	lea	$2000,a3
	move.l	a3,a1
	jsr	(resload_LoadFileDecrunch,a2)
	move.l	a3,a0
	sub.l	a1,a1
	jsr	(resload_Relocate,a2)

	pea	(_patch,pc)
	move.l	(sp)+,($AC,a3)
	jmp	(a3)			;decrunch bytekiller

_patch	lea	$38000,a3
	lea	_pl,a0
	move.l	a3,a1
	movea.l	(_resload,pc),a2
	jsr	(resload_Patch,a2)

	moveq	#0,d0			;Disable CPU Instruction-Cache
	move.l  #CACRF_EnableI,d1	;mask
	jsr	(resload_SetCACR,a2)

	move	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(_custom+dmacon)	; expected by ctro
	jsr	(a3)

;======================================================================
; Exit slave
;======================================================================

; We put the "OK" reason to the stack and load the resident-base to a0.
; Then we abort the whole show giving WHD the reason.

    pea     TDREASON_OK                     ; Everything went O.K.
    move.l  (_resload,pc),a0                ; Put base to a0 for use
    jmp     (resload_Abort,a0)              ; Exit the slave

;======================================================================
; patches
;======================================================================

_pl	PL_START
	PL_S	$3e8,4				;open gfx
	PL_PS	$4be,_dmaon
	PL_S	$4ee,4				;exec.Forbid
	PL_PS	$504,_waitvb
	PL_S	$524,8				;restore gfx clist
	PL_PSS	$EE0,_dbra,2			; Address of the SoundTracker-loop
	PL_END

_dmaon	move.l	a0,(_custom+cop1lc)		;original
	waitvb
	move	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER,(_custom+dmacon)
	rts

	; avoid gfx trash when disable dma
_waitvb	lea	_custom,a0			;original
	waitvb	a0
	rts

;======================================================================
; FIX Routines
;======================================================================

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
DBRALOOPS   = 5

    movem.l d0-d7/a0-a6,-(a7)               ; Save registers
    move.w  #DBRALOOPS,d1                   ; How many loop-runs to run ?
.1  move.b  ($dff006),d0                    ; Get beam-position from VHPOSR
.2  cmp.b   ($dff006),d0                    ; Compare actual position with d0
    beq.b   .2                              ; If found, test again (old bug)
    dbf     d1,.1                           ; Repeat the loop
    movem.l (a7)+,d0-d7/a0-a6               ; Restore registers
    rts                                     ; And return to old code

_exe        dc.b    "wow-crak.exe",0        ; Name of the intro-executable
	EVEN

;======================================================================

	INCLUDE	whdload/keyboard.s

;======================================================================

_resload	dx.l	0		;address of resident loader

;======================================================================

	end
