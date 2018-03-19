;*---------------------------------------------------------------------------
;  :Modul.      kick31.asm
;  :Contents.   kickstart 3.1 booter
;  :Author.     Cfou!
;  :Version.    $Id: UFO_All.asm 1.1 2015/07/12 18:18:09 wepl Exp wepl $
;  :History.    04.03.03 started
;               22.06.03 rework for whdload v16
;		12.07.15 IOCACHE set
;  :Requires.   kick31.s
;  :Copyright.  Public Domain
;  :Language.   68000 Assembler
;  :Translator. Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

_CD32 ; same like aga
;_ECS
;_AGA

        INCDIR  Includes:
        INCLUDE whdload.i
        INCLUDE whdmacros.i
        INCLUDE lvo/dos.i

        IFD BARFLY
        IFD _CD32
        OUTPUT  "wart:u/UFO/UFO.Slave"
        ENDC
        IFD _ECS
        OUTPUT  "sdh2:UFOEcs/UFO.Slave"
        ENDC
        BOPT    O+                              ;enable optimizing
        BOPT    OG+                             ;enable optimizing
        BOPT    ODd-                            ;disable mul optimizing
        BOPT    ODe-                            ;disable mul optimizing
        BOPT    w4-                             ;disable 64k warnings
        BOPT    wo-                             ;disable optimize warnings
        SUPER
        ENDC

;  ============================================================================

 IFD _ECS
CHIPMEMSIZE     = $100000
FASTMEMSIZE     = $0000
 else
CHIPMEMSIZE     = $1f0000
FASTMEMSIZE     = $100000
INITAGA
 ENDC

NUMDRIVES       = 1
WPDRIVES        = %1000

;BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG;
DOSASSIGN
;DISKSONBOOT
;;FONTHEIGHT     = 8
HDINIT
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_MATHFFP
HRTMON
IOCACHE		= 17000
;MEMFREE        = $200
;NEEDFPU
;POINTERTICKS   = 1
;STACKSIZE      = 8000
;TRDCHANGEDISK
;SETPATCH
;============================================================================

slv_Version     = 16
slv_Flags       = WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit     = $59   ;F10

;============================================================================

 IFD _CD32
DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB
;USE_DISK_NONVOLATILE_LIB
QUIT_AFTER_PROGRAM_EXIT
;_PATCH_LOWLEV_LANGUAGE
_PATCH_NV_GETLIST
 ENDC
        IFD _CD32
        INCLUDE sources:whdload/jotd/kick31cd32.s
        ENDC
        IFD _AGA
        INCLUDE osemu:kick31.s
        ENDC
        IFD _ECS
        INCLUDE osemu:kick13.s
        ENDC

;============================================================================

        IFD BARFLY
        IFND    .passchk
        DOSCMD  "WDate  >T:date"
.passchk
        ENDC
        ENDC

slv_CurrentDir          dc.b    "data",0

 IFD _CD32
slv_name                dc.b    "UFO AGA/CD32 ",0
 ENDC
 IFD _ECS
slv_name                dc.b    "Diggers ECS ",0
 ENDC
slv_copy                dc.b    "Microprose",0
slv_info                dc.b    "Coded by CFou! using Wepl's KickEmul",10
                dc.b    "Version 1.0 "
        IFD BARFLY
                INCBIN  "T:date"
        ENDC
                dc.b    0
        EVEN

;============================================================================
; entry before any diskaccess is performed, no dos.library available

        IFD BOOTEARLY

_bootearly
                IFD _CD32
                bsr     _patch_cd32_libs
                IFD _PATCH_LOWLEV_LANGUAGE
                bsr _patch_lowlevel_lang
                ENDC
                ENDC

                blitz
                rts

        ENDC

;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

        IFD BOOTBLOCK

; A0 = buffer (1024 bytes)
; A1 = ioreq
; A6 = execbase

_bootblock      blitz
                jmp     (12,a4)

        ENDC



                                            

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

; the following example is extensive because it saves all registers and
;   restores them before executing the program, the reason for this that some
;   programs (e.g. MANX Aztec-C) require specific registers properly setup on
;   calling
; in most cases a simpler routine is sufficient :-)

        IFD BOOTDOS

