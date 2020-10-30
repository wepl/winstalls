;*---------------------------------------------------------------------------
;  :Modul.	lowlevel.s
;  :Contents.	lowlevel.library
;		will be constructed directly in memory
;  :Author.	Wepl
;  :Version.	$Id: lowlevel.s 1.1 2020/10/30 15:06:58 wepl Exp wepl $
;  :History.	2020-10-29 initial
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	exec/initializers.i
	INCLUDE	libraries/lowlevel.i
	INCLUDE	lvo/cia.i
	INCLUDE	lvo/input.i
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/lowlevel.i
	INCLUDE	lvo/potgo.i
	INCLUDE	lvo/timer.i
	INCLUDE	lvo/utility.i

;============================================================================
; this creates the library, must be called once at startup

_lowlevel_init
		movem.l	d0-d1/a0-a2/a6,-(a7)
		lea	(.name,pc),a0
		lea	(.struct_name+2,pc),a1
		move.l	a0,(a1)
		move.l	#$1fc,d0		;data size
		moveq	#0,d1			;segment list
		lea	(.vectors,pc),a0
		lea	(.structure,pc),a1
		lea	(_lowlevel_rtinit,pc),a2
		move.l	(4),a6
		jsr	(_LVOMakeLibrary,a6)
	IFD JOYPADEMU
		bsr	_joypademu
	ENDC
		move.l	d0,a1
		jsr	(_LVOAddLibrary,a6)
		movem.l	(a7)+,d0-d1/a0-a2/a6
		rts

.structure	INITBYTE LN_TYPE,NT_LIBRARY
.struct_name	INITLONG LN_NAME,0
		INITBYTE LIB_FLAGS,LIBF_CHANGED|LIBF_SUMUSED
		INITWORD LIB_VERSION,40
		INITBYTE LIB_SIZE,100		;taskpri
		dc.w	0

.vectors	dc.w	-1
		dc.w	_ll_Open-.vectors
		dc.w	_ll_Close-.vectors
		dc.w	_ll_Expunge_ExtFunc-.vectors
		dc.w	_ll_Expunge_ExtFunc-.vectors
		dc.w	ReadJoyPort-.vectors
		dc.w	GetLanguageSelection-.vectors
		dc.w	SetLanguageSelection-.vectors
		dc.w	GetKey-.vectors
		dc.w	QueryKeys-.vectors
		dc.w	AddKBInt-.vectors
		dc.w	RemKBInt-.vectors
		dc.w	SystemControlA-.vectors
		dc.w	AddTimerInt-.vectors
		dc.w	RemTimerInt-.vectors
		dc.w	StopTimerInt-.vectors
		dc.w	StartTimerInt-.vectors
		dc.w	ElapsedTime-.vectors
		dc.w	AddVBlankInt-.vectors
		dc.w	RemVBLankInt-.vectors
		dc.w	KillReq-.vectors
		dc.w	RestoreReq-.vectors
		dc.w	SetJoyPortAttrsA-.vectors
		dc.w	-1

.name		dc.b	"lowlevel.library",0
utilitylibrar.MSG	db	'utility.library',0
nonvolatileli.MSG	db	'nonvolatile.library',0
intuitionlibr.MSG	db	'intuition.library',0
graphicslibra.MSG	db	'graphics.library',0
timerdevice.MSG		db	'timer.device',0
keyboarddevic.MSG	db	'keyboard.device',0
potgoresource.MSG	db	'potgo.resource',0
gameportdevic.MSG	db	'gameport.device',0
inputdevice.MSG		db	'input.device',0
InputMapper.MSG		db	'Input Mapper',0
	EVEN

_ll_Open	addq	#1,(LIB_OPENCNT,a6)
		move.l	a6,d0
		rts
_ll_Close	subq	#1,(LIB_OPENCNT,a6)
_ll_Expunge_ExtFunc
		moveq	#0,d0
		rts

;-----------------------
; original init code
; may contain obsolete stuff

_lowlevel_rtinit
	movem.l	d7/a5/a6,-(sp)
	movea.l	d0,a5
	move.l	a6,($34,a5)	;34 execbase
	move.l	a0,($30,a5)	;seglist
	lea	(potgoresource.MSG,pc),a1
	jsr	(_LVOOpenResource,a6)
	move.l	d0,($58,a5)	;58 poto ressource
	move.b	#8,($6D,a5)
	move.b	#8,($AD,a5)
	moveq	#0,d0
	move.l	d0,($9C,a5)
	move.l	d0,($DC,a5)
	move.l	d0,($170,a5)
	move.l	d0,($1B0,a5)
	lea	($6E,a5),a0
	jsr	(_LVOInitSemaphore,a6)
	lea	($AE,a5),a0
	jsr	(_LVOInitSemaphore,a6)
	lea	($1B4,a5),a0
	jsr	(_LVOInitSemaphore,a6)
	move.b	#2,($110,a5)
	move.l	(10,a5),($112,a5)
	lea	(lbC000F16,pc),a1
	move.l	a1,($11A,a5)
	move.l	a5,($116,a5)
	moveq	#-1,d0
	move.b	d0,($23,a5)
	move.b	d0,($24,a5)
	move.b	d0,($25,a5)
	move.b	d0,($6C,a5)
	move.b	d0,($AC,a5)
	move.w	d0,($2A,a5)
	move.b	#2,($126,a5)
	move.l	(10,a5),($128,a5)
	move.l	a5,($12C,a5)
	lea	(_keyread,pc),a1
	move.l	a1,($130,a5)
	lea	($FC,a5),a1
	move.l	a1,(8,a1)
	addq.l	#4,a1
	clr.l	(a1)
	move.l	a1,-(a1)
	movea.l	(10,a5),a1
	jsr	(_LVOFindPort,a6)
	move.l	d0,($54,a5)
	bne.w	.portok
	move.l	#$43,d0
	move.l	#MEMF_CLEAR,d1
	jsr	(_LVOAllocMem,a6)
	move.l	d0,($54,a5)
	beq.w	.nov37
	movea.l	d0,a1
	move.l	#2,(14,a1)
	move.b	#$FF,(9,a1)
	lea	($14,a1),a0
	move.l	a0,(8,a0)
	addq.l	#4,a0
	clr.l	(a0)
	move.l	a0,-(a0)
	move.l	a1,-(sp)
	lea	($32,a1),a0
	move.l	a0,(10,a1)
	movea.l	(10,a5),a1
.copy	move.b	(a1)+,(a0)+
	bne.b	.copy
	movea.l	(sp)+,a1
	jsr	(_LVOAddPort,a6)
	lea	(intuitionlibr.MSG,pc),a1
	moveq	#37,d0
	jsr	(_LVOOpenLibrary,a6)
	tst.l	d0
	beq.w	.nov37
	movea.l	($54,a5),a1
	lea	($30,a1),a0
	move.l	a0,($26,a1)
	move.l	#$2F3AFFFA,($2A,a1)	;move.l (*-4),-(a7)
	move.w	#$7000,($2E,a1)	;moveq #0,d0
	move.w	#$4E75,($30,a1)	;rts
	lea	($2A,a1),a1
	movea.l	#_LVOEasyRequestArgs,a0
	exg	d0,a1
	movem.l	d0/a0/a1,-(sp)
	jsr	(_LVOCacheClearU,a6)
	movem.l	(sp)+,d0/a0/a1
	jsr	(_LVOSetFunction,a6)
	movea.l	($54,a5),a1
	move.l	d0,($22,a1)
	move.l	d0,($26,a1)
	jsr	(_LVOCacheClearU,a6)
.portok	lea	(utilitylibrar.MSG,pc),a1
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,($38,a5)	;38 utilbase
	beq.w	.nov37
	lea	(graphicslibra.MSG,pc),a1
	moveq	#40,d0
	jsr	(_LVOOpenLibrary,a6)
	tst.l	d0
	bne.b	.gfx40
	lea	($1E2,a5),a1
	move.b	#2,(8,a1)
	move.l	(10,a5),(10,a1)
	lea	(_ll_inc_a1,pc),a0
	move.l	a0,($12,a1)
	lea	($1F8,a5),a0
	move.l	a0,(14,a1)
	moveq	#5,d0
	jsr	(_LVOAddIntServer,a6)
	lea	($1F8,a5),a1
	bra.b	.1

.gfx40	movea.l	d0,a0
	lea	($1F4,a0),a1
.1	move.l	a1,($5C,a5)
	move.w	#$FFFF,($26,a5)
	lea	(-$28,sp),sp
	lea	(timerdevice.MSG,pc),a0
	movea.l	sp,a1
	moveq	#0,d0
	moveq	#0,d1
	jsr	(_LVOOpenDevice,a6)
	tst.b	d0
	bne.b	.notimer
	movea.l	($14,sp),a6
	move.l	a6,($40,a5)
	movea.l	sp,a0
	jsr	(_LVOReadEClock,a6)
	move.l	d0,($2C,a5)
	movea.l	($34,a5),a6
	lea	(keyboarddevic.MSG,pc),a0
	movea.l	sp,a1
	moveq	#0,d0
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	tst.b	d0
	bne.b	.nokeyboard
	move.l	($14,sp),($44,a5)
	lea	(ciaaresource.MSG,pc),a1
	jsr	(_LVOOpenResource,a6)
	movea.l	d0,a6
	move.w	#3,d0
	jsr	(_LVOAddICRVector,a6)
	move.l	d0,($48,a5)
	movea.l	d0,a1
	move.w	#3,d0
	jsr	(_LVORemICRVector,a6)
	lea	($11E,a5),a1
	move.w	#3,d0
	jsr	(_LVOAddICRVector,a6)
	move.l	a5,d0
	lea	($28,sp),sp
	bra.b	.end

