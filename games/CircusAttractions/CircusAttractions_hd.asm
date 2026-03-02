;*--------------------------------------------------------------------------- 
;  :Program.    SWIV.asm 
;  :Contents.   Slave for "Tennis cup 2" from Loriciel
;  :Author.     CFou!
;  :History.    30.03.04
;  :Requires.   - 
;  :Copyright.  Public Domain 
;  :Language.   68000 Assembler 
;  :Translator. Barfly
;  :To Do. 
;---------------------------------------------------------------------------* 
        OUTPUT  dh2:CircusAttractions/CircusAttractions.slave
;        OPT     O+ OG+                  ;enable optimizing

   INCDIR   Include:
   INCLUDE  whdload.i
   INCLUDE  whdmacros.i

CHIPMEMSIZE = $88000
FASTMEMSIZE = $0

BASEMEM=CHIPMEMSIZE
EXPMEM=FASTMEMSIZE

_base
    SLAVE_HEADER           ;ws_Security + ws_ID
      dc.w  13             ;ws_Version
      dc.w  WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_NoKbd  ;ws_flags
      dc.l  BASEMEM        ;ws_BaseMemSize
      dc.l  0              ;ws_ExecInstall
      dc.w  _start-_base      ;ws_GameLoader
      dc.w  _data-_base    ;ws_CurrentDir
      dc.w  0              ;ws_DontCache
_keydebug
      dc.b  $5f            ;ws_keydebug
_keyexit
      dc.b  $5d            ;ws_keyexit = *
_expmem
      dc.l  EXPMEM         ;ws_ExpMem
      dc.w  _name-_base    ;ws_name
      dc.w  _copy-_base    ;ws_copy
      dc.w  _info-_base    ;ws_info

;============================================================================

   IFD BARFLY
   DOSCMD   "WDate  >T:date"
   ENDC

_data    dc.b  0
_name    dc.b  "Circus Attractions",0
_copy    dc.b  "1989-91 Golden Goblins/Top Shots ",0
_info    dc.b  "Install done by CFou!",10
      dc.b  "Version 1.0 "
   IFD BARFLY
      INCBIN   "T:date"
   ENDC
      dc.b  0
;====================================================================== 
 even
 
;====================================================================== 
_start   ;       A0 = resident loader
;====================================================================== 
        lea _resload(pc),a1
        move.l  a0,(a1)                 ;save for later use

loadadr=$30000


        MOVE.L  #$400,D0
        MOVE.L  #$800,D1
        MOVEQ   #1,D2
        LEA     loadadr,A0
        BSR     _LoadDisk

        move.w #$4e75,$112(a0)
        move.w #$4e75,$ac(a0)
        move.w #$4e75,$17a(a0)


        MOVE.W  #$4EF9,$54(a0)
        PEA     _LoadTrackGame(PC)
        MOVE.L  (SP)+,$54+2(a0)


      ;  MOVE.W  #$4EF9,$48(a0)
        PEA     _modif(PC)
        MOVE.L  (SP)+,$48+2(a0)


        JMP     (A0)

_modif
        cmp.l #$48e7f0c0,$6f4da ; 2disks version
        bne .pas
        MOVE.W  #$4EF9,$6f4da
        PEA     _LoadTrackGame(PC)
        MOVE.L  (SP)+,$6f4da+2

        MOVE.W  #$4EB9,$6f1aa
        PEA     _debugAdr(PC)
        MOVE.L  (SP)+,$6f1aa+2

        MOVE.W  #$4EB9,$6e0fc
        PEA     _Modif1_2D(PC)
        MOVE.L  (SP)+,$6e0fc+2

        MOVE.W  #$4Ef9,$6f61a
        PEA     _DiskChange(PC)
        MOVE.L  (SP)+,$6f61a+2

        ; disk access
        move.w #$4e75,$6f7e0
        move.w #$6016,$6f9c4
        move.w #$4e75,$6f868
        move.w #$4e75,$6f874
        move.w #$4e75,$6f898
        move.w #$4e75,$6f824
 ;       move.w #$4e75,$6f810

        MOVE.W  #$4Ef9,$6e7e6
        PEA     _load_2D(PC)
        MOVE.L  (SP)+,$6e7e6+2

        MOVE.W  #$4EB9,$6e7b2
        PEA     _save_2D(PC)
        MOVE.L  (SP)+,$6e7b2+2