_bootdos      

        clr.l   $0.W
        move.l  (_resload),a2           ;A2 = resload


        ;get tags
                lea     (_tag,pc),a0
                jsr     (resload_Control,a2)
        
      ;  ;enable cache
      ;          move.l  #WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
      ;          move.l  #WCPUF_All,d1
      ;          jsr     (resload_SetCPU,a2)



        ;open doslib

                lea     (_dosname,pc),a1
                move.l  (4),a6
                jsr     (_LVOOldOpenLibrary,a6)
                lea     (_dosbase,pc),a0
                move.l  d0,(a0)
                move.l  d0,a6                   ;A6 = dosbase

        ;assigns
                lea     (_disk0,pc),a0
                sub.l   a1,a1
                bsr     _dos_assign
                lea     (_disk1,pc),a0
                sub.l   a1,a1
                bsr     _dos_assign
                lea     (_disk2,pc),a0
                sub.l   a1,a1
                bsr     _dos_assign
                lea     (_disk3,pc),a0
                sub.l   a1,a1
                bsr     _dos_assign
                lea     (_disk4,pc),a0
                sub.l   a1,a1
                bsr     _dos_assign

                lea     (_disk6,pc),a0
                lea     (_disk6b,pc),a1
                bsr     _dos_assign




                IFD _CD32
                bsr     _patch_cd32_libs
                  IFD _PATCH_LOWLEV_LANGUAGE
                  bsr _patch_lowlevel_lang
                  ENDC

                  IFD _PATCH_NV_GETLIST
                  bsr _patch_nv_getlist
                  ENDC
                ENDC

                move.l _custom1(pc),d0
                tst.l d0
                bne .skip

                lea     _program0(pc),a0
                move.l  (_resload,pc),a2
                jsr     resload_GetFileSize(a2)
                tst.l  d0
                beq .skip

                lea     _program0(pc),a0        ; "intro"
                lea     _args0(pc),a1
                moveq   #_args_end0-_args0,d0
                lea _patch_game(pc),a5
 ;               lea 0,a5
                bsr     _load_exe

.skip
                lea     _program1(pc),a0        ; "geo "0" "0""
                lea     _args1(pc),a1
                moveq   #_args_end1-_args1,d0
                lea _patch_game(pc),a5
;                lea 0,a5
                bsr     _load_exe
                move.l out_d0(pc),d0
                tst.l d0
                beq .quit

.loop
                lea     _program2(pc),a0        ; "tactical "1" "0""
                lea     _args2(pc),a1
                moveq   #_args_end2-_args2,d0
;                lea _patch_game(pc),a5
                lea 0,a5
                bsr     _load_exe

                lea     _program1(pc),a0        ; "geo "1" "0""
                lea     _args2(pc),a1
                moveq   #_args_end2-_args2,d0
                lea _patch_game(pc),a5
;                lea 0,a5
                bsr     _load_exe
                move.l out_d0(pc),d0
                tst.l d0
                beq .quit

                bra .loop
.quit
        IFD QUIT_AFTER_PROGRAM_EXIT
                pea     TDREASON_OK
                move.l  (_resload,pc),a2
                jmp     (resload_Abort,a2)
        ELSE
                rts
        ENDC

                rts
_quit
       pea     TDREASON_OK
                move.l  (_resload,pc),a2
                jmp     (resload_Abort,a2)




_patch_game
  add.l d7,d7
  add.l d7,d7
   move.l d7,a1
   add.l #4,a1

 move.l a1,a3
 add.l #$5e,a3
 cmp.l #$4cdf7fff,(a3)
 bne .pas
 pea modif(pc)
 move.w #$4ef9,(a3)+
 move.l (a7)+,(a3)
.pas
;.t
; move.w #$f,$dff180
; btst #$6,$bfe001
; bne .t
 bsr patchAga

 rts
modif:
    movem.l (a7)+,d0-d7/a0-a6
    move.l (a7),a6

    movem.l a1/a3,-(a7)
    move.l a6,a1
    bsr patchAga
    movem.l (a7)+,a1/a3
    move.l 4,a6
    rts

patchAga
 ; manual protection aga
 move.l a1,a3
 add.l #$28ae-$68,a3
 cmp.l #$6d2e7239,(a3)
 bne .pas
 move.w #$4e71,(a3)
 move.w #$4e71,6(a3)
.pas

 move.l a1,a3
 add.l #$28ce-$68,a3
 cmp.l #$1410b082,(a3)
 bne .pas1
 move.l #$1f904814,(a3)+
 move.w #$6006,(a3)
.pas1

 move.l a1,a3
 add.l #$28f4-$68,a3
 cmp.l #$670e7008,(a3)
 bne .pas2
 move.w #$4e71,(a3)
