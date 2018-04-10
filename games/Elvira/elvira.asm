;*---------------------------------------------------------------------------
;  :Program.	elvira.asm
;  :Contents.	Slave for "Elvira" from Accolade
;  :Author.	Wepl
;  :Original	v1
;  :Version.	$Id: elvira.asm 1.9 2018/04/10 00:23:29 wepl Exp wepl $
;  :History.	03.08.01 started
;		10.11.01 beta version for whdload-dev ;)
;		21.12.01 nearly complete
;		19.02.02 final
;		17.04.02 POINTERTICKS added
;		02.04.17 reassmebled because quitkey problem
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	OUTPUT	"wart:e/elvira/Elvira.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
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

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name	dc.b	"Elvira - Mistress of the Dark",0
slv_copy	dc.b	"1990 Accolade",0
slv_info	dc.b	"adapted by Wepl",10
		dc.b	"Version 1.2 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir	dc.b	"data",0
_runit		dc.b	"runit",0
_args		dc.b	"gameamiga",10
_args_end
		dc.b	0
	EVEN

;============================================================================

_bootdos

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
		cmp.w	#$e419,d0
		beq	.p
		lea	(_plen),a0
		cmp.w	#$feb9,d0
		beq	.p
		lea	(_plfr),a0
		cmp.w	#$3be1,d0
		beq	.p
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
		
	;patch
.p		move.l	d7,a1
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

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

.end		moveq	#0,d0
		rts


_plde	PL_START
	PL_S	$20b2,$c8-$b2	;disable DeleteFile
	;PL_W	$168b6,21780	;io buffer size
	;PL_R	$192ec		;check if hd installed
	;PL_I	$1984c		;largest chip mem
	;PL_I	$19882		;largest fast mem
	PL_PS	$19d08,_dbffix
	PL_W	$19d08+6,$1f4
	PL_PS	$19dba,_dbffix
	PL_W	$19dba+6,$5000
	PL_PS	$1cafc,_dbffix
	PL_W	$1cafc+6,$50
	PL_PS	$1cb12,_dbffix
	PL_W	$1cb12+6,$30
	PL_END

_plen	PL_START
	PL_S	$2122,$38-$22	;disable DeleteFile
	;PL_W	$16cea,21780	;io buffer size
	PL_PS	$1a10c,_dbffix
	PL_W	$1a10c+6,$1f4
	PL_PS	$1a1be,_dbffix
	PL_W	$1a1be+6,$5000
	PL_PS	$1cf00,_dbffix
	PL_W	$1cf00+6,$50
	PL_PS	$1cf16,_dbffix
	PL_W	$1cf16+6,$30
	PL_END

_plfr	PL_START
	PL_S	$2122,$38-$22	;disable DeleteFile
	;PL_W	$16cea,21780	;io buffer size
	PL_PS	$1a15e,_dbffix
	PL_W	$1a15e+6,$1f4
	PL_PS	$1a210,_dbffix
	PL_W	$1a210+6,$5000
	PL_PS	$1cf62,_dbffix
	PL_W	$1cf62+6,$50
	PL_PS	$1cf78,_dbffix
	PL_W	$1cf78+6,$30
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

	END