.pas
        cmp.l #$48e7f0c0,$6f64e ; 1 disk version
        bne .pas1
        MOVE.W  #$4EF9,$6f64e
        PEA     _LoadTrackGame(PC)
        MOVE.L  (SP)+,$6f64e+2

        MOVE.W  #$4EB9,$6f008
        PEA     _debugAdr(PC)
        MOVE.L  (SP)+,$6f008+2

        MOVE.W  #$4EB9,$6e0fa
        PEA     _Modif1_1D(PC)
        MOVE.L  (SP)+,$6e0fa+2
        move.l #$4e714e71,$6e0fa+6
        ; access disk
        move.w #$4e75,$6f7d6
        move.w #$6016,$6f8d6
        move.w #$4e75,$6f83a
        move.w #$4e75,$6f82e

        MOVE.W  #$4Ef9,$6e78c
        PEA     _load_1D(PC)
        MOVE.L  (SP)+,$6e78c+2

        MOVE.W  #$4EB9,$6e768
        PEA     _save_1D(PC)
        MOVE.L  (SP)+,$6e768+2

       MOVE.W  #$4Ef9,$6ee52
        PEA     _Modif3_1D(PC)
        MOVE.L  (SP)+,$6ee52+2

.pas1
        jmp $6e000

_Modif1_2D
        MOVE.W  #$4Ef9,$1d18
        PEA     _touchenew(PC)
        MOVE.L  (SP)+,$1d18+2

;  move.w #$601c,$124a ; access fault pile
   move.w #$600c,$1c7a ; clear interupt adr

        MOVE.W  #$4EB9,$6e1a0
        PEA     _Modif2_2D(PC)
        MOVE.L  (SP)+,$6e1a0+2

  jsr $1000
  rts

_Modif2_1D
_Modif2_2D
;------------- self modifying code
        MOVE.W  #$4Ef9,$100
        PEA     _d1_a1(PC)
        MOVE.L  (SP)+,$100+2

        MOVE.W  #$4Ef9,$106
        PEA     _d0_a1(PC)
        MOVE.L  (SP)+,$106+2

        MOVE.W  #$4Ef9,$10c
        PEA     _d1_a0(PC)
        MOVE.L  (SP)+,$10c+2

        move.l #$4eb80100,$303e6
        move.l #$4eb80106,$30204
        move.l #$4eb8010c,$30594
        lea $20000,a0
        rts

_d1_a1
  move.l d1,2(a1)  ; self modifing code jmp $0
  rts

_d0_a1
  move.l d0,2(a1)  ; self modifing code jmp $0
  rts

_d1_a0
  move.l d1,2(a0)  ; self modifing code jmp $0
  rts

_Modif1_1D
         MOVE.W  #$4Ef9,$1d18
        PEA     _touchenew(PC)
        MOVE.L  (SP)+,$1d18+2

        MOVE.W  #$4EB9,$6e1b6
        PEA     _Modif2_1D(PC)
        MOVE.L  (SP)+,$6e1b6+2


  jsr $1000
  lea $dff000,a6
  rts

_debugAdr
  add.w #$180,d1
  move.w d3,(a6,d1.w)
  sub.w #$180,d1
  add.l #2,d1
  rts
_LoadTrackGame
        MOVEM.L D0-D7,-(SP)
        mulu #$1600,d0   ; track
        and.l #$ffff,d2
        lsl.l #1,d2      ; decal track
        add.l d2,d0

        LSL.l #1,d1  ; lg

        move.l _NumDisk(pc),d2
                 move.l  _resload(pc),a2
                jsr     resload_DiskLoad(a2)
          bsr _PatchAccessFault2
        MOVEM.l (a7)+,d0-d7
        clr.l d0
        rts