.pas2

 move.l a1,a3
 add.l #$28fc-$68,a3
 cmp.l #$66064279,(a3)
 bne .pas3
 move.w #$4e71,(a3)
.pas3

 move.l a1,a3
 add.l #$290c-$68,a3
 cmp.w #$4a79,(a3)
 bne .pas4
 move.w #$4279,(a3)
.pas4

 move.l a1,a3
 add.l #$2912-$68,a3
 cmp.l #$67147001,(a3)
 bne .pas5
 move.b #$60,(a3)
.pas5
; fin manual protection

 rts


; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
        movem.l d0-a6,-(a7)
        move.l  d0,d2
        move.l  a0,a3
        move.l  a1,a4
        move.l  a0,d1
        jsr     (_LVOLoadSeg,a6)
        move.l  d0,d7                   ;D7 = segment
        beq     .end                    ;file not found

        ;patch here
        cmp.l   #0,A5
        beq.b   .skip
        movem.l d2/d7/a4,-(a7)
        jsr     (a5)
        movem.l (a7)+,d2/d7/a4
.skip
        ;call
        move.l  d7,a1
        add.l   a1,a1
        add.l   a1,a1

        move.l  a4,a0
        move.l  ($44,a7),d0             ;stacksize
        sub.l   #5*4,d0                 ;required for MANX stack check
        movem.l d0/d7/a2/a6,-(a7)
        move.l  d2,d0                   ; argument string length
;-----
        jsr     (4,a1)
;-----
        lea out_d0(pc),a2
        move.l d0,(a2)
        movem.l (a7)+,d1/d7/a2/a6



        ;remove exe
        move.l  d7,d1
        jsr     (_LVOUnLoadSeg,a6)

        movem.l (a7)+,d0-a6
        rts
                

.end
        move.l  a3,-(a7)
        pea     205                     ; file not found
        pea     TDREASON_DOSREAD
        move.l  (_resload,pc),-(a7)
        add.l   #resload_Abort,(a7)
        rts
out_d0
 dc.l 0

_pl_program     PL_START
                PL_END

 IFD _CD32
_disk0          dc.b    "UFO CD³²",0
_disk1          dc.b    "UFO disk 1",0
_disk2          dc.b    "UFO disk 2",0
_disk3          dc.b    "UFO disk 3",0
_disk4          dc.b    "UFO disk 4",0
_disk6          dc.b    "UFOTemp",0
;_disk6b          dc.b   "RAM",0
_disk6b          dc.b   "Temp",0
 ENDC
              even
_program0
      dc.b    "intro",0
_args0           dc.b  '',10
_args_end0       dc.b    0
_program1
      dc.b    "geo",0
_program2
      dc.b    "tactical",0
_args1           dc.b  '"0" "0"',10
_args_end1       dc.b    0
_args2           dc.b  '"1" "0"',10
_args_end2       dc.b    0
        EVEN

_saveregs       ds.l    11
_saverts        dc.l    0

        ENDC

;============================================================================
; callback/hook which gets executed after each successful call to dos.LoadSeg
; can also be used instead of _bootdos, requires the presence of
; "startup-sequence"

; the following example uses a parameter table to patch different executables
; after they get loaded

        IFD CBDOSLOADSEG

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg  lsl.l   #2,d0           ;-> APTR
                move.l  d0,a0
                moveq   #0,d0
                move.b  (a0)+,d0        ;D0 = name length
        ;remove leading path
                move.l  a0,a1
                move.l  d0,d2
.2              move.b  (a1)+,d3
                subq.l  #1,d2
                cmp.b   #":",d3
                beq     .1
                cmp.b   #"/",d3
                beq     .1
                tst.l   d2
                bne     .2
                bra     .3
.1              move.l  a1,a0           ;A0 = name
                move.l  d2,d0           ;D0 = name length
                bra     .2
.3      ;get hunk length sum
                move.l  d1,a1           ;D1 = segment
                moveq   #0,d2
.add            add.l   a1,a1
                add.l   a1,a1
                add.l   (-4,a1),d2      ;D2 = hunks length
                subq.l  #8,d2           ;hunk header
                move.l  (a1),a1
                move.l  a1,d7
                bne     .add
        ;search patch
                lea     (.patch,pc),a1
.next           move.l  (a1)+,d3
                movem.w (a1)+,d4-d5
                beq     .end
                cmp.l   d2,d3           ;length match?
                bne     .next
        ;compare name
                lea     (.patch,pc,d4.w),a2
                move.l  a0,a3
                move.l  d0,d6
