
WHDLF_NoError	equ	$2
resload_LoadFileDecrunch	equ	$1C
resload_Abort	equ	$4
resload_SetCACR	equ	$10
TDREASON_OK	equ	$FFFFFFFF
_LVOLoadSeg	equ	-$96
CACRF_EnableI	equ	$1
_LVOOpenLibrary	equ	-$228
****************************************************************************
	exeobj
	errfile	'ram:assem.output'
	objfile	'BamigaSectorOne-GPC.slave'
;_[]
	SECTION	BamigaSectorOneGPCslave000000,CODE
ProgStart
ws	moveq	#-1,d0	;ws_Security
	rts

	db	'WHDLOADS'	;ws_ID
	dw	14	;ws_Version
	dw	WHDLF_NoError	;ws_Flags
	dl	$80000	;ws_BaseMemSize
	dl	0	;ws_ExecInstall
	dw	slv_GameLoader-ws	;ws_GameLoader
	dw	0	;ws_CurrentDir
	dw	0	;ws_DontCache
	db	$5F	;ws_keydebug
	db	$5D	;ws_keyexit
	dl	0	;ws_ExpMem
	dw	slv_name-ws	;ws_name
	dw	slv_copy-ws	;ws_copy
	dw	slv_info-ws	;ws_info
slv_name	db	'Grand Prix Circuit Crack-Intro',0
slv_copy	db	'198x Bamiga Sector One & Cybertech',0
slv_info	db	'-----------------------------',$A
	db	'Installed by',$A
	db	'Max Headroom',$A
	db	'of',$A
	db	'The Exterminators',$A
	db	'-----------------------------',$A
	db	'Version 1.0 ',0

slv_GameLoader	lea	(_resload,pc),a1
	move.l	a0,(a1)
	movea.l	a0,a2
	move.l	#CACRF_EnableI,d0
	move.l	d0,d1
	jsr	(resload_SetCACR,a0)
	lea	($10000).l,a0
	move.l	#$6FFFFF,d0
lbC000104	clr.l	(a0)+
	dbra	d0,lbC000104
	lea	(OSEmu400.MSG,pc),a0
	lea	($400).w,a1
	jsr	(resload_LoadFileDecrunch,a2)
	movea.l	a2,a0
	lea	(ws,pc),a1
	jsr	($400).w
	move.w	#0,sr
	moveq	#0,d0
	lea	(doslibrary.MSG,pc),a1
	movea.l	(4).w,a6
	jsr	(_LVOOpenLibrary,a6)
	lea	(_execbase,pc),a4
	move.l	d0,(a4)
	movea.l	d0,a6
	lea	(bs1crackgrand.MSG,pc),a0
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	lsl.l	#2,d0
	movea.l	d0,a1
	addq.l	#4,a1
	suba.l	a0,a0
	moveq	#0,d0
	lea	(_start,pc),a2
	move.l	a1,(a2)
	jsr	(_patch_dec,pc)
	movea.l	(_start,pc),a1
	lea	(doslibrary.MSG0,pc),a0
	moveq	#1,d0
	jsr	(a1)
	jmp	(_quit,pc)

_patch_dec	movea.l	(_start,pc),a1
	move.w	#$4EF9,($AA,a1)
	pea	(_patch,pc)
	move.l	(sp)+,($AC,a1)
	rts

_patch	move.w	#$4EB9,($336E8).l
	pea	(_wait4lines,pc)
	move.l	(sp)+,($336EA).l
	move.w	#$4E71,($336EE).l
	move.w	#$4E71,($3279E).l
	move.w	#$4E71,($327A0).l
	move.w	#$4E71,($327A2).l
	move.w	#$4E71,($327A4).l
	move.w	#$4E71,($327A6).l
	move.w	#$4E71,($327AE).l
	move.w	#$4E71,($327B0).l
	jmp	($30000).l

_quit	pea	(TDREASON_OK).l
	movea.l	(_resload,pc),a0
	jmp	(resload_Abort,a0)

_wait4lines	movem.l	d0-d7/a0-a6,-(sp)
	move.w	#3,d1
.loop	move.b	($DFF006).l,d0
.wait	cmp.b	($DFF006).l,d0
	beq.b	.wait
	dbra	d1,.loop
	movem.l	(sp)+,d0-d7/a0-a6
	rts

OSEmu400.MSG	db	'OSEmu.400',0
bs1crackgrand.MSG	db	'bs1-crackgrandprixcircuit',0
_resload	dl	0
_execbase	dl	0
_start	dl	0
doslibrary.MSG0	db	10
doslibrary.MSG	db	'dos.library',0,0

	end