_Modif3_1D
  bsr _PatchAccessFault2
  jmp $4000

_PatchAccessFault2
  cmp.l #$226d0238,$663a
  bne .pas
  lea _accessfault2(pc),a0
  move.w #$4eb9,$663a
  move.l a0,$663a+2
.pas
 rts
_accessfault2
  move.l $238(a5),a1
  move.l d0,-(a7)
  move.l a1,d0
  and.l #$7ffff,d0
  move.l d0,a1
  move.l (a7)+,d0
  move.l (a0),(a1)
  rts
    
_NumDisk
       dc.l    1
 
;-------------------------------- 
 
_resload        dc.l    0               ;address of resident loader 
 
;-------------------------------- 
; IN:   d0=offset d1=size d2=disk a0=dest 
; OUT:  d0=success 
 
_LoadDisk       movem.l d0-d1/a0-a2,-(a7) 
                move.l  _resload(pc),a2 
                jsr     resload_DiskLoad(a2) 
                movem.l (a7)+,d0-d1/a0-a2 
                rts 
 
;-------------------------------- 
 
_exit           pea     TDREASON_OK.w 
                bra.b   _end 
_debug          pea     TDREASON_DEBUG.w 
_end            move.l  _resload(pc),-(a7) 
                addq.l  #resload_Abort,(a7) 
                rts

_Touche_1D_2D
        tst.w $109c
        beq .ok
        clr.w $2b6c
        rts
.ok
        MOVEM.L D0/D1,-(SP)
        MOVE.W  $238e,D1
        MOVEQ   #0,D0
        move.l touchebin(pc),d0
      ;  MOVE.B  ($BFEC01).L,D0
        and.l #$ff,d0
        NOT.B   D0
        LSR.B   #1,D0
        BCS.W   .lab00B2
        CMPI.W  #$40,D0
        BNE.B   .lab0022
        BSET    #4,D1
.lab0022
        CMPI.W  #$4C,D0
        BNE.B   .lab002C
        BSET    #8,D1
.lab002C
        CMPI.W  #$4D,D0
        BNE.B   .lab0036
        BSET    #0,D1
.lab0036
        CMPI.W  #$4E,D0
        BNE.B   .lab0040
        BSET    #1,D1
.lab0040
        CMPI.W  #$4F,D0
        BNE.B   .lab004A
        BSET    #9,D1
.lab004A
        CMP.W   $238e,D1
        BNE.W   .lab00EA
        TST.W   ($1086).L
        BNE.W   .lab00A8
        CMPI.B  #$21,D0
        BNE.B   .lab0094
        TST.W   ($108A).L
        BNE.B   .lab008A
        ST      ($108A).L
.lab0070
        MOVEA.L #$DFF000,A6
        CLR.W   ($A8,A6)
        CLR.W   ($B8,A6)
        CLR.W   ($C8,A6)
        CLR.W   ($D8,A6)
        BRA.W   .lab00B0

.lab008A
        SF      ($108A).L
        BRA.W   .lab00B0

.lab0094
        CMPI.B  #$19,D0
        BNE.B   .lab00A8
        TST.W   ($1088).W
        BNE.B   .lab00A8
        ST      ($1088).W
        BRA.W   .lab0070

.lab00A8
        jsr $1e7c
        MOVE.W  D0,($2B6C).W
.lab00B0
        BRA.B   .lab00EE

.lab00B2
        CMPI.W  #$40,D0
        BNE.B   .lab00BC
        BCLR    #4,D1
.lab00BC
        CMPI.W  #$4C,D0
        BNE.B   .lab00C6
        BCLR    #8,D1
.lab00C6
        CMPI.W  #$4D,D0
        BNE.B   .lab00D0
        BCLR    #0,D1
.lab00D0
        CMPI.W  #$4E,D0
        BNE.B   .lab00DA
        BCLR    #1,D1
.lab00DA
        CMPI.W  #$4F,D0
        BNE.B   .lab00E4
        BCLR    #9,D1