.nokeyboard	move.l	($40,a5),($14,sp)
	movea.l	sp,a1
	jsr	(_LVOCloseDevice,a6)
.notimer	lea	($28,sp),sp
	movea.l	($38,a5),a1
	jsr	(_LVOCloseLibrary,a6)
.nov37	moveq	#0,d0

		illegal			; stop on failure

.end	movem.l	(sp)+,d7/a5/a6
	rts

;============================================================================

	IFD JOYPADEMU

_joypademu	movem.l	d0/d2-d3/d6/a2/a6,-(a7)
		move.l	d0,d6			;D6 = lowlevelbase

	;check for user defined keys
JPARGBUFLEN = 100
		sub.l	#JPARGBUFLEN,a7
		moveq	#(RDA_SIZEOF+(7*4))/4-1,d0
.clr		clr.l	-(a7)
		dbf	d0,.clr
		move.l	#JPARGBUFLEN,d0		;buffer length
		moveq	#0,d1			;reserved
		lea	(RDA_SIZEOF+(7*4),a7),a0
		move.l	a0,(RDA_Source+CS_Buffer,a7)
		move.l	(_resload,pc),a1
		jsr	(resload_GetCustom,a1)
		tst.l	d0
		beq	.badcustom
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6
		lea	(.rjp_template,pc),a0
		move.l	a0,d1			;template
		lea	(RDA_SIZEOF,a7),a0
		move.l	a0,d2			;array
		move.l	a7,d3			;rdargs
		move.l	(RDA_Source+CS_Buffer,a7),a0
		moveq	#0,d0
.cnt		addq.l	#1,d0
		tst.b	(a0)+
		bne	.cnt
		move.b	#10,-(a0)
		move.l	d0,(RDA_Source+CS_Length,a7)
		move.l	#RDAF_NOPROMPT,(RDA_Flags,a7)
		jsr	(_LVOReadArgs,a6)
		tst.l	d0
		beq	.badargs
		lea	(RDA_SIZEOF,a7),a2
		lea	(_rjp_keys,pc),a1
		moveq	#6-1,d3
.loop		move.l	(a2)+,d0
		beq	.skip
		move.l	d0,a0
		bsr	_atoi
		tst.b	(a0)
		bne	.badnum
		cmp.w	#$70,d0
		bhs	.badnum
		move.w	d0,(a1)
.skip		addq.l	#4,a1
		dbf	d3,.loop
		move.l	a7,d1
		jsr	(_LVOFreeArgs,a6)
	;force lowlevel.library to joystick mode for port0/1
		tst.l	(a2)
		beq	.noforce
		move.l	d6,a6
		clr.l	-(a7)
		pea     SJA_TYPE_JOYSTK
		pea	SJA_Type
		moveq	#0,d0			;port 0
		move.l	a7,a1
		jsr	(_LVOSetJoyPortAttrsA,a6)
		moveq	#1,d0			;port 1
		move.l	a7,a1
		jsr	(_LVOSetJoyPortAttrsA,a6)
		add.w	#12,a7
.noforce
		add.l	#RDA_SIZEOF+(7*4)+JPARGBUFLEN,a7
		movem.l	(a7)+,d0/d2-d3/d6/a2/a6
		rts

.badcustom	move.l	#ERROR_NO_FREE_STORE,d0
		bra	.bad

.badargs	jsr	(_LVOIoErr,a6)
		bra	.bad

.badnum		move.l	#ERROR_BAD_NUMBER,d0
.bad		pea	(.rjp_template,pc)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a5)

.rjp_template	dc.b	"Blue/K,Green/K,Yellow/K,Grey/K,LeftEar/K,RightEar/K,Force/S",0

_rjp_keys	dc.w	$50,0			;F1 Blue - Stop
		dc.w	$51,0			;F2 Green - Shuffle
		dc.w	$52,0			;F3 Yellow - Repeat
		dc.w	$53,0			;F4 Grey - Play/Pause
		dc.w	$54,0			;F5 Left Ear - Reverse
		dc.w	$55,0			;F6 Right Ear - Forward

;----------------------------------------
; ASCII to Integer
; asciiint ::= [+|-] { {<digit>} | ${<hexdigit>} }¹
; hexdigit ::= {012456789abcdefABCDEF}¹
; digit    ::= {0123456789}¹
; IN:	A0 = CPTR ascii | NIL
; OUT:	D0 = LONG integer (on error=0)
;	A0 = CPTR first char after translated ASCII

_atoi		movem.l	d6-d7,-(a7)
		moveq	#0,d0		;default
		move.l	a0,d1		;a0 = NIL ?
		beq	.eend
		moveq	#0,d1
		move.b	(a0)+,d1
		cmp.b	#"-",d1
		seq	d7		;D7 = negative
		beq	.1p
		cmp.b	#"+",d1
		bne	.base
.1p		move.b	(a0)+,d1
.base		cmp.b	#"$",d1
		beq	.hexs

.dec		cmp.b	#"0",d1
		blo	.end
		cmp.b	#"9",d1
		bhi	.end
		sub.b	#"0",d1
		move.l	d0,d6		;D0 * 10
		lsl.l	#3,d0		;
		add.l	d6,d0		;
		add.l	d6,d0		;
		add.l	d1,d0
		move.b	(a0)+,d1
		bra	.dec

.hexs		move.b	(a0)+,d1
.hex		cmp.b	#"0",d1
		blo	.hexl
		cmp.b	#"9",d1
		bhi	.hexl
		sub.b	#"0",d1
		bra	.hexgo
.hexl		cmp.b	#"a",d1
		blo	.hexh
		cmp.b	#"f",d1
		bhi	.hexh
		sub.b	#"a"-10,d1
		bra	.hexgo
.hexh		cmp.b	#"A",d1
		blo	.end
		cmp.b	#"F",d1
		bhi	.end
		sub.b	#"A"-10,d1
.hexgo		lsl.l	#4,d0		;D0 * 16
		add.l	d1,d0
		move.b	(a0)+,d1
		bra	.hex

.end		subq.l	#1,a0
		tst.b	d7
		beq	.eend
		neg.l	d0
.eend		movem.l	(a7)+,d6-d7
		rts
	ENDC

;-----------------------
; not implemented functions

SetLanguageSelection

		illegal

;-----------------------
; returns the current language selection
; IN:	-
; OUT:	D0 = ULONG language

GetLanguageSelection
		move.l	(_language,pc),d0
		rts

_ll_inc_a1	addq.l	#1,(a1)
	moveq	#0,d0
	rts

lbC0004F0	tst.w	d1
	bne.b	lbC0004FC
	subq.b	#1,($23,a5)
	bpl.b	lbC000512
	bra.b	lbC000502

lbC0004FC	addq.b	#1,($23,a5)
	bne.b	lbC000512
lbC000502	movea.l	($3C,a5),a1
	move.b	($22,a5),d0
	jsr	(_LVOSetTaskPri,a6)
	move.b	d0,($22,a5)
lbC000512	rts

SwitchReq	tst.w	d1
	bne.b	KillReq
RestoreReq	subq.b	#1,($24,a6)
	bpl.b	.end
	movea.l	($54,a6),a0
	move.l	($22,a0),($26,a0)
	move.l	a6,-(sp)
	movea.l	($34,a6),a6
	jsr	(_LVOCacheClearU,a6)
	movea.l	(sp)+,a6
.end	rts

KillReq	addq.b	#1,($24,a6)
	bne.b	.end
	movea.l	($54,a6),a1
	lea	($30,a1),a0
	move.l	a0,($26,a1)
	move.l	a6,-(sp)
	movea.l	($34,a6),a6
	jsr	(_LVOCacheClearU,a6)
	movea.l	(sp)+,a6
.end	rts

lbC000558	move.l	d1,-(sp)
	move.w	($26,a5),d0
	bge.w	lbC000568
	bsr	lbC00061E
lbC000568	move.l	(sp)+,d1
	moveq	#-1,d0
	cmp.l	#2,d1
	bcs.b	lbC00057E
	bhi.w	lbC000610
	moveq	#0,d1
	move.w	($26,a5),d1
lbC00057E	tst.l	d1
	bmi.w	lbC000610
	lea	(-$3C,sp),sp
	move.l	d1,-(sp)
	lea	($1B4,a5),a0
	jsr	(_LVOObtainSemaphore,a6)
	move.l	(sp)+,d1
	suba.l	a1,a1
	move.l	d1,-(sp)
	jsr	(_LVOFindTask,a6)
	move.l	(sp)+,d1
	movea.l	($54,a5),a0
	move.l	d0,($10,a0)
	move.b	#4,(15,a0)
	move.b	#0,(14,a0)
	move.l	a0,(14,sp)
	move.l	#0,($38,sp)
	move.l	d1,($34,sp)
	move.l	#6,($30,sp)
	lea	(cddevice.MSG,pc),a0
	moveq	#0,d0
	movea.l	sp,a1
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	tst.l	d0
	bne.b	lbC000602
	move.w	#$21,($1C,sp)
	lea	($30,sp),a1
	move.l	a1,($28,sp)
	move.l	#0,($24,sp)
	movea.l	sp,a1
	jsr	(_LVODoIO,a6)
	movea.l	sp,a1
	move.l	d0,-(sp)
	jsr	(_LVOCloseDevice,a6)
	move.l	(sp)+,d0
lbC000602	movea.l	(14,sp),a0
	lea	($3C,sp),sp
	move.b	#2,(14,a0)
