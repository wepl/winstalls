;*---------------------------------------------------------------------------
;  :Program.    Unit-A
;  :Contents.   "F/A 18 Interceptor" Crack-Intro (02/06/1988)
;  :Author.     Stefano "Max Headroom/TEX" Pucino
;  :Requires.   Unit-A Intro (uncompressed, 57.844 bytes)
;  :Copyright.  Open Source (like GNU)
;  :Language.   68000 Assembler
;  :Translator. ASM-One v1.46 / Barfly v2.00
;  :To Do.
;
;  :History.
;               03.10.2001 - Version 1.0
;                NEW: Removed SoundTracker-Bug
;                     Removed useless UNIT-check
;---------------------------------------------------------------------------*

;======================================================================
; Load all includes and macros
;======================================================================

    INCDIR  INCLUDE:
    INCLUDE whdload.i
    INCLUDE whdmacros.i
    INCLUDE lvo/exec_lib.i
    INCLUDE lvo/dos_lib.i

;======================================================================
; Special BarFly options and optimisations
;======================================================================

    IFD BARFLY
        OUTPUT  "Unit-A.slave"              ; Name of the slave
        BOPT    O+ OG+                      ; Enable optimizing
        BOPT    ODd- ODe-                   ; Disable mul optimizing
        BOPT    w4-                         ; Disable 64k warnings
        SUPER                               ; Disable supervisor warnings
    ENDC

;======================================================================

_base   SLAVE_HEADER                        ; ws_Security + ws_ID
        dc.w    14                          ; WHDLoad version needed
        dc.w    WHDLF_NoError               ; Flags
        dc.l    $80000                      ; BaseMem Size (512 KB)
        dc.l    $0                          ; Exec Install
        dc.w    _Start-_base                ; Gameloader
        dc.w    0                           ; Current Dir
        dc.w    0                           ; Don't Cache
_keydebug
        dc.b    $5f                         ; DebugKey = HELP
_keyexit
        dc.b    $5d                         ; Exit Key = PrtScr
_expmem
        dc.l    0                           ; ExpMem (No Fast-Mem)
        dc.w    _name-_base                 ; Name of file
        dc.w    _copy-_base                 ; Copyright
        dc.w    _info-_base                 ; Additional informations

;======================================================================
; The description part
; Strings are zero terminated. 10 means Carricage Return (CR)
;======================================================================

_name
    dc.b    "F/A 18 Interceptor Crack-Intro",0  ; Full name of the intro
_copy
    dc.b    "1988 Unit-A",0                 ; Copyright information
_info                                       ; Who am I ? ;)
    dc.b    "--------Installed by:--------",10
    dc.b    "Max Headroom",10
    dc.b    "of",10
    dc.b    "The Exterminators",10
    dc.b    "-----------------------------",10

    dc.b    "Version 1.0 "                  ; Installer-version
    IFD      BARFLY
        IFND    .passchk
            DOSCMD  "WDate  >T:date"
            INCBIN  "T:date"                ; Include current date of slave
.passchk
        ENDC
    ENDC
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

;======================================================================
; Clear Memory
;======================================================================

; This isn't important, so you can also leave this out. But for
; a nice and real clean memory we will "simulate" a software reset
; by clearing the memory from $10000 to $80000.

    lea.l   $10000,a0                       ; Get Start into a0
    move.l  #$6fffff,d0                     ; How many bytes to clear ?
.clearloop
    clr.l   (a0)+                           ; Clear a0 ($10000)
    dbra    d0,.clearloop                   ; Continue until d0 is -1

;======================================================================
; Load & initialize the OSEmu module
;======================================================================

; Without this we wouldn't be able to use the DOS-function LoadSeg()
; to directly load and relocate an executable for our needs.

    lea     _OSEmu(pc),a0                   ; file name
    lea     $400.w,a1                       ; A3 = OSEmu base address
    jsr     (resload_LoadFileDecrunch,a2)   ; Load and decrunch OSEmu file

; Initialize OSEmu

    move.l  a2,a0                           ; resload
    lea     _base(pc),a1                    ; slave structure
    jsr     $400.w                          ; Start it

    move.w  #0,sr                           ; switch to user mode

; Open dos.library to provide file loading function

    moveq.l #0,d0                           ; Clear d0 (=lib-version not important)
    lea     _dosname(pc),a1                 ; load dos.library

    move.l  $4.w,a6                         ; Get execbase to a6
    jsr     _LVOOpenLibrary(a6)             ; Open the library
    lea.l   _dospointer(pc),a4              ; Load dos-pointer address to a4
    move.l  d0,(a4)                         ; Put dos-pointer to a4
    move.l  d0,a6                           ; Put it also to a6

;======================================================================
; Load the intro via dos.library LoadSeg() function
;======================================================================

    lea     _exe(pc),A0                     ; Get executable-filename
    move.l  a0,d1                           ; And copy it to d0 also
    jsr     _LVOLoadSeg(A6)                 ; Load the file now.

    lsl.l   #2,d0                           ; Left-scroll result by 2
    move.l  d0,a1                           ; Copy result to a1
    addq.l  #4,a1                           ; Add 4 to it

    sub.l   a0,a0                           ; Clear a0 now
    moveq.l #0,d0                           ; No pointer on argumentline

    lea     _introstart(pc),a2              ; Get variable
    move.l  a1,(a2)                         ; Save start-address of game

;======================================================================
; The now loaded and relocated executable will be fixed here.
;======================================================================

; We will fix some routines in the intro before we start the show.

    jsr     _fix(pc)                        ; Jump to the fixing-routine

    move.l  _introstart(pc),a1              ; Source-Address
    lea.l   _arg(pc),a0                     ; Argument line
    moveq.l #1,d0                           ; One argument
    jsr     (a1)                            ; Start the decruncher
    jmp     _exitintro(pc)                  ; Jump to EXIT-OF-INTRO

_fix
    move.l  _introstart(pc),a1              ; Source-Address
    move.w  #$4eb9,$8f6(a1)                 ; Poke JSR to destination
    pea     (_dbra,pc)                      ; Put SoundTracker-fix on Stack
    move.l  (a7)+,$8f8(a1)                  ; Write Stack to destination

    move.w  #$4e71,$8fc(a1)                 ; Add 2 NOP-words after the call
    move.w  #$4e71,$8fe(a1)                 ; to overwrite old command

    move.w  #$4e71,$420(a1)                 ; Remove call to "UNIT"-test
    move.w  #$4e71,$422(a1)                 ; and infinite loop
    rts

;======================================================================
; Exit slave
;======================================================================

_exitintro

; We put the "OK" reason to the stack and load the resident-base to a0.
; Then we abort the whole show giving WHD the reason.

    pea     TDREASON_OK                     ; Everything went O.K.
    move.l  (_resload,pc),a0                ; Put base to a0 for use
    jmp     (resload_Abort,a0)              ; Exit the slave

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

_OSEmu      dc.b    'OSEmu.400',0           ; Name of the OSEmu module to emulate DOS functions
_exe        dc.b    "Unit-A",0              ; Name of the Intro
    even
_resload    dc.l    0                       ; Address of resident loader
_dospointer dc.l    0                       ; DOS.library base pointer
_introstart dc.l    0                       ; Start-address after LoadSeg()
_arg        dc.b    $a                      ; Argument-line (CR=Empty)
_dosname    dc.b    'dos.library',0         ; DOS.library name
    even