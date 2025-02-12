;*---------------------------------------------------------------------------
;  :Program.	elvira.asm
;  :Contents.	Slave for "Elvira" from Accolade
;  :Author.	Wepl, Psygore
;  :Original	v1
;  :Version.	$Id: elvira.asm 1.10 2018/04/10 00:30:37 wepl Exp wepl $
;  :History.	03.08.01 started
;		10.11.01 beta version for whdload-dev ;)
;		21.12.01 nearly complete
;		19.02.02 final
;		17.04.02 POINTERTICKS added
;		02.04.17 reassmebled because quitkey problem
;		08.12.22 dma wait fixed
;			 audio volume patched
;			 quit slave when game exits added
;		15.12.22 supports ntsc screen
;		09.02.24 fix % umlauts in german translation
;		12.02.24 added patch for german texts in gameamiga
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
;	OUTPUT	"sd0:Elvira.Slave"
;	OUTPUT	"wart:e/elvira/Elvira.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= $80000	;size of fast memory
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
IOCACHE		= 22000		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
POINTERTICKS	= 1		;set mouse speed
;SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_name	dc.b	"Elvira - Mistress of the Dark",0
slv_copy	dc.b	"1990 Accolade",0
slv_info	dc.b	"adapted by Wepl, Psygore",10
		dc.b	"Version 1.4 "
		INCBIN	".date"
		dc.b	0
slv_CurrentDir	dc.b	"data",0
_runit		dc.b	"runit",0
_args		dc.b	"gameamiga",10
_args_end
		dc.b	0
	EVEN

;============================================================================

_bootdos

	;tags
		lea	(_tags_elvira,pc),a0
		move.l	(_resload,pc),a2
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
		bsr	_intro

	;load exe
		lea	(_runit),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;check version
		lea	(_runit),a0
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d1
		move.l	#300,d3
		sub.l	d3,a7
		move.l	a7,d2
		jsr	(_LVORead,a6)
		move.l	d3,d0
		move.l	a7,a0
		move.l	(_resload),a2
		jsr	(resload_CRC16,a2)
		add.l	d3,a7
		
		lea	(_plde),a0
		lea	(_plde_ntsc),a1
		cmp.w	#$e419,d0
		beq	.p
		lea	(_plen),a0
		lea	(_plen_ntsc),a1
		cmp.w	#$feb9,d0
		beq	.p
		lea	(_plfr),a0
		lea	(_plfr_ntsc),a1
		cmp.w	#$3be1,d0
		beq	.p
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
		
	;patch
.p
		move.l	(_modeid,pc),d0
		cmp.l	#NTSC_MONITOR_ID,d0
		bne	.PAL
		move.l	a1,a0
.PAL		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		move.l	(4,a7),d2		;D2 = stacksize
		sub.l	#5*4,d2			;required for MANX stack check
		movem.l	d2/d7/a2/a6,-(a7)
		jsr	(4,a1)
		movem.l	(a7)+,d2/d7/a2/a6
		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

;	;remove exe
;		move.l	d7,d1
;		jsr	(_LVOUnLoadSeg,a6)
;
.end		moveq	#0,d0
		rts

; $23=#=ä $24=$=ö $25=%=ü $2b=+=ß $99=Ö $9a=Ü

_plde_ntsc
	PL_START
	PL_W	$DA56,0		;remove X offset screen
	PL_PS	$1C8E0,_replay_music
	PL_NEXT	_plde

_plde	PL_START
	PL_PS	$87a,.printf
	PL_S	$20b2,$c8-$b2	;disable DeleteFile
;	PL_BKPT	$7142		;load gameamiga header
;	PL_BKPT	$79aa		;load gameamiga texts
	PL_P	$7a0c,_texts
	;PL_W	$168b6,21780	;io buffer size
	PL_B	$184a7,$25	;Überschreiben
	;PL_R	$192ec		;check if hd installed
	;PL_I	$1984c		;largest chip mem
	;PL_I	$19882		;largest fast mem
	PL_PS	$19d08,_dbffix
	PL_W	$19d08+6,$1f4
	PL_PS	$19dba,_dbffix
	PL_W	$19dba+6,300	;v1.3 was $5000
	PL_PS	$1cafc,_dbffix
	PL_W	$1cafc+6,300	;v1.3 was $50
	PL_PS	$1cb12,_dbffix
	PL_W	$1cb12+6,$30
	PL_B	$1CD8E+5,9	;v1.3 audio.vol byte fix
	PL_END

; % is used as 'ü' which breaks printf formatting
; we disable formatting except % is followed by l/s

.printf		cmp.b	#"l",(a2)		;%ld
		beq	.do
		cmp.b	#"s",(a2)		;%s
		bne	.skip
		cmp.b	#"e",(1,a2)		;%se
		beq	.skip
		cmp.b	#"s",(1,a2)		;%ss
		beq	.skip
		cmp.b	#"t",(1,a2)		;%st
		bne	.do
.skip		add.l	#$894-$87a-6,(a7)
		rts

.do		move.l	(a7)+,d0
		move.l	a3,-(a7)		;original
		pea	(-10,a5)		;original
		move.l	d0,-(a7)
		rts

_texts		movem.l	d1/a0-a2,-(a7)
		lea	.pl,a0
		move.l	(-4,a5),a1
		sub	#$14,a1			;offset in file
		move.l	(_resload),a2
		jsr	(resload_Patch,a2)
		movem.l	(a7)+,_MOVEMREGS
		movem.l	(-$10,a5),d7/a3		;original
		unlk	a5			;original
		rts				;original

.pl	PL_START
	PL_STR	$15e,< >				;- 20
	PL_STR	$17f,<Igitt! Schon irgendwie eklig.>	;Ups ! Mu+test Du so grob sein
	PL_STR	$fd2,<villeicht ein kleiner Hinweis>	;Scher Dich hier raus Bastard
	PL_STR	$12af,< >			;- 20
	PL_STR	$17ad,<Spanner>			;Bastard
	PL_STR	$18b6,<Gartensieb>		;ein R#tsel
	PL_STR	$1931,<o+enflasche >		;aucenflasche
	PL_STR	$1b73,<E>			;e 45
	PL_STR	$1dc2,<leines St%ck Z%ndschnur>	;urzes St%ck wei+ses Band
	PL_STR	$1e42,<Bild von  >		;(Oe)lbild von
	PL_STR	$20da,<%>			;(Ue)
	PL_STR	$2653,<E>			;e
	PL_STR	$27c6,<r EX Vampirin>		; Ex-Vampirin
	PL_STR	$29d9,<S>			;s
	PL_STR	$2b42,<STUNG>			;stung
	PL_STR	$30cf,<Mein Held, daf%r werde ich dich ganz besonders verw$hnen>
		      ;Ohh, mein Held! Wer ist denn nun der gro+e, starke Junge
	PL_STR	$31bb,<Buttergolem losgeworden > ;Schmalzeimer los geworden
	PL_STR	$33f6,< abgekn$pft>		;abgekn$pft.
	PL_STR	$3727,< ..deine Hose PLATZT gleich.      >
		      ;Elvira wirft Dir den Schl%ssel zu.
	PL_STR	$389b,<S>			;s
	PL_STR	$3b9f,<S>			;s
	PL_STR	$3d3c,<z mit >			;sz mit
	PL_STR	$3e98,<!!>			; -
	PL_STR	$40e3,<C>			;c
	PL_STR	$4390,<                           Also, ich kriech auf allen vieren herum, w#hrend du hier (.)(.)>
		      ;Ich kriech' hier auf allen Vieren rum, w#hrnd Du dastehst und dumm aus der W#sche guckst."
	PL_STR	$4539,<u darfst dich sp#ter daf%r ausgiebig bei mir bedanken!>
		      ;a, sieh hin, ich bin so schlau wie ich verfressen bin.
	PL_STR	$4581,<%>			;(Ue)
	PL_STR	$48c3,< >			;- 20
	PL_STR	$5096,< >			;- 20
	PL_END

_plen_ntsc
	PL_START
	PL_W	$DE8A,0		;remove X offset screen
	PL_PS	$1CCE4,_replay_music
	PL_NEXT	_plen

_plen	PL_START
	PL_S	$2122,$38-$22	;disable DeleteFile
	;PL_W	$16cea,21780	;io buffer size
	PL_PS	$1a10c,_dbffix
	PL_W	$1a10c+6,$1f4
	PL_PS	$1a1be,_dbffix
	PL_W	$1a1be+6,300	;v1.3 was $5000
	PL_PS	$1cf00,_dbffix
	PL_W	$1cf00+6,300	;v1.3 was $50
	PL_PS	$1cf16,_dbffix
	PL_W	$1cf16+6,$30
	PL_B	$1D192+5,9	;v1.3 audio.vol byte fix
	PL_END