lbC000610	move.l	d0,-(sp)
	lea	($1B4,a5),a0
	jsr	(_LVOReleaseSemaphore,a6)
	move.l	(sp)+,d0
	rts

lbC00061E	lea	($1B4,a5),a0
	jsr	(_LVOObtainSemaphore,a6)
	lea	(-$3C,sp),sp
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	movea.l	($54,a5),a0
	move.l	d0,($10,a0)
	move.b	#4,(15,a0)
	move.b	#0,(14,a0)
	move.l	a0,(14,sp)
	lea	(cddevice.MSG,pc),a0
	moveq	#0,d0
	movea.l	sp,a1
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	tst.l	d0
	bne.b	lbC000682
	move.w	#$20,($1C,sp)
	lea	($30,sp),a1
	move.l	a1,($28,sp)
	move.l	#12,($24,sp)
	movea.l	sp,a1
	jsr	(_LVODoIO,a6)
	movea.l	sp,a1
	move.l	d0,-(sp)
	jsr	(_LVOCloseDevice,a6)
	move.l	(sp)+,d0
	beq.b	lbC000686
lbC000682	moveq	#0,d0
	bra.b	lbC00068A

lbC000686	move.w	($3A,sp),d0
lbC00068A	movea.l	(14,sp),a0
	lea	($3C,sp),sp
	move.b	#2,(14,a0)
	move.w	d0,($26,a5)
	lea	($1B4,a5),a0
	jmp	(_LVOReleaseSemaphore,a6)

cddevice.MSG	db	'cd.device',0

SystemControlA	movem.l	d7/a4-a6,-(sp)
	movea.l	a6,a5
	lea	(-8,sp),sp
	move.l	a1,(sp)
	move.l	a1,(4,sp)
	movea.l	($34,a5),a6
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,d7
_sc_loop	movea.l	($38,a5),a6
	movea.l	sp,a0
	jsr	(_LVONextTagItem,a6)
	movea.l	($34,a5),a6
	tst.l	d0
	bne.b	_sc_call
lbC0006DE	addq.l	#8,sp
	move.l	d0,-(sp)
	move.b	($23,a5),d0
	and.b	($25,a5),d0
	bpl.b	.end
	sub.l	($3C,a5),d7
	bne.b	.end
	move.l	d7,($3C,a5)
.end	movem.l	(sp)+,d0/d7/a4-a6
	rts

_sc_call	movea.l	d0,a0
	move.l	(a0)+,d0
	move.l	(a0)+,d1
	sub.l	#$80C00000,d0
	bmi.b	_sc_loop
	cmp.w	#5,d0
	bgt.b	_sc_loop
	rol.w	#1,d0
	move.w	(.jmp,pc,d0.w),d0
	jmp	(.jmp,pc,d0.w)

.jmp	dw	_sc_TakeOverSys-.jmp
	dw	_sc_KillReq-.jmp
	dw	_sc_CDReboot-.jmp
	dw	_sc_StopInput-.jmp
	dw	_sc_AddCreateKeys-.jmp
	dw	_sc_RemCreateKeys-.jmp

_sc_TakeOverSys	move.l	#$80C00000,d0
	bsr.w	lbC0007EE
	bne.w	lbC0007E4
	bsr.w	lbC0004F0
	bra.b	_sc_loop

_sc_KillReq	exg	a5,a6
	bsr.w	SwitchReq
	exg	a5,a6
	bra.b	_sc_loop

_sc_CDReboot	bsr.w	lbC000558
	tst.l	d0
	beq.b	_sc_loop
	move.l	#$80C00002,d0
	bra.w	lbC0007E4

_sc_StopInput	move.l	#$80C00003,d0
	bsr.w	lbC0007EE
	bne.w	lbC0007E4
	bsr.w	lbC000B1C
	bra.w	_sc_loop

_sc_AddCreateKeys	move.l	#$80C00004,d0
	cmp.l	#1,d1
	bgt.b	lbC0007E4
	move.l	d1,d0
	mulu.w	#$40,d1
	lea	($60,a5,d1.l),a4
	lea	(14,a4),a0
	jsr	(_LVOObtainSemaphore,a6)
	addq.b	#1,(12,a4)
	bne.b	lbC0007AC
	bsr.w	lbC001902
	move.l	d0,(8,a4)
	bne.b	lbC0007AC
	lea	(14,a4),a0
	jsr	(_LVOReleaseSemaphore,a6)
	move.l	#$80C00004,d0
	bra.b	lbC0007E4

lbC0007AC	lea	(14,a4),a0
	jsr	(_LVOReleaseSemaphore,a6)
	bra.w	_sc_loop

_sc_RemCreateKeys	move.l	#$80C00005,d0
	cmp.l	#1,d1
	bgt.b	lbC0007E4
	move.l	d1,d0
	mulu.w	#$40,d1
	lea	($60,a5,d1.l),a4
	subq.b	#1,(12,a4)
	bpl.w	_sc_loop
	movea.l	(8,a4),a0
	bsr.w	lbC001A16
	bra.w	_sc_loop

lbC0007E4	movea.l	(4,sp),a1
	bsr.b	lbC000806
	bra.w	lbC0006DE

lbC0007EE	jsr	(_LVOForbid,a6)
	tst.l	($3C,a5)
	bne.b	lbC0007FC
	move.l	d7,($3C,a5)
lbC0007FC	jsr	(_LVOPermit,a6)
	cmp.l	($3C,a5),d7
	rts

lbC000806	movem.l	d0/d7,-(sp)
	move.l	d0,d7
	move.l	a1,-(sp)
lbC00080E	movea.l	($38,a5),a6
	lea	(sp),a0
	jsr	(_LVONextTagItem,a6)
	movea.l	($34,a5),a6
	movea.l	d0,a0
	move.l	(a0)+,d0
	cmp.l	d0,d7
	bne.b	lbC00082C
	movea.l	(sp)+,a1
	movem.l	(sp)+,d0/d7
	rts

lbC00082C	move.l	(a0)+,d1
	sub.l	#$80C00000,d0
	bmi.b	lbC00080E
	cmp.w	#5,d0
	bgt.b	lbC00080E
	rol.w	#1,d0
	move.w	(lbW000846,pc,d0.w),d0
	jmp	(lbW000846,pc,d0.w)

lbW000846	dw	lbC000852-lbW000846
	dw	lbC00085A-lbW000846
	dw	lbC000866-lbW000846
	dw	lbC000878-lbW000846
	dw	lbC00089E-lbW000846
	dw	lbC000880-lbW000846

lbC000852	bsr.b	lbC0008BC
	bsr.w	lbC0004F0
	bra.b	lbC00080E

lbC00085A	bsr.b	lbC0008BC
	exg	a5,a6
	bsr.w	SwitchReq
	exg	a5,a6
	bra.b	lbC00080E

lbC000866	cmp.l	#1,d1
	bpl.b	lbC000872
	eori.w	#1,d1
lbC000872	bsr.w	lbC000558
	bra.b	lbC00080E

lbC000878	bsr.b	lbC0008BC
	bsr.w	lbC000B1C
	bra.b	lbC00080E

lbC000880	move.l	d1,d0
	mulu.w	#$40,d1
	lea	($60,a5,d1.l),a4
	addq.b	#1,(12,a4)
	bne.w	lbC00080E
	bsr.w	lbC001902
	move.l	d0,(8,a4)
	bra.w	lbC00080E

lbC00089E	move.l	d1,d0
	mulu.w	#$40,d1
	lea	($60,a5,d1.l),a4
	subq.b	#1,(12,a4)
	bpl.w	lbC00080E
	move.l	(8,a4),d0
	bsr.w	lbC001A16
	bra.w	lbC00080E

lbC0008BC	tst.w	d1
	seq	d1
	rts

AddTimerInt	movem.l	a0/a1/a4-a6,-(sp)
	movea.l	a6,a5
	movea.l	($34,a6),a6
	jsr	(_LVOForbid,a6)
	tst.l	($F2,a5)
	beq.b	lbC0008E4
	jsr	(_LVOPermit,a6)
	movem.l	(sp)+,a0/a1/a4-a6
	moveq	#0,d0
	rts

lbC0008E4	movem.l	(sp)+,a0/a1
	lea	($E0,a5),a4
	move.l	a0,($12,a4)
	move.l	a1,(14,a4)
	clr.b	(9,a4)
	move.b	#2,(8,a4)
	move.l	(10,a5),(10,a4)
	jsr	(_LVOPermit,a6)
	jsr	(_LVODisable,a6)
	lea	(ciaaresource.MSG,pc),a1
	bsr	lbC000A3C
	bpl.b	lbC000934
	movea.l	($34,a5),a6
	lea	(ciabresource.MSG,pc),a1
	bsr	lbC000A3C
	bpl.b	lbC000934
	moveq	#0,d0
	move.l	d0,($12,a4)
	movea.l	($34,a5),a6
	bra.b	lbC000970

lbC000934	move.l	a6,($18,a4)
	move.w	d0,($16,a4)
	bne.b	lbC000950
	moveq	#14,d1
	rol.l	#8,d1
	move.l	#$100CE,d0
	movea.l	#$BFE001,a1
	bra.b	lbC000960

lbC000950	moveq	#15,d1
	rol.l	#8,d1
	move.l	#$2008E,d0
	movea.l	#$BFD000,a1
lbC000960	and.b	d0,(a1,d1.w)
	swap	d0
	jsr	(_LVOSetICR,a6)
	movea.l	($34,a5),a6
	move.l	a4,d0