.cmp            move.b  (a3)+,d7
                cmp.b   #"a",d7
                blo     .l
                cmp.b   #"z",d7
                bhi     .l
                sub.b   #$20,d7
.l              cmp.b   (a2)+,d7
                bne     .next
                subq.l  #1,d6
                bne     .cmp
                tst.b   (a2)
                bne     .next
        ;patch
                lea     (.patch,pc,d5.w),a0
                move.l  d1,a1
                move.l  (_resload,pc),a2
                jsr     (resload_PatchSeg,a2)
        ;end
.end
        IFD DEBUG
        ;set debug
                clr.l   -(a7)
                move.l  d1,-(a7)
                pea     WHDLTAG_DBGSEG_SET
                move.l  a7,a0
                move.l  (_resload,pc),a2
                jsr     (resload_Control,a2)
                add.w   #12,a7
        ENDC
                rts

PATCH   MACRO
                dc.l    \1              ;cumulated size of hunks (not filesize!)
                dc.w    \2-.patch       ;name
                dc.w    \3-.patch       ;patch list
        ENDM

.patch          PATCH   2516,.n_run,_p_run2568
                dc.l    0

        ;all upper case!
.n_run          dc.b    "RUN",0
        EVEN

_p_run2568      PL_START
        ;       PL_P    0,.1
                PL_END

        ENDC

;============================================================================
; callback/hook which gets executed after each successful call to
; dos.LoadRead

; the following example uses a parameter table to patch different files
; after they get loaded

        IFD CBDOSREAD

; D0 = ULONG bytes read
; D1 = ULONG offset in file
; A0 = CPTR name of file
; A1 = APTR memory buffer

_cb_dosRead
                move.l  a0,a2
.1              tst.b   (a2)+
                bne     .1
                lea     (.name,pc),a3
                move.l  a3,a4
.2              tst.b   (a4)+
                bne     .2
                sub.l   a4,a2
                add.l   a3,a2           ;first char to check
.4              move.b  (a2)+,d2
                cmp.b   #"A",d2
                blo     .3
                cmp.b   #"Z",d2
                bhi     .3
                add.b   #$20,d2
.3              cmp.b   (a3)+,d2
                bne     .no
                tst.b   d2
                bne     .4

        ;check position
                move.l  d0,d2
                add.l   d1,d2
                lea     (.data,pc),a2
                moveq   #0,d3
.next           movem.w (a2)+,d3-d4
                tst.w   d3
                beq     .no
                cmp.l   d1,d3
                blo     .next
                cmp.l   d2,d3
                bhs     .next
                sub.l   d1,d3
                move.b  d4,(a1,d3.l)
                bra     .next

.no             rts

.name           dc.b    "introduction",0    ;lower case!
        EVEN
        ;offset, new data
.data           dc.w    $4278,$c        ;original = 0b
                dc.w    $45b4,$c        ;original = 0b
                dc.w    0

        ENDC


;---------------------- patch language selection cd32

 IFD _PATCH_LOWLEV_LANGUAGE

_patch_lowlevel_lang
        ;open sldeteclib
                lea     (_lowlevelName,pc),a1
                move.l  (4),a6
                jsr     (_LVOOldOpenLibrary,a6)
                lea     (_lowlevelBase,pc),a0
                move.l  d0,(a0)
                tst.l d0
                beq .fin

fct=_LVOGetLanguageSelection  ;(-30) language selection

  ; patch open function dos.library
     lea optLs(pc),a0
     move.l (a0),d0
     cmp.l #1,d0
     beq .paslock
     move.l #1,(a0)
     lea optadr_old(pc),a0
     move.l _lowlevelBase(pc),a6
     move.l fct+2(a6),(a0)  ; old open file
     lea changefile(pc),a0
     move.l a0,fct+2(a6)    ; open file
.paslock


.fin
              move.l _dosbase(pc),a6

      rts


_lowlevelName
             dc.b 'lowlevel.library',0'
   even
_lowlevelBase
             dc.l 0

optLs:
    dc.l 0 ; patch dos librarie open file -$1e(a6)

optadr_old
    dc.l 0

changefile:
    movem.l a2,-(a7)
    lea changebin(pc),a2
    jsr (a2)
;    move.l optadr_old(pc),a2
;    jsr (a2)
    movem.l (a7)+,a2
    rts