_plfr_ntsc
	PL_START
	PL_W	$DE8A,0		;remove X offset screen
	PL_PS	$1CD46,_replay_music
	PL_NEXT	_plfr

_plfr	PL_START
	PL_S	$2122,$38-$22	;disable DeleteFile
	;PL_W	$16cea,21780	;io buffer size
	PL_PS	$1a15e,_dbffix
	PL_W	$1a15e+6,$1f4
	PL_PS	$1a210,_dbffix
	PL_W	$1a210+6,300	;v1.3 was $5000
	PL_PS	$1cf62,_dbffix	;soundtrack dma wait
	PL_W	$1cf62+6,300	;v1.3 was $50
	PL_PS	$1cf78,_dbffix	;soundtrack dma wait
	PL_W	$1cf78+6,$30
	PL_B	$1D1F4+5,9	;v1.3 audio.vol byte fix
	PL_END

_dbffix		movem.l	d0-d1/a0,-(a7)
		move.l	(12,a7),a0
		moveq	#0,d0
		move.w	(a0)+,d0
		divu	#34,d0
.1		move.b	$dff006,d1
.2		cmp.b	$dff006,d1
		beq	.2
		dbf	d0,.1
		movem.l	(a7)+,d0-d1/a0
		addq.l	#2,(a7)
		rts

;----------------------------------------------
; skip 1 frame every 5 frames to slowdown music in ntsc screen

_replay_music	move.l	(sp)+,d0		;return address
		addq.l	#2,d0			;skip lea (,pc),a0 (not used)
		movem.l	d0-d4/a0-a3/a5/a6,-(sp)	;ori
		move.l	d0,-(sp)
		lea	(.1,pc),a0
		addq.b	#1,(a0)
		cmp.b	#5+1,(a0)
		bne	.ok
		clr.b	(a0)
		addq.l	#6,(sp)			;skip addq.b #1, for mt_speed
.ok		rts

.1		dc.b	0,0

;============================================================================

_intro		lea	_custom,a5		;A5 = custom

		jsr	(_LVOOutput,a6)
		move.l	d0,d7			;D7 = output
		
		lea	(.text),a2
		
.loop		move.l	d7,d1
		move.l	a2,d2
		moveq	#1,d3
		jsr	(_LVOWrite,a6)
		
		cmp.b	#10,(a2)
		beq	.next
		cmp.b	#" ",(a2)
		beq	.next
		cmp.b	#"	",(a2)
		beq	.next
		
		bsr	.wait
		bne	.end
		
.next		addq.l	#1,a2
		tst.b	(a2)
		bne	.loop
		
.rmb		bsr	.wait
		beq	.rmb
		
.end		move.l	d7,d1
		lea	(.lf),a2
		move.l	a2,d2
		moveq	#1,d3
		jsr	(_LVOWrite,a6)

		rts

.wait		moveq	#3,d0
.w1		btst	#POTGOB_DATLY-8,(potinp,a5)
		beq	.w3
		btst	#0,(vposr+1,a5)
		beq	.w1
.w2		btst	#POTGOB_DATLY-8,(potinp,a5)
		beq	.w3
		btst	#0,(vposr+1,a5)
		bne	.w2
		dbf	d0,.w1
		moveq	#0,d0
		rts

.w3		btst	#POTGOB_DATLY-8,(potinp,a5)
		beq	.w3
		moveq	#-1,d0
		rts

.text		dc.b	10
		dc.b	10
		dc.b	10
		dc.b   "		 Elvira - Mistress of the Dark",10
		dc.b	10
		dc.b   "		   Install by Wepl 2001-2002",10
		dc.b   "      Kickstart 1.3 emulation interface by Wepl 1999-2002",10
		dc.b	10
		dc.b   "		 Greetings to all my friends!",10
		dc.b	10
		dc.b   "		  Press RMB to start Elvira...",10
.lf		dc.b	10
		dc.b	0
	EVEN

;============================================================================

_tags_elvira	dc.l	WHDLTAG_MONITOR_GET
_modeid		dc.l	0
		dc.l	TAG_DONE

	END