lbC000970	jsr	(_LVOEnable,a6)
	movem.l	(sp)+,a4-a6
	rts

StopTimerInt	tst.w	($16,a1)
	bne.b	lbC000990
	moveq	#14,d1
	rol.l	#8,d1
	move.w	#$CE,d0
	movea.l	#$BFE001,a1
	bra.b	lbC00099E

lbC000990	moveq	#15,d1
	rol.l	#8,d1
	move.w	#$8E,d0
	movea.l	#$BFD000,a1
lbC00099E	and.b	d0,(a1,d1.w)
	rts

StartTimerInt	movem.l	d1-d3,-(sp)
	tst.w	($16,a1)
	bne.b	lbC0009C6
	moveq	#14,d2
	rol.l	#8,d2
	movea.l	#$400,a1
	move.l	#$100C6,d3
	movea.l	#$BFE001,a0
	bra.b	lbC0009DC

lbC0009C6	moveq	#15,d2
	rol.l	#8,d2
	movea.l	#$600,a1
	move.l	#$10086,d3
	movea.l	#$BFD000,a0
lbC0009DC	and.b	d3,(a0,d2.w)
	tst.w	d1
	bne.b	lbC0009EA
	ori.b	#8,(a0,d2.w)
lbC0009EA	move.l	($2C,a6),d1
	lsr.l	#1,d0
	lsr.l	#4,d1
	mulu.w	d1,d0
	divu.w	#$7A12,d0
	bne.b	lbC0009FC
	addq.b	#1,d0
lbC0009FC	adda.l	a0,a1
	move.b	d0,(a1)
	lsr.w	#8,d0
	move.b	d0,($100,a1)
	tst.w	(2,sp)
	beq.b	lbC000A12
	swap	d3
	or.b	d3,(a0,d2.w)
lbC000A12	movem.l	(sp)+,d1-d3
	rts

RemTimerInt	move.l	a6,-(sp)
	move.l	a1,-(sp)
	beq.b	lbC000A36
	move.w	($16,a1),d0
	movea.l	($18,a1),a6
	jsr	(-12,a6)
	movem.l	(sp)+,a1
	clr.l	($12,a1)
	movea.l	(sp)+,a6
	rts

lbC000A36	movem.l	(sp)+,a1/a6
	rts

lbC000A3C	jsr	(_LVOOpenResource,a6)
	movea.l	d0,a6
	movea.l	a4,a1
	move.w	#0,d0
	move.w	d0,-(sp)
	jsr	(_LVOAddICRVector,a6)
	tst.l	d0
	beq.b	lbC000A66
	movea.l	a4,a1
	move.w	#1,d0
	move.w	d0,(sp)
	jsr	(_LVOAddICRVector,a6)
	tst.l	d0
	beq.b	lbC000A66
	move.w	#$FFFF,(sp)
lbC000A66	move.w	(sp)+,d0
	rts

ElapsedTime	movem.l	d2/d3/a6,-(sp)
	move.l	(4,a0),-(sp)
	move.l	(a0),-(sp)
	movea.l	($40,a6),a6
	jsr	(_LVOReadEClock,a6)
	movem.l	(a0)+,d1/d2
	sub.l	(4,sp),d2
	move.l	(sp)+,d3
	addq.w	#4,sp
	subx.l	d3,d1
	bpl.b	lbC000A90
	neg.l	d2
	negx.l	d1
lbC000A90	swap	d1
	tst.w	d1
	bne.b	lbC000AAA
	swap	d2
	move.w	d2,d1
	clr.w	d2
	divu.l	d0,d1:d2
	bvs.b	lbC000AAA
	move.l	d2,d0
lbC000AA4	movem.l	(sp)+,d2/d3/a6
	rts

lbC000AAA	moveq	#-1,d0
	bra.b	lbC000AA4

	movem.l	d2/d3/a6,-(sp)
	move.l	(4,a0),-(sp)
	move.l	(a0),-(sp)
	movea.l	($40,a6),a6	;timer
	jsr	(_LVOReadEClock,a6)
	movem.l	(a0)+,d1/d2
	sub.l	(4,sp),d2
	move.l	(sp)+,d3
	addq.w	#4,sp
	subx.l	d3,d1
	bpl.b	lbC000AD4
	neg.l	d2
	negx.l	d1
lbC000AD4	cmp.l	#15,d1
	bgt.b	lbC000AAA
	lsr.l	#4,d0
	and.w	#15,d1
	and.w	#$FFF0,d2
	or.w	d1,d2
	ror.l	#4,d2
	divu.w	d0,d2
	bvs.b	lbC000AAA
	move.l	d2,d1
	swap	d2
	clr.w	d1
	divu.w	d0,d1
	move.w	d1,d2
	move.l	d2,d0
	movem.l	(sp)+,d2/d3/a6
	rts

ciaaresource.MSG	db	'ciaa.resource',0
ciabresource.MSG	db	'ciab.resource',0

lbC000B1C	tst.w	d1
	bne.b	lbC000B96
	subq.b	#1,($25,a5)
	bpl.w	lbC000BEE
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	movea.l	($54,a5),a0
	move.l	d0,($10,a0)
	move.b	#4,(15,a0)
	move.b	#0,(14,a0)
	lea	(-$30,sp),sp
	move.l	a0,(14,sp)
	move.l	($44,a5),($14,sp)
	move.w	#5,($1C,sp)
	movea.l	sp,a1
	jsr	(_LVODoIO,a6)
	lea	(gameportdevic.MSG,pc),a0
	movea.l	sp,a1
	moveq	#0,d0
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	bne.b	lbC000B7E
	move.w	#5,($1C,sp)
	movea.l	sp,a1
	jsr	(_LVODoIO,a6)
	movea.l	sp,a1
	jsr	(_LVOCloseDevice,a6)
lbC000B7E	lea	(inputdevice.MSG,pc),a0
	movea.l	sp,a1
	moveq	#0,d0
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	bne.b	lbC000BE0
	move.w	#1,($1C,sp)
	bra.b	lbC000BD4

lbC000B96	addq.b	#1,($25,a5)
	bne.b	lbC000BEE
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	movea.l	($54,a5),a0
	move.l	d0,($10,a0)
	move.b	#4,(15,a0)
	move.b	#0,(14,a0)
	lea	(-$30,sp),sp
	move.l	a0,(14,sp)
	lea	(inputdevice.MSG,pc),a0
	movea.l	sp,a1
	moveq	#0,d0
	move.l	d0,d1
	jsr	(_LVOOpenDevice,a6)
	bne.b	lbC000BE0
	move.w	#6,($1C,sp)
lbC000BD4	movea.l	sp,a1
	jsr	(_LVODoIO,a6)
	movea.l	sp,a1
	jsr	(_LVOCloseDevice,a6)
lbC000BE0	movea.l	(14,sp),a0
	lea	($30,sp),sp
	move.b	#2,(14,a0)
lbC000BEE	rts

libportnumoffset	dw	$60
	dw	$A0
	dw	$134
	dw	$174

;-----------------------
; return the state of the selected joy/mouse port
; IN:	D0 = ULONG portNumber
; OUT:	D0 = ULONG portState

ReadJoyPort

	IFD JOYPADEMU

.readjoyport	cmp	#1,d1			;only port 1
		bne	.rjp_original
		bsr	.rjp_original

		move.l	d0,d1
		clr.b	d1
		rol.l	#4,d1
		cmp.b	#JP_TYPE_JOYSTK>>28,d1
		beq	.rjp_ok
		cmp.b	#JP_TYPE_GAMECTLR>>28,d1
		bne	.rjp_end
.rjp_ok		move.l	d0,-(a7)
		moveq	#6,d1			;amount of keys in array
		lea	(_rjp_keys,pc),a0
		jsr	(_LVOQueryKeys,a6)
		move.l	(a7)+,d0
		and.l	#~(JP_TYPE_MASK),d0
		or.l	#JP_TYPE_GAMECTLR,d0
		tst.w	(_rjp_keys+2,pc)
		beq	.rjp_f2
		bset	#JPB_BUTTON_BLUE,d0
.rjp_f2		tst.w	(_rjp_keys+6,pc)
		beq	.rjp_f3
		bset	#JPB_BUTTON_GREEN,d0
.rjp_f3		tst.w	(_rjp_keys+10,pc)
		beq	.rjp_f4
		bset	#JPB_BUTTON_YELLOW,d0
.rjp_f4		tst.w	(_rjp_keys+14,pc)
		beq	.rjp_f5
		bset	#JPB_BUTTON_PLAY,d0
.rjp_f5		tst.w	(_rjp_keys+18,pc)
		beq	.rjp_f6
		bset	#JPB_BUTTON_REVERSE,d0
.rjp_f6		tst.w	(_rjp_keys+22,pc)
		beq	.rjp_end
		bset	#JPB_BUTTON_FORWARD,d0
.rjp_end	rts

.rjp_original

	ENDC

	move.w	d0,d1	;portnumber 0..3
	add.b	d1,d1
	lea	(libportnumoffset,pc),a0
	move.w	(a0,d1.w),d1
	lea	(a6,d1.w),a0
	move.l	($3C,a0),d1
	beq.b	initport
	movea.l	d1,a0
	jmp	(a0)