_US=1
_GB=2
_GER=3
_FR=4
_POR=5
_IT=6
changebin:     
;.t
; move.w #$ff0,$dff180
; btst #6,$bfe001
; bne .t
  move.l _custom2(pc),d0
  cmp.l #_GER,d0
  beq .fin        ; -allemand
  cmp.l #_FR,d0
  beq .fin        ; -FR
  cmp.l #_US,d0
  beq .fin        ; -US
  cmp.l #_POR,d0
  beq .fin        ; -Portug
  cmp.l #_IT,d0
  beq .fin        ; -Italien
  move.l #_GB,d0  ; sinon anglais
.fin
  rts
               
 ENDC



 IFD _PATCH_NV_GETLIST

_patch_nv_getlist
        ;open sldeteclib
                lea     (_nvName,pc),a1
                move.l  (4),a6
                jsr     (_LVOOldOpenLibrary,a6)
                lea     (_nvBase,pc),a0
                move.l  d0,(a0)
                tst.l d0
                beq .fin

fctNV=_LVOGetNVList  ;(-60) get list
fctNV2=_LVOSetNVProtection  ;(-66) protection
  ; patch open function dos.library
     lea optNV(pc),a0
     move.l (a0),d0
     cmp.l #1,d0
     beq .paslock
     move.l #1,(a0)

   lea optadr_oldNV(pc),a0
     move.l _nvBase(pc),a6
     move.w #$4ef9,fctNV+0(a6)  ; replace jsr by jmp
     move.l fctNV+2(a6),(a0)  ; old open file
     lea changefileNV(pc),a0
     move.l a0,fctNV+2(a6)    ; open file

    lea optadr_oldNV2(pc),a0
     move.l _nvBase(pc),a6
     move.l fctNV2+2(a6),(a0)  ; old open file
     lea changefileNV2(pc),a0
    move.l a0,fctNV2+2(a6)    ; open file
.paslock


.fin
              move.l _dosbase(pc),a6

      rts


_nvName
             dc.b 'nonvolatile.library',0
   even
_nvBase
             dc.l 0

optNV:
    dc.l 0 ; patch dos librarie open file -$1e(a6)

optadr_oldNV
    dc.l 0

optadr_oldNV2
    dc.l 0

changefileNV:
    movem.l a2,-(a7)
    lea changebinNV(pc),a2
    jsr (a2)
;    move.l optadr_oldNV(pc),a2
;    jsr (a2)
    movem.l (a7)+,a2
    rts

changefileNV2:
    movem.l a2,-(a7)
    lea changebinNV2(pc),a2
    jsr (a2)
;    move.l optadr_oldNV2(pc),a2
;    jsr (a2)
    movem.l (a7)+,a2
    rts

changebinNV:
;.t
; move.w #$ff0,$dff180
; btst #6,$bfe001
; bne .t
;  clr.l d0

    lea listfile(pc),a2
    move.l a0,4(a2)
    move.l a1,8(a2)
;_GetNVInfo:
;       moveq   #0,D0   ; not available

        moveq.l #8*2+12*2,d0
        moveq.l #0,d1
        bsr.w   ForeignAllocMem
        tst.l   d0
        beq.s   .rts
        move.l  d0,a0
        clr.l   (a0)+           ;simple structure
        move.l  d0,(A0)+        ;pointer
        move.l d0,d1
        move.l  #8+12,(A0)+     ;size to free
        move.l  #999900,(A0)    ;total storage on nv-device
        move.l  #989800,4(A0)   ;free storage on nv-device

        move.l  a0,d0
        lea listfile(pc),a2
        move.l a2,(a0)+
;        clr.l   (a0)+           ;simple structure
        move.l  d0,(A0)+        ;pointer
        move.l  #1,(A0)+     ;size to free
        move.l  #999900,(A0)    ;total storage on nv-device
        move.l  #989800,4(A0)   ;free storage on nv-device
        move.l  d0,a0

.rts    rts
lgsave=840
listfile:
 dc.l lgsave/10,0,0,lgsave/10,0


changebinNV2:
;.t
; move.w #$f00,$dff180
; btst #6,$bfe001
; bne .t
  clr.l d0
  rts
 ENDC

_tag            dc.l    WHDLTAG_CUSTOM1_GET
_custom1        dc.l    0
                dc.l    WHDLTAG_CUSTOM2_GET
_custom2        dc.l    0
                dc.l    0
                               

;============================================================================