.lab00E4
        CMP.W   $238e,D1
        BEQ.B   .lab00EE
.lab00EA
        MOVE.W  D1,($238E).W
.lab00EE
        MOVEM.L (SP)+,D0/D1
        RTS

_touchenew:
        MOVEM.L D0/D1/A1,-(SP)
        LEA     $BFE001,A1
        BTST    #3,$D00(A1)
        BEQ   .fintouche
        MOVE.B  $C00(A1),D0
        CLR.B   $C00(A1)
        OR.B    #$40,$E00(A1)
        lea touchebin(pc),a1
        move.l d0,(a1)
        NOT.B   D0
        ROR.B   #1,D0
        move.l d0,4(a1)
        bsr _Touche_1D_2D

        cmp.b #$58,d0
        bne .pas_f9
        move.w #$f0,$dff180
         move.w #$f0,$dff180
         move.w #$f0,$dff180
         move.w #$0,$dff180
.pas_f9:


        MOVEQ   #2,D1
.w2:
        MOVE.B  $DFF006,D0
.w1:
        CMP.B   $DFF006,D0
        BEQ.S   .w1
        DBRA    D1,.w2
        LEA     $BFE001,A1
        AND.B   #$BF,$E00(A1)
.fintouche
        MOVE.W  #8,$DFF09C
        MOVEM.L (SP)+,D0/D1/A1
        RTE
                          
touchebin:
    dc.l 0,0

_DiskChange
 ext.l d0
 add.l #1,d0
 move.l a0,-(a7)
 lea _NumDisk(pc),a0
 move.l d0,(a0)
 move.l (a7)+,a0
 clr.l d0
 rts

_GetFileSize
      movem.l d1-a6,-(a7)
        lea save_game_name(pc),a0
        move.l (_resload,pc),a2
        jsr (resload_GetFileSize,a2)
      movem.l (a7)+,d1-a6
      rts

_load_2D
      movem.l d0-a6,-(a7)
      bsr _GetFileSize
      beq .load
      move.l a1,a0
       lea $6ff58,a0
        lea save_game_name(pc),a1
        exg.l  a0,a1
        clr.l d0
        move.l #152,d1 ; lg
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_LoadFileOffset,a2)
        st $6ef9e
        movem.l (a7)+,d0-a6
      rts

.load
        move.l #1,d0
        lea $6fd76,a0
        jsr $6f47c ; load high score
        st $6ef9e
        movem.l (a7)+,d0-a6
      rts


_load_1D
      movem.l d0-a6,-(a7)
      bsr _GetFileSize
      beq .load
      move.l a1,a0
       lea $6fda6,a0
        lea save_game_name(pc),a1
        exg.l  a0,a1
        clr.l d0
        move.l #152,d1 ; lg
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_LoadFileOffset,a2)
        st $6ee06
        movem.l (a7)+,d0-a6
      rts

.load
        move.l #1,d0
        lea $6fbe0,a0
        jsr $6f0f6 ; load high score
        st $6ee06
        movem.l (a7)+,d0-a6
      rts

_save_1D
        jsr $6e9d0
        movem.l d0-a6,-(a7)
        move.l a1,a0
        lea $6fda6,a0
        lea save_game_name(pc),a1
        exg.l  a0,a1
        clr.l d0
        move.l #152,d1 ; lg
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_SaveFileOffset,a2)
        movem.l (a7)+,d0-a6
        move.l #1,d0
        rts

_save_2D
        jsr $6ea3c
        movem.l d0-a6,-(a7)
        move.l a1,a0
        lea $6ff58,a0
        lea save_game_name(pc),a1
        exg.l  a0,a1
        clr.l d0
        move.l #152,d1 ; lg
        exg.l d0,d1
        move.l (_resload,pc),a2
        jsr (resload_SaveFileOffset,a2)
        movem.l (a7)+,d0-a6
        move.l #1,d0
        rts


save_game_name
   dc.b 'highs',0
   even
                       
 
;====================================================================== 
 end

      