initport	movem.l	d2-d7/a2-a6,-(sp)
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	movea.l	a6,a5
	moveq	#0,d6
	move.l	d0,d2
	cmp.l	#3,d2
	bhi.w	RJP_error
	movea.l	a0,a2
	btst	#0,d2
	bne.b	lbC000CD2
	bset	#1,(13,a2)
	bne.w	RJP_error
	move.l	#$A0000,d7
	move.w	(joy0dat,a3),d7
	move.w	#6,d4
	move.w	#$200,d5
	btst	#0,(13,a2)
	bne.b	lbC000CEE
	movea.l	($34,a5),a6
	movea.l	($90,a6),a0
	lea	(gameportdevic.MSG,pc),a1
	jsr	(_LVOForbid,a6)
	jsr	(_LVOFindName,a6)
	beq.b	lbC000CB6
	bset	#0,(13,a2)
	bclr	#3,(13,a2)
	move.l	d0,($4C,a5)
	movea.l	d0,a1
	moveq	#5,d0
	jsr	(_LVORemIntServer,a6)
	moveq	#5,d0
	lea	($108,a5),a1
	jsr	(_LVOAddIntServer,a6)
lbC000CB6	jsr	(_LVOPermit,a6)
	bsr.w	joydir_d7_d0
	beq.b	lbC000CC8
	or.l	#$200A0000,d7
	bra.b	lbC000CCE

lbC000CC8	or.l	#$40000000,d7
lbC000CCE	move.l	d7,(a2)
	bra.b	lbC000CEE

lbC000CD2	bset	#1,($6D,a5)
	bne.w	RJP_error
	move.l	#$C0000,d7
	move.w	(joy1dat,a3),d7
	move.w	#7,d4
	move.w	#$2000,d5
lbC000CEE	movea.l	($58,a5),a6	;potgo
	bclr	#3,(13,a2)
	beq.b	lbC000D34
	bsr.w	joydir_d7_d0
	beq.b	lbC000D08
	or.l	#$200A0000,d7
	bra.b	lbC000D0E

lbC000D08	or.l	#$40000000,d7
lbC000D0E	move.l	d7,(a2)
	move.w	d5,d1
	lsr.w	#1,d1
	or.w	d5,d1
	move.w	d1,d0
	lsl.w	#2,d1
	or.w	d1,d0
	move.w	d0,d3
	jsr	(_LVOAllocPotBits,a6)
	cmp.w	d3,d0
	beq.b	lbC000D34
	jsr	(_LVOFreePotBits,a6)
	bset	#3,(13,a2)
	bra.w	lbC000E14

lbC000D34	move.w	(a2),d2
	and.w	#$FF,d2
	bne.b	lbC000DB4
lbC000D3C	bset	#2,(13,a2)
	bset	d4,(ciaddra,a4)
	bclr	d4,(ciapra,a4)
	move.w	d5,d1
	lsr.w	#1,d1
	or.w	d5,d1
	move.l	d1,-(sp)
	move.w	d5,d0
	jsr	(_LVOWritePotgo,a6)
	movea.l	#$DFF016,a0
	move.w	d5,d1
	lsl.w	#1,d1
	moveq	#0,d3
	moveq	#8,d0
	btst	#4,(13,a2)
	beq.b	lbC000D78
	add.w	#9,d0
	bra.b	lbC000D78

lbC000D72	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
lbC000D78	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(a0),d2
	bset	d4,(ciapra,a4)
	bclr	d4,(ciapra,a4)
	and.w	d1,d2
	bne.b	lbC000D8E
	bset	d0,d3
lbC000D8E	dbra	d0,lbC000D72
	move.l	(sp)+,d1
	move.w	d1,d0
	jsr	(_LVOWritePotgo,a6)
	bclr	d4,(ciaddra,a4)
	bclr	#2,(13,a2)
	and.w	#$1FF,d3
	lsr.w	#1,d3
	bcc.b	lbC000DB4
	cmp.b	#$FF,d3
	bne.w	lbC000E3C
lbC000DB4	btst	#4,(13,a2)
	bne.b	lbC000E14
	move.w	d5,d1
	lsr.w	#1,d1
	or.w	d5,d1
	move.w	d1,d0
	lsl.w	#2,d1
	or.w	d1,d0
	move.w	d0,d1
	jsr	(_LVOWritePotgo,a6)
	move.b	(ciapra,a4),d1
	btst	d4,d1
	bne.b	lbC000DDA
	ori.l	#$400000,d6
lbC000DDA	move.w	(potinp,a3),d1
	not.w	d1
	move.w	d1,d2
	lsr.w	#1,d1
	and.w	d5,d1
	beq.b	lbC000DEE
	ori.l	#$800000,d6
lbC000DEE	move.w	d2,d1
	lsl.w	#1,d1
	and.w	d5,d1
	beq.b	lbC000DFC
	ori.l	#$20000,d6
lbC000DFC	move.l	(a2),d2
	and.l	#$30000000,d2
	beq.b	lbC000E28
	rol.l	#5,d2
	move.w	(lbC000E20,pc,d2.w),d2
	jmp	(lbW000E22,pc,d2.w)

lbC000E10	move.w	d7,(2,a2)
lbC000E14	bclr	#1,($6D,a5)
RJP_error	move.l	d6,d0
	movem.l	(sp)+,d2-d7/a2-a6
lbC000E20	rts

lbW000E22	dw	lbC000E28-lbW000E22
	dw	lbC000E72-lbW000E22
	dw	lbC000ECA-lbW000E22

lbC000E28	cmp.w	(2,a2),d7
	bne.w	lbC000EC6
	or.l	#$40000000,d6
	move.w	#$4000,(a2)
	bra.b	lbC000E10

lbC000E3C	move.w	#$1000,d0
	cmp.w	(a2),d0
	beq.b	lbC000E5A
	move.w	d0,-(sp)
	move.w	d5,d1
	lsl.w	#2,d1
	or.w	d5,d1
	moveq	#0,d0
	jsr	(_LVOWritePotgo,a6)
	move.w	(sp)+,d0
	move.w	d0,(a2)
	bra.w	lbC000D3C

lbC000E5A	swap	d3
	move.l	d3,d6
	swap	d7
	move.w	(a3,d7.w),d7
	bsr.w	joydir_d7_d0
	or.w	d0,d6
	ori.l	#$10000000,d6	;type gamectlr
	bra.b	lbC000E10

lbC000E72	cmp.w	(2,a2),d7
	beq.b	lbC000EB4
	bsr.b	joydir_d7_d0
	bne.b	lbC000EA6
	movea.l	($5C,a5),a0
	move.l	(a0),d0
	sub.l	(4,a2),d0
	beq.b	lbC000EAE
	subq.l	#1,d0
	bge.b	lbC000E94
	bset	#6,(13,a2)
	bne.b	lbC000EA6
lbC000E94	move.l	(a0),(4,a2)
	move.w	(a2),d0
	subq.w	#1,d0
	cmp.w	#$2000,d0
	blt.b	lbC000EC6
	move.w	d0,(a2)
	bra.b	lbC000EBA

lbC000EA6	movea.l	($5C,a5),a0
	move.l	(a0),(4,a2)
lbC000EAE	move.w	#$200A,d0
	move.w	d0,(a2)
lbC000EB4	andi.b	#$BF,(13,a2)
lbC000EBA	or.w	d7,d6
	ori.l	#$20000000,d6	;type mouse
	bra.w	lbC000E10

lbC000EC6	move.w	#$3001,(a2)
lbC000ECA	bsr.b	joydir_d7_d0
	beq.b	lbC000ED4
	move.w	#$200A,(a2)
	bra.b	lbC000E72

lbC000ED4	move.w	d0,d6
	move.w	(a2),d0
	subq.w	#1,d0
	cmp.w	#$3000,d0
	bge.b	lbC000EE4
	move.w	#$3008,d0
lbC000EE4	move.w	d0,(a2)
	ori.l	#$30000000,d6	;type joystck
	bra.w	lbC000E10

joydir_d7_d0	move.w	d7,d1
	move.w	d1,d0
	lsr.w	#1,d0
	eor.w	d0,d1
	and.w	#$101,d1
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d1
	lsr.w	#7,d0
	lsr.w	#5,d1
	or.w	d1,d0
	move.b	d0,d1
	lsr.b	#1,d1
	and.b	#$FD,d1
	and.b	d0,d1
	rts

lbC000F16	btst	#2,($6D,a1)
	bne.b	lbC000F2C
	movea.l	($4C,a1),a1
	movea.l	($12,a1),a5
	movea.l	(14,a1),a1
	jmp	(a5)

lbC000F2C	moveq	#0,d0
	rts

SetJoyPortAttrsA	movem.l	d0/d2/a2/a3,-(sp)
	movem.l	d0/a1/a5/a6,-(sp)
	movea.l	a6,a5
	lea	($60,a6),a2
	btst	#0,(13,a2)
	bne.b	lbC000F82
	movea.l	($34,a5),a6
	movea.l	(IVVERTB,a6),a0
	lea	(gameportdevic.MSG,pc),a1
	jsr	(_LVOForbid,a6)
	jsr	(_LVOFindName,a6)
	beq.b	lbC000F7E
	bset	#0,(13,a2)
	bclr	#3,(13,a2)
	move.l	d0,($4C,a5)
	movea.l	d0,a1
	moveq	#5,d0
	jsr	(_LVORemIntServer,a6)
	moveq	#5,d0
	lea	($108,a5),a1
	jsr	(_LVOAddIntServer,a6)
lbC000F7E	jsr	(_LVOPermit,a6)
lbC000F82	movem.l	(sp)+,d0/a1/a5/a6
	cmp.l	#3,d0
	bls.b	lbC000F94
	moveq	#0,d0
	bra.w	lbC001062

lbC000F94	add.b	d0,d0
	lea	(libportnumoffset,pc),a0
	move.w	(a0,d0.w),d0
	lea	(a6,d0.w),a3
	moveq	#0,d2
	move.l	a1,-(sp)
lbC000FA6	movea.l	sp,a2
	move.l	a6,-(sp)
	movea.l	($38,a6),a6
	movea.l	a2,a0
	jsr	(_LVONextTagItem,a6)
	movea.l	(sp)+,a6
	tst.l	d0
	beq.w	lbC00102E
	movea.l	d0,a0
	cmpi.l	#$80C00101,(a0)
	bne.b	lbC000FE4
	move.l	(4,a0),d0
	bne.b	lbC000FD0
	moveq	#-1,d2
	bra.b	lbC000FE4

lbC000FD0	moveq	#12,d1
	lsl.w	d1,d0
	move.w	(a3),d1
	and.w	#$FF,d1
	and.w	#$FF00,d0
	or.w	d0,d1
	move.w	d1,(a3)
	moveq	#1,d2
lbC000FE4	cmpi.l	#$80C00102,(a0)
	bne.b	lbC00102A
	moveq	#0,d0
	move.l	d0,($3C,a3)
	addq.b	#1,($127,a6)
	bset	#3,(13,a3)
	bne.b	lbC001026
	move.l	(4,sp),d0
	bne.b	lbC00100C
	moveq	#0,d0
	move.w	#0,d0
	bra.b	lbC00101A

lbC00100C	cmp.l	#1,d0
	bne.b	lbC001026
	moveq	#0,d0
	move.w	#$F000,d0
lbC00101A	move.l	a6,-(sp)
	movea.l	($58,a6),a6
	jsr	(_LVOFreePotBits,a6)
	movea.l	(sp)+,a6
lbC001026	jsr	(_LVOPermit,a6)
lbC00102A	bra.w	lbC000FA6

lbC00102E	tst.b	d2
	beq.b	lbC00105E
	bmi.b	lbC001058
	moveq	#12,d0
	move.w	(a3),d1
	lsr.w	d0,d1
	move.l	(4,sp),d0
	lsl.b	#2,d0
	or.b	d1,d0
	lsl.b	#1,d0
	lea	(port_type_list,pc),a0
	move.w	(a0,d0.w),d0
	lea	(a0,d0.w),a0
	move.l	a0,($3C,a3)
	bra.b	lbC00105E

lbC001058	moveq	#0,d0
	move.l	d0,($3C,a3)
lbC00105E	addq.l	#4,sp
	moveq	#1,d0
lbC001062	movem.l	(sp)+,d0/d2/a2/a3
	rts

port_type_list	dw	port_unknown-port_type_list
	dw	port_gamectlr_0-port_type_list
	dw	port_mouse_0-port_type_list
	dw	port_joystck_0-port_type_list
	dw	port_unknown-port_type_list
	dw	port_gamectlr_1-port_type_list
	dw	port_mouse_1-port_type_list
	dw	port_joystck_1-port_type_list
	dw	port_unknown-port_type_list
	dw	port_gamectlr_2-port_type_list
	dw	port_unknown-port_type_list
	dw	port_unknown-port_type_list
	dw	port_unknown-port_type_list
	dw	port_gamectlr_3-port_type_list
	dw	port_unknown-port_type_list
	dw	port_unknown-port_type_list

port_unknown	moveq	#0,d0
	rts

port_mouse_1	movem.l	d2/d4/a3-a6,-(sp)
	movea.l	a6,a5
	bset	#1,($6D,a5)
	bne.b	lbC0010FA
	move.w	#$F000,d1
	move.w	d1,d0
	movea.l	($58,a6),a6
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#7,d4
	moveq	#0,d2
	move.b	(ciapra,a4),d1
	btst	d4,d1
	bne.b	lbC0010C6
	or.l	#$400000,d2
lbC0010C6	move.w	(potinp,a3),d1
	btst	#12,d1
	bne.b	lbC0010D6
	or.l	#$20000,d2
lbC0010D6	btst	#14,d1
	bne.b	lbC0010E2
	or.l	#$800000,d2
lbC0010E2	move.l	#$20000000,d0	;type mouse
	move.w	(joy1dat,a3),d0
	or.l	d2,d0
	bclr	#1,($6D,a5)
	movem.l	(sp)+,d2/d4/a3-a6
	rts

lbC0010FA	moveq	#0,d0
	movem.l	(sp)+,d2/d4/a3-a6
	rts

port_mouse_0	movem.l	d2/d4/a3-a6,-(sp)
	movea.l	a6,a5
	bset	#1,($6D,a5)
	bne.b	lbC001172
	move.w	#$F00,d1
	move.w	#$F00,d0
	movea.l	($58,a6),a6
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#6,d4
	moveq	#0,d2
	move.b	(ciapra,a4),d1
	btst	d4,d1
	bne.b	lbC00113E
	or.l	#$400000,d2
lbC00113E	move.w	(potinp,a3),d1
	btst	#8,d1
	bne.b	lbC00114E
	or.l	#$20000,d2
lbC00114E	btst	#10,d1
	bne.b	lbC00115A
	or.l	#$800000,d2
lbC00115A	move.l	#$20000000,d0	;type mouse
	move.w	(joy0dat,a3),d0
	or.l	d2,d0
	bclr	#1,($6D,a5)
	movem.l	(sp)+,d2/d4/a3-a6
	rts

lbC001172	moveq	#0,d0
	movem.l	(sp)+,d2/d4/a3-a6
	rts

port_joystck_0	movem.l	d2/d4/a3-a6,-(sp)
	movea.l	a6,a5
	bset	#1,($6D,a5)
	bne.b	lbC001202
	move.w	#$F00,d1
	move.w	#$F00,d0
	movea.l	($58,a6),a6
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#6,d4
	moveq	#0,d2
	move.b	(ciapra,a4),d1
	btst	d4,d1
	bne.b	lbC0011B6
	or.l	#$400000,d2
lbC0011B6	move.w	(potinp,a3),d1
	btst	#8,d1
	bne.b	lbC0011C6
	or.l	#$20000,d2
lbC0011C6	btst	#10,d1
	bne.b	lbC0011D2
	or.l	#$800000,d2
lbC0011D2	move.w	(joy0dat,a3),d1
	move.w	d1,d0
	lsr.w	#1,d0
	eor.w	d0,d1
	and.w	#$101,d1
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d1
	lsr.w	#7,d0
	lsr.w	#5,d1
	or.w	d1,d0
	or.l	d2,d0
	or.l	#$30000000,d0	;type joystck
	bclr	#1,($6D,a5)
	movem.l	(sp)+,d2/d4/a3-a6
	rts

lbC001202	moveq	#0,d0
	movem.l	(sp)+,d2/d4/a3-a6
	rts

port_joystck_1	movem.l	d2/d4/a3-a6,-(sp)
	movea.l	a6,a5
	moveq	#0,d0
	bset	#1,($6D,a5)
	bne.b	lbC001294
	move.w	#$F000,d1
	move.w	#$F000,d0
	movea.l	($58,a6),a6
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#7,d4
	moveq	#0,d2
	move.b	(ciapra,a4),d1
	btst	d4,d1
	bne.b	lbC001248
	or.l	#$400000,d2
lbC001248	move.w	(potinp,a3),d1
	btst	#12,d1
	bne.b	lbC001258
	or.l	#$20000,d2
lbC001258	btst	#14,d1
	bne.b	lbC001264
	or.l	#$800000,d2
lbC001264	move.w	(joy1dat,a3),d1
	move.w	d1,d0
	lsr.w	#1,d0
	eor.w	d0,d1
	and.w	#$101,d1
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d1
	lsr.w	#7,d0
	lsr.w	#5,d1
	or.w	d1,d0
	or.l	d2,d0
	or.l	#$30000000,d0	;type joystck
	bclr	#1,($6D,a5)
	movem.l	(sp)+,d2/d4/a3-a6
	rts

lbC001294	moveq	#0,d0
	movem.l	(sp)+,d2/d4/a3-a6
	rts

port_gamectlr_0	movem.l	d2-d4/a2-a4/a6,-(sp)
	lea	($60,a6),a2
	bset	#1,(13,a2)
	bne.w	.quit
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#CIAB_GAMEPORT0,d4
	bset	#2,(13,a2)
	bset	d4,(ciaddra,a4)
	bclr	d4,(ciapra,a4)
	movea.l	($58,a6),a6
	move.w	#$200,d0
	move.w	#$300,d1
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom+potinp,a0
	move.w	#$400,d1
	moveq	#0,d3
	moveq	#6,d0
	bra.b	.in

.loop	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
.in	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(a0),d2
	bset	d4,(a4)
	bclr	d4,(a4)
	and.w	d1,d2
	bne.b	.skip
	bset	d0,d3
.skip	dbra	d0,.loop
	move.w	#$300,d0
	move.w	d0,d1
	jsr	(_LVOWritePotgo,a6)
	bclr	d4,(ciaddra,a4)
	bclr	#2,(13,a2)
	lsl.w	#1,d3
	swap	d3
	move.w	(joy0dat,a3),d1
	move.w	d1,d0
	lsr.w	#1,d0
	eor.w	d0,d1
	and.w	#$101,d1
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d1
	lsr.w	#7,d0
	lsr.w	#5,d1
	or.w	d1,d0
	or.l	d3,d0
	or.l	#$10000000,d0
	bclr	#1,(13,a2)
.quit	movem.l	(sp)+,d2-d4/a2-a4/a6
	rts

port_gamectlr_1	movem.l	d2-d4/a2-a4/a6,-(sp)
	lea	($A0,a6),a2
	bset	#1,(-$33,a2)
	bne.w	.quit
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#CIAB_GAMEPORT1,d4
	bset	#2,(-$33,a2)
	bset	d4,(ciaddra,a4)
	bclr	d4,(a4)
	movea.l	($58,a6),a6
	move.w	#$2000,d0
	move.w	#$3000,d1
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom+potinp,a0
	move.w	#$4000,d1
	moveq	#0,d3
	moveq	#6,d0
	bra.b	.in

.loop	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
.in	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(a0),d2
	bset	d4,(a4)
	bclr	d4,(a4)
	and.w	d1,d2
	bne.b	.skip
	bset	d0,d3
.skip	dbra	d0,.loop
	move.w	#$3000,d0
	move.w	d0,d1
	jsr	(_LVOWritePotgo,a6)
	bclr	d4,(ciaddra,a4)
	bclr	#2,(-$33,a2)
	lsl.w	#1,d3
	swap	d3
	move.w	(joy1dat,a3),d1
	move.w	d1,d0
	lsr.w	#1,d0
	eor.w	d0,d1
	and.w	#$101,d1
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d1
	lsr.w	#7,d0
	lsr.w	#5,d1
	or.w	d1,d0
	or.l	d3,d0
	or.l	#$10000000,d0
	bclr	#1,(-$33,a2)
.quit	movem.l	(sp)+,d2-d4/a2-a4/a6
	rts

port_gamectlr_2	movem.l	d2-d4/a2-a4/a6,-(sp)
	lea	($134,a6),a2
	bset	#1,(-$C7,a2)
	bne.w	.quit
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#CIAB_GAMEPORT0,d4
	bset	#2,(-$C7,a2)
	bset	d4,(ciaddra,a4)
	bclr	d4,(ciapra,a4)
	movea.l	($58,a6),a6
	move.w	#$200,d0
	move.w	#$300,d1
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom+potinp,a0
	move.w	#$400,d1
	moveq	#0,d3
	moveq	#$11,d0
	bra.b	.in

.loop	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
.in	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(a0),d2
	bset	d4,(ciapra,a4)
	bclr	d4,(ciapra,a4)
	and.w	d1,d2
	bne.b	.skip
	bset	d0,d3
.skip	dbra	d0,.loop
	move.w	(joy0dat,a3),d2
	move.w	#$300,d0
	move.w	d0,d1
	jsr	(_LVOWritePotgo,a6)
	bclr	d4,(ciaddra,a4)
	bclr	#2,(-$C7,a2)
	lsl.w	#1,d3
	swap	d3
	move.w	d2,d0
	lsr.w	#1,d0
	eor.w	d0,d2
	and.w	#$101,d2
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d2
	lsr.w	#7,d0
	lsr.w	#5,d2
	or.w	d2,d0
	or.l	d3,d0
	or.l	#$10000000,d0
	bclr	#1,(-$C7,a2)
.quit	movem.l	(sp)+,d2-d4/a2-a4/a6
	rts

port_gamectlr_3	movem.l	d2-d4/a2-a4/a6,-(sp)
	lea	($174,a6),a2
	bset	#1,(-$107,a2)	;already running?
	bne.w	.quit
	movea.l	#_custom,a3
	movea.l	#_ciaa,a4
	move.w	#CIAB_GAMEPORT1,d4
	bset	#2,(-$107,a2)
	bset	d4,(ciaddra,a4)
	bclr	d4,(ciapra,a4)
	movea.l	($58,a6),a6	;potgo
	move.w	#$2000,d0	;data
	move.w	#$3000,d1	;mask
	jsr	(_LVOWritePotgo,a6)
	movea.l	#_custom+potinp,a0
	move.w	#$4000,d1
	moveq	#0,d3
	moveq	#$11,d0
	bra.b	.in

.loop	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
.in	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	tst.b	(a4)
	move.w	(a0),d2	;potinp
	bset	d4,(ciapra,a4)
	bclr	d4,(ciapra,a4)
	and.w	d1,d2
	bne.b	.skip
	bset	d0,d3
.skip	dbra	d0,.loop
	move.w	(joy0dat,a3),d2
	move.w	#$3000,d0	;data
	move.w	d0,d1	;mask
	jsr	(_LVOWritePotgo,a6)
	bclr	d4,(ciaddra,a4)
	bclr	#2,(-$107,a2)
	lsl.w	#1,d3
	swap	d3
	move.w	d2,d0
	lsr.w	#1,d0
	eor.w	d0,d2
	and.w	#$101,d2
	and.w	#$101,d0
	ror.b	#1,d0
	ror.b	#1,d2
	lsr.w	#7,d0
	lsr.w	#5,d2
	or.w	d2,d0
	or.l	d3,d0
	or.l	#$10000000,d0	;type gamectlr
	bclr	#1,(-$107,a2)
.quit	movem.l	(sp)+,d2-d4/a2-a4/a6
	rts

QueryKeys	movem.l	d2/a2/a5/a6,-(sp)
	movea.l	a6,a5
	move.b	d1,d2
	movea.l	a0,a2
	movea.l	($34,a6),a6
	suba.l	a1,a1
	jsr	(_LVOFindTask,a6)
	movea.l	($54,a5),a0
	move.l	d0,($10,a0)
	move.b	#4,(15,a0)
	move.b	#0,(14,a0)
	lea	(-$40,sp),sp
	move.l	a0,(14,sp)
	movea.l	sp,a1
	move.l	($44,a5),($14,a1)
	move.w	#10,($1C,a1)
	lea	($30,sp),a0
	move.l	a0,($28,a1)
	move.l	#$10,($24,a1)
	jsr	(_LVODoIO,a6)
	tst.b	d0
	bne.b	lbC0015F8
lbC0015DA	move.w	(a2)+,d1
	move.w	d1,d0
	and.w	#7,d0
	lsr.w	#3,d1
	btst	d0,($30,sp,d1.w)
	beq.b	lbC0015F0
	move.w	#$FFFF,(a2)+
	bra.b	lbC0015F4

lbC0015F0	move.w	#0,(a2)+
lbC0015F4	subq.b	#1,d2
	bne.b	lbC0015DA
lbC0015F8	movea.l	(14,sp),a0
	lea	($40,sp),sp
	move.b	#2,(14,a0)
	movem.l	(sp)+,d2/a2/a5/a6
	rts

AddKBInt	movem.l	a0/a1/a5/a6,-(sp)
	movea.l	a6,a5
	movea.l	($34,a5),a6
	moveq	#$16,d0
	move.l	#$10001,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq.b	lbC001674
	movea.l	d0,a1
	move.b	#2,(8,a1)
	move.l	(sp)+,($12,a1)
	move.l	(sp)+,(14,a1)
	move.l	(10,a5),(10,a1)
	lea	($FC,a5),a0
	jsr	(_LVOForbid,a6)
	cmpa.l	(8,a0),a0
	bne.w	lbC001666
	move.l	(a0),d0
	move.l	a1,(a0)
	movem.l	d0/a0,(a1)
	movea.l	d0,a0
	move.l	a1,(4,a0)
	jsr	(_LVOPermit,a6)
	move.l	a1,d0
	movem.l	(sp)+,a5/a6
	rts

lbC001666	jsr	(_LVOPermit,a6)
	moveq	#$16,d0
	jsr	(_LVOFreeMem,a6)
	moveq	#0,d0
	subq.l	#8,sp
lbC001674	movem.l	(sp)+,a0/a1/a5/a6
	rts

RemKBInt	cmpa.l	#0,a0
	beq.b	lbC0016A6
	move.l	a6,-(sp)
	movea.l	($34,a6),a6
	move.l	a1,-(sp)
	jsr	(_LVOForbid,a6)
	movea.l	(a1)+,a0
	movea.l	(a1),a1
	move.l	a0,(a1)
	move.l	a1,(4,a0)
	jsr	(_LVOPermit,a6)
	movea.l	(sp)+,a1
	moveq	#$16,d0
	jsr	(_LVOFreeMem,a6)
	movea.l	(sp)+,a6
lbC0016A6	rts

_keyread	movem.l	d2/a4-a6,-(sp)
	movea.l	a1,a4
	moveq	#0,d2
	move.b	($BFEC01).l,d2
	not.b	d2
	ror.b	#1,d2
	movea.l	($48,a4),a0
	movea.l	(14,a0),a1
	movea.l	($12,a0),a5
	jsr	(a5)
	cmp.w	#$78,d2
	beq.b	lbC00172E
	move.w	d2,d1
	and.w	#$78,d1
	cmp.w	#$60,d1
	bne.b	lbC0016EC
	move.w	($28,a4),d0
	move.w	d2,d1
	and.w	#7,d1
	bchg	d1,d0
	move.w	d0,($28,a4)
	bra.b	lbC00170A

lbC0016EC	btst	#7,d2
	bne.b	lbC0016F8
	move.w	d2,($2A,a4)
	bra.b	lbC00170A

lbC0016F8	move.w	d2,d1
	bclr	#7,d1
	cmp.w	($2A,a4),d1
	bne.b	lbC00170A
	ori.w	#$FF,($2A,a4)
lbC00170A	move.w	d2,d0
	subi.w	#$F9,d2
	bpl.b	lbC00172E
	movea.l	($FC,a4),a1
	bra.b	lbC001726

lbC001718	movea.l	($12,a1),a5
	movea.l	(14,a1),a1
	jsr	(a5)
	movea.l	(sp)+,a1
	move.w	(sp)+,d0
lbC001726	move.w	d0,-(sp)
	move.l	(a1),-(sp)
	bne.b	lbC001718
	addq.w	#6,sp
lbC00172E	movem.l	(sp)+,d2/a4-a6
	rts

GetKey	move.l	($28,a6),d0
	rts

AddVBlankInt	movem.l	a0/a1/a5/a6,-(sp)
	movea.l	a6,a5
	movea.l	($34,a5),a6
	moveq	#$16,d0
	move.l	#$10001,d1
	jsr	(_LVOAllocMem,a6)
	tst.l	d0
	beq.b	lbC0017A0
	jsr	(_LVOForbid,a6)
	tst.l	($50,a5)
	bne.b	lbC00178E
	move.l	d0,($50,a5)
	jsr	(_LVOPermit,a6)
	movea.l	d0,a1
	move.b	#2,(8,a1)
	move.l	(sp)+,($12,a1)
	move.l	(sp)+,(14,a1)
	move.l	(10,a5),(10,a1)
	moveq	#5,d0
	jsr	(_LVOAddIntServer,a6)
	move.l	($50,a5),d0
	movem.l	(sp)+,a5/a6
	rts

lbC00178E	jsr	(_LVOPermit,a6)
	movea.l	#$16,a1
	exg	d0,a1
	jsr	(_LVOFreeMem,a6)
	moveq	#0,d0
lbC0017A0	movem.l	(sp)+,a0/a1/a5/a6
	rts

RemVBLankInt	movem.l	a5/a6,-(sp)
	movea.l	a6,a5
	movea.l	($34,a5),a6
	move.l	a1,-(sp)
	beq.b	lbC0017CC
	clr.l	($50,a5)
	moveq	#5,d0
	jsr	(_LVORemIntServer,a6)
	movea.l	(sp)+,a1
	moveq	#$16,d0
	jsr	(_LVOFreeMem,a6)
	movem.l	(sp)+,a5/a6
	rts

lbC0017CC	movem.l	(sp)+,a1/a5/a6
	rts

lbC0017D4	movea.l	a1,a5
	move.l	($32,a5),d0
	beq.b	lbC0017EC
	subq.l	#1,($22,a5)
	bne.b	lbC0017EC
	move.l	($26,a5),($22,a5)
	bsr.w	lbC00188E
lbC0017EC	movea.l	($1A,a5),a6
	move.l	($1E,a5),d0
	jsr	(-$1E,a6)
	move.l	d0,d1
	and.l	#$F0000000,d0
	beq.b	lbC001864
	move.l	($2E,a5),d0
	cmp.l	d0,d1
	beq.b	lbC001864
lbC00180A	movem.l	d2/d6/d7/a2,-(sp)
	move.l	d1,d7
	and.l	#$F0000000,d1
	and.l	#$F0000000,d0
	beq.b	lbC001830
	cmp.l	d0,d1
	beq.b	lbC001830
	move.l	d0,d1
	bsr.b	lbC00180A
	move.l	d7,d1
	and.l	#$F0000000,d1
	move.l	d1,d0
lbC001830	move.l	($2E,a5),d6
	move.l	d7,($2E,a5)
	move.l	d6,d2
	eor.l	d7,d2
	lea	(lbB001A68,pc),a2
	bsr.b	lbC001868
	move.l	d7,d0
	and.l	#$F0000000,d0
	cmp.l	#$40000000,d0
	beq.b	lbC001860
	cmp.l	#$20000000,d0
	beq.b	lbC001860
	lea	(lbB001A77,pc),a2
	bsr.b	lbC001868
lbC001860	movem.l	(sp)+,d2/d6/d7/a2
lbC001864	moveq	#0,d0
lbC001866	rts

lbC001868	move.b	(a2)+,d0
	bmi.b	lbC001866
	move.b	(a2)+,d1
	btst	d0,d2
	beq.b	lbC001868
	btst	d0,d7
	bne.b	lbC00187C
	bset	#7,d1
	bra.b	lbC001882

lbC00187C	move.l	($2A,a5),($22,a5)
lbC001882	move.l	($1E,a5),d0
	asl.l	#8,d0
	or.b	d1,d0
	bsr.b	lbC00188E
	bra.b	lbC001868

lbC00188E	movem.l	d2/d3,-(sp)
	move.l	d0,d2
	movea.l	($6C,a5),a6
	jsr	(_LVOPeekQualifier,a6)
	move.l	d0,d3
	movea.l	($16,a5),a6
	lea	($36,a5),a0
	jsr	(_LVOGetMsg,a6)
	tst.l	d0
	beq.b	lbC0018FC
	movea.l	d0,a1
	movea.l	($28,a1),a0
	move.w	#11,($1C,a1)
	move.l	#$16,($24,a1)
	cmp.l	($32,a5),d2
	bne.b	lbC0018CC
	bset	#9,d3
lbC0018CC	cmp.l	#$78,d2
	bne.w	lbC0018DA
	bset	#14,d3
lbC0018DA	clr.l	(a0)+
	move.b	#1,(a0)+
	clr.b	(a0)+
	move.w	d2,(a0)+
	move.w	d3,(a0)+
	clr.l	(a0)+
	jsr	(_LVOSendIO,a6)
	bclr	#7,d2
	beq.b	lbC0018F8
	sub.l	($32,a5),d2
	bne.b	lbC0018FC
lbC0018F8	move.l	d2,($32,a5)
lbC0018FC	movem.l	(sp)+,d2/d3
	rts

lbC001902	movem.l	d2/a2-a4,-(sp)
	move.l	d0,d2
	move.l	#$4B8,d0
	move.l	#(MEMF_PUBLIC|MEMF_CLEAR),d1
	jsr	(_LVOAllocVec,a6)
	movea.l	d0,a4
	tst.l	d0
	beq.w	lbC001A10
	move.l	d2,d0
	exg	a5,a6
	jsr	(-$1E,a6)	;ReadJoyPort
	exg	a6,a5
	and.l	#$F0000000,d0
	beq.w	lbC001A10
	move.l	a6,($16,a4)
	move.l	a5,($1A,a4)
	move.l	d2,($1E,a4)
	lea	(InputMapper.MSG,pc),a0
	move.l	a0,(10,a4)
	move.l	a4,(14,a4)
	lea	(lbC0017D4,pc),a0
	move.l	a0,($12,a4)
	move.b	#2,($44,a4)
	lea	($4A,a4),a0
	move.l	a0,(8,a0)
	addq.l	#4,a0
	clr.l	(a0)
	move.l	a0,-(a0)
	lea	(inputdevice.MSG,pc),a0
	moveq	#0,d0
	lea	($58,a4),a1
	moveq	#0,d1
	jsr	(_LVOOpenDevice,a6)
	tst.l	d0
	beq.b	lbC001988
	movea.l	a4,a1
	jsr	(_LVOFreeVec,a6)
	moveq	#0,d0
	bra.w	lbC001A10

lbC001988	move.l	#$4E20,d0
	cmpi.l	#$AEC85,($2C,a5)
	bne.b	lbC00199E
	sub.l	#$D06,d0
lbC00199E	movea.l	($6C,a4),a0
	move.l	($12A0,a0),d1
	mulu.w	#$3D09,d1
	lsl.l	#6,d1
	add.l	($12A4,a0),d1
	divu.w	d0,d1
	addq.w	#1,d1
	move.w	d1,($2C,a4)
	move.l	($12A8,a0),d1
	mulu.w	#$3D09,d1
	lsl.l	#6,d1
	add.l	($12AC,a0),d1
	divu.w	d0,d1
	addq.w	#1,d1
	move.w	d1,($28,a4)
	lea	($58,a4),a2
	lea	($358,a4),a3
	lea	($36,a4),a0
	move.l	a0,(14,a2)
	moveq	#15,d2
	bra.b	lbC0019F0

lbC0019E2	movea.l	a2,a0
	lea	($58,a4),a1
	moveq	#$2F,d1
lbC0019EA	move.b	(a1)+,(a0)+
	dbra	d1,lbC0019EA
lbC0019F0	move.l	a3,($28,a2)
	movea.l	a2,a1
	jsr	(_LVOReplyMsg,a6)
	lea	($30,a2),a2
	lea	($16,a3),a3
	dbra	d2,lbC0019E2
	movea.l	a4,a1
	moveq	#5,d0
	jsr	(_LVOAddIntServer,a6)
	move.l	a4,d0
lbC001A10	movem.l	(sp)+,d2/a2-a4
	rts

lbC001A16	movem.l	d2/a5/a6,-(sp)
	movea.l	a0,a5
	move.l	a0,d0
	beq.b	lbC001A62
	movea.l	($16,a5),a6
	movea.l	a5,a1
	moveq	#5,d0
	jsr	(_LVORemIntServer,a6)
	move.l	(ThisTask,a6),($46,a5)
	move.b	#4,($45,a5)
	move.b	#0,($44,a5)
	moveq	#15,d2
lbC001A40	lea	($36,a5),a0
	jsr	(_LVOWaitPort,a6)
	lea	($36,a5),a0
	jsr	(_LVOGetMsg,a6)
	dbra	d2,lbC001A40
	lea	($58,a5),a1
	jsr	(_LVOCloseDevice,a6)
	movea.l	a5,a1
	jsr	(_LVOFreeVec,a6)
lbC001A62	movem.l	(sp)+,d2/a5/a6
	rts

lbB001A68	db	$17
	db	$72
	db	$16
	db	$78
	db	$15
	db	$77
	db	$14
	db	$76
	db	$13
	db	$75
	db	$12
	db	$74
	db	$11
	db	$73
	db	$FF
lbB001A77	db	3
	db	$79
	db	2
	db	$7A
	db	1
	db	$7C
	db	0
	db	$7B
	db	$FF

;============================================================================

