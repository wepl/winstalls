;*---------------------------------------------------------------------------
;  :Modul.	kick12.s
;  :Contents.	interface code and patches for kickstart 1.2
;  :Author.	Wepl, JOTD
;  :Version.	$Id: kick12.s 1.3 2002/05/09 14:18:45 wepl Exp wepl $
;  :History.	17.04.02 created from kick13.s and kick12.s from JOTD
;		18.11.02 illegal trackdisk-patches enabled if DEBUG
;		30.11.02 FONTHEIGHT added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	lvo/exec.i
	INCLUDE	lvo/graphics.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	exec/memory.i
	INCLUDE	graphics/gfxbase.i

;============================================================================

_boot		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

	;relocate some addresses
		lea	(_cbswitch,pc),a0
		lea	(_cbswitch_tag,pc),a1
		move.l	a0,(a1)

	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a5)

	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#$e9c6,d1			;crc16
		lea	(_kick,pc),a0			;name
		jsr	(resload_LoadKick,a5)

	;patch the kickstart
		lea	(kick_patch,pc),a0
		move.l	(_expmem,pc),a1
		jsr	(resload_Patch,a5)

	;call
kick_reboot	move.l	(_expmem,pc),a0
		jmp	(2,a0)				;original entry

kick_patch	PL_START
		PL_S	$d2,$fe-$d2
		PL_CW	$132				;color00 $444 -> $000
		PL_P	$61a,kick_detectfast
		PL_P	$592,kick_detectchip
		PL_CW	$25a				;color00 $888 -> $000
	IFD HRTMON
		PL_PS	$286,kick_hrtmon
	ENDC
		PL_L	$106,$02390002			;skip LED power off (and.b #~CIAF_LED,$bfe001)
		PL_S	$50C,$514-$50C			;skip LED power on
		PL_P	$546,kick_detectcpu
		PL_P	$5f0,kick_reboot		;reboot (reset)
		PL_P	$1318,exec_snoop1
		PL_PS	$1576,exec_MakeFunctions
		PL_PS	$147a,exec_SetFunction
		PL_PS	$422,exec_flush
	IFD MEMFREE
		PL_P	$17ea,exec_AllocMem
	ENDC
		PL_L	$4f4,-1				;disable search for residents at $f00000
		PL_S	$4c66,4				;skip autoconfiguration at $e80000
		PL_PS	$6d04,gfx_vbserver
		PL_PS	$6d1a,gfx_snoop1
		PL_PS	$ad9e,gfx_setcoplc
		PL_S	$adc2,6				;avoid ChkBltWait problem
		PL_S	$af16,$36-$16			;skip color stuff & strange gb_LOFlist set
		PL_P	$afe4,gfx_detectgenlock
		PL_P	$b058,gfx_detectdisplay
		PL_PS	$d5cc,gfx_fix1			;gfx_LoadView
	IFD _bootearly
		PL_P	$2897a,_bootearly
	ENDC
	IFD _bootblock
		PL_PS	$28a2c,_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$29308,timer_init
		PL_P	$2a734,trd_readwrite
		PL_P	$2a462,trd_motor
		PL_P	$2a07a,trd_format
		PL_PS	$2aa56,trd_protstatus
		PL_P	$2998c,trd_task
	IFD DEBUG
		PL_L	$29fd4,-1			;disable asynchron io
		PL_I	$2a51c				;empty dbf-loop in trackdisk.device
	;	PL_I	$?????				;internal readwrite
		PL_I	$2aa14				;trd_seek
		PL_I	$2b2e8				;trd_rawread
		PL_I	$2b2ee				;trd_rawwrite
	ENDC
		PL_P	$491c,disk_getunitid
	IFD BLACKSCREEN
		PL_C	$1bcd6,6			;color17,18,19
		PL_C	$1bcde,8			;color0,1,2,3
	ENDC
	IFD FONTHEIGHT
		PL_B	$1bc70,FONTHEIGHT
	ENDC
	IFD POINTERTICKS
		PL_W	$1bcdc,POINTERTICKS
	ENDC
	IFD HDINIT
		PL_PS	$288e8,hd_init			;enter while starting strap
	ENDC
	IFND _bootearly
	IFND _bootblock
		PL_PS	$342ec,dos_init
		PL_PS	$3c9b2,dos_1
		PL_PS	$3717c,dos_LoadSeg
	ENDC
	ENDC
	IFD  _bootdos
		PL_PS	$38a4a,dos_bootdos
	ENDC
	;the following stuff is from SetPatch 1.38
	IFD SETPATCH
		PL_PS	$57c0,gfx_MrgCop
		PL_PS	$7f26,gfx_SetFont
		PL_P	$7f66,gfx_SetSoftStyle
		PL_P	$191e,exec_AllocEntry
		PL_P	$1174,exec_UserState
		PL_P	$165a,exec_FindName
	ENDC
		PL_END

;============================================================================

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem,pc),a4
		add.l	#KICKSIZE,a4
		move.l	a4,($1f0-$1ea,a5)
		move.l	a4,($1fc-$1ea,a5)
		add.l	#FASTMEMSIZE,a4
		bsr	_flushcache
	ENDC
		jmp	(a5)

kick_detectchip	move.l	#CHIPMEMSIZE,a3
		jmp	(a5)

	IFD HRTMON
kick_hrtmon	move.l	a4,d0
		bne	.1
		move.l	a3,d0
.1		sub.l	#8,d0			;hrt reads too many from stack -> avoid af
		rts
	ENDC

kick_detectcpu	move.l	(_attnflags,pc),d0
	IFND NEEDFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

	;move.w (a7)+,($dff09c) does not work with Snoop/S on 68060
exec_snoop1	move.w	(a7),($dff09c)
		addq.l	#2,a7
		rts

exec_MakeFunctions
		subq.l	#8,a7
		move.l	(8,a7),(a7)
		move.l	a3,(4,a7)		;original
		lea	(_flushcache,pc),a3
		move.l	a3,(8,a7)
		moveq	#0,d0			;original
		move.l	a2,d1			;original
		rts

exec_SetFunction
		move.l	(a7)+,d1
		pea	(_flushcache,pc)
		move.l	d1,-(a7)
		bset	#1,(14,a1)		;original
		rts

exec_flush	lea	(_custom),a0		;original
		bra	_flushcache

	IFD MEMFREE
exec_AllocMem	movem.l	d0-d1/a0-a1,-(a7)
		move.l	#MEMF_LARGEST|MEMF_CHIP,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE),d1
		beq	.3
		cmp.l	d1,d0
		bhi	.1
.3		move.l	d0,(MEMFREE)
.1		move.l	#MEMF_LARGEST|MEMF_FAST,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE+4),d1
		beq	.4
		cmp.l	d1,d0
		bhi	.2
.4		move.l	d0,(MEMFREE+4)
.2		movem.l	(a7)+,d0-d1/a0-a1
		movem.l	(a7)+,d2-d3/a2
		rts
	ENDC

	IFD SETPATCH

exec_AllocEntry	movem.l	d2/d3/a2-a4,-(sp)
		movea.l	a0,a2
		moveq	#0,d3
		move.w	(14,a2),d3
		move.l	d3,d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		move.l	#$10000,d1
		jsr	(-$C6,a6)
		movea.l	d0,a3
		movea.l	d0,a4
		tst.l	d0
		beq.b	.BD0
		move.w	d3,(14,a3)
		lea	($10,a2),a2
		lea	($10,a3),a3
		moveq	#0,d2
.B78		move.l	(0,a2),d1
		move.l	(4,a2),d0
		move.l	d0,(4,a3)
		beq.b	.B8E
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq.b	.BA4
.B8E		move.l	d0,(0,a3)
		addq.l	#8,a2
		addq.l	#8,a3
		addq.w	#1,d2
		subq.l	#1,d3
		bne.b	.B78
		move.l	a4,d0
.B9E		movem.l	(sp)+,d2/d3/a2-a4
		rts

.BA4		subq.w	#1,d2
		bmi.b	.BB8
		subq.l	#8,a3
		movea.l	(0,a3),a1
		move.l	(4,a3),d0
		jsr	(_LVOFreeMem,a6)
		bra.b	.BA4

.BB8		moveq	#0,d0
		move.w	(14,a4),d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		movea.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		move.l	(0,a2),d0
.BD0		bset	#$1F,d0
		bra.b	.B9E

exec_UserState	move.l	(sp)+,d1
		move.l	sp,usp
		movea.l	d0,sp
		movea.l	a5,a0
		lea	(.B18,pc),a5
		jmp	(_LVOSupervisor,a6)

.B18		movea.l	a0,a5
		move.l	d1,(2,sp)
		andi.w	#$DFFF,(sp)
		rte

exec_FindName	move.l	a2,-(sp)
		movea.l	a0,a2
		move.l	a1,d1
		move.l	(a2),d0
		beq.b	.FDC
.FBE		movea.l	d0,a2
		move.l	(a2),d0
		beq.b	.FDC
		tst.l	(10,a2)
		beq.b	.FBE
		movea.l	(10,a2),a0
		movea.l	d1,a1
.FD0		cmpm.b	(a0)+,(a1)+
		bne.b	.FBE
		tst.b	(-1,a0)
		bne.b	.FD0
		move.l	a2,d0
.FDC		movea.l	d1,a1
		movea.l	(sp)+,a2
		rts

	ENDC

;============================================================================

gfx_vbserver	lea	(_cbswitch_cop2lc,pc),a6
		move.l	d0,(a6)
		lea	($bfd000),a6		;original
		rts

_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		jmp	(a0)

	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

gfx_detectgenlock
		moveq	#0,d0
		rts

gfx_detectdisplay
		moveq	#4,d0			;pal
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.1
		moveq	#1,d0			;ntsc
.1		rts

gfx_setcoplc	moveq	#-2,d0
		move.l	d0,(a3)+
		move.l	a3,(cop2lc,a4)		;original
		move.l	a3,(gb_LOFlist,a2)
		move.l	a3,(gb_SHFlist,a2)
		move.l	d0,(a3)+
		clr.w	(color+2,a4)
		add.l	#$adb6-$ad9e-6,(a7)
		rts

	;somewhere there will used a empty view, too stupid
gfx_fix1	move.l	(v_LOFCprList,a0),d0
		beq	.s1
		move.l	d0,a1
		move.l	(4,a1),(gb_LOFlist,a2)
.s1		move.l	(v_SHFCprList,a0),d0
		beq	.s2
		move.l	d0,a1
		move.l	(4,a1),(gb_SHFlist,a2)
.s2		add.l	#$d5e0-$d5cc-6,(a7)
		rts

	IFD SETPATCH

gfx_MrgCop	move.w	($10,a1),d0
		move.w	($9E,a6),d1
		eor.w	d1,d0
		andi.w	#4,d0
		beq.b	.F58
		and.w	($10,a1),d0
		beq.b	.F58
		movem.l	a2/a3,-(sp)
		movea.l	a1,a2
		movea.l	a1,a3
.F2E		move.l	(a3),d0
		beq.b	.F52
		movea.l	d0,a3
		move.w	($20,a3),d0
		move.w	#$2000,d1
		and.w	d0,d1
		beq.b	.F2E
		move.w	#4,d1
		and.w	d0,d1
		beq.b	.F2E
		movea.l	a2,a0
		movea.l	a3,a1
		jsr	(_LVOMakeVPort,a6)
		bra.b	.F2E
.F52		movea.l	a2,a1
		movem.l	(sp)+,a2/a3
.F58
		move.l	a1,-(a7)		;original
		pea	(.ret,pc)
		move.l	(8,a7),-(a7)
		add.l	#-6-$57c0+$a586,(a7)
		rts

.ret		addq.l	#8,a7
		rts

gfx_SetFont	move.l	a0,d0
		beq.b	.FAC
		move.l	a1,d0
		beq.b	.FAC
		move.w	($14,a0),($3a,a1)	;original
		rts

.FAC		addq.l	#4,a7
		rts

gfx_SetSoftStyle
		move.l	d2,-(sp)
		moveq	#0,d2
		movem.l	d0/d1/a0/a1,-(sp)
		jsr	(_LVOAskSoftStyle,a6)
		move.b	d0,d2
		movem.l	(sp)+,d0/d1/a0/a1
		movea.l	($34,a1),a0
		and.b	d2,d1
		move.b	($38,a1),d2
		and.b	d1,d0
		not.b	d1
		and.b	d1,d2
		or.b	d0,d2
		move.b	d2,($38,a1)
		or.b	($16,a0),d2
		move.l	d2,d0
		move.l	(sp)+,d2
		rts

	ENDC

;============================================================================

disk_getunitid
	IFNE NUMDRIVES-4
		lea	(12,a3),a3
	IFEQ NUMDRIVES
		clr.l	-(a7)
		subq.l	#4,a7
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		move.l	(_resload,pc),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7),d0
		addq.l	#8,a7
		neg.l	d0
		addq.l	#3,d0
		bmi	.q
		cmp.w	#3,d0
		blo	.ok
		moveq	#2,d0
.ok
	ELSE
		moveq	#3-NUMDRIVES,d0
	ENDC
		moveq	#-1,d1
.0		move.l	d1,-(a3)
		dbf	d0,.0
	ENDC
.q		rts

;============================================================================

timer_init	move.l	(_time,pc),a0
		move.l	(whdlt_days,a0),d0
		mulu	#24*60,d0
		add.l	(whdlt_mins,a0),d0
		move.l	d0,d1
		lsl.l	#6,d0			;*64
		lsl.l	#2,d1			;*4
		sub.l	d1,d0			;=*60
		move.l	(whdlt_ticks,a0),d1
		divu	#50,d1
		ext.l	d1
		add.l	d1,d0
		move.l	d0,($c6,a2)
		movem.l	(a7)+,d2/a2-a3		;original
		rts

;============================================================================

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)

		moveq	#0,d1
		move.b	($43,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)

		btst	#1,($40,a3)		;disk inserted?
		beq	.diskok

		move.b	#TDERR_DiskChanged,(IO_ERROR,a1)

.end		movem.l	(a7),d2/a1-a2
		bsr	trd_endio
		movem.l	(a7)+,d2/a1-a2
		moveq	#0,d0
		move.b	(IO_ERROR,a1),d0
		rts

.diskok		cmp.b	#CMD_READ,(IO_COMMAND+1,a1)
		bne	.write

.read		moveq	#0,d2
		move.b	(_trd_disk,pc,d1.w),d2	;disk
		move.l	(IO_OFFSET,a1),d0	;offset
		move.l	(IO_LENGTH,a1),d1	;length
		move.l	(IO_DATA,a1),a0		;destination
		move.l	(_resload,pc),a1
		jsr	(resload_DiskLoad,a1)
		bra	.end

.write		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		bne	.protok
		move.b	#TDERR_WriteProt,(IO_ERROR,a1)
		bra	.end

.protok		lea	(.disk,pc),a0
		move.b	(_trd_disk,pc,d1.w),d0	;disk
		add.b	#"0",d0
		move.b	d0,(5,a0)		;name
		move.l	(IO_LENGTH,a1),d0	;length
		move.l	(IO_OFFSET,a1),d1	;offset
		move.l	(IO_DATA,a1),a1		;destination
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
		bra	.end

.disk		dc.b	"Disk.",0,0,0

_trd_disk	dc.b	1,2,3,4			;number of diskimage in drive
_trd_prot	dc.b	WPDRIVES		;protection status
_trd_chg	dc.b	0			;diskchanged

trd_motor	moveq	#0,d0
		bchg	#7,($41,a3)		;motor status
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	($43,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$a88-$a56-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$2a1b0,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$29a68,(a7)
		rts

trd_task
	IFD DISKSONBOOT
		bclr	#1,($40,a3)		;set disk inserted
		beq	.1
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.1
	ENDC
		move.b	($43,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,($40,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,($40,a3)		;set disk inserted
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause

.2		rts

	IFD TRDCHANGEDISK
	;d0.b = unit
	;d1.b = new disk image number
_trd_changedisk	movem.l	a6,-(a7)

		and.w	#3,d0
		lea	(_trd_chg,pc),a0

		move.l	(4),a6
		jsr	(_LVODisable,a6)

		move.b	d1,(-5,a0,d0.w)
		bset	d0,(a0)

		jsr	(_LVOEnable,a6)

		movem.l	(a7)+,a6
		rts
	ENDC

;============================================================================

	IFND _bootearly
	IFND _bootblock

dos_init	move.l	#$10001,d1
		bra	_flushcache

dos_1		move.l	#$118,d1		;original
		bra	_flushcache

dos_LoadSeg	clr.l	(12,a1)			;original
		moveq	#12,d4			;original
		lea	(.savea4,pc),a6
		move.l	a4,(a6)
		lea	(.bcplend,pc),a6
		rts

.savea4		dc.l	0

.bcplend	cmp.l	(.savea4,pc),a4		;are we in dos_51?
		beq	.end51
		jmp	($344a8-$344b4,a5)	;call original

.end51		lea	($344a8-$344b4,a5),a6	;restore original
	IFD _cb_dosLoadSeg
		movem.l	d0-a6,-(a7)
		move.l	(a1),d0			;d0 = BSTR FileName
		tst.l	d1			;d1 = BPTR SegList
		beq	.failed
		bsr	_cb_dosLoadSeg
.failed		movem.l	(a7)+,d0-a6
	ENDC
		bsr	_flushcache
		jmp	(a6)

	ENDC
	ENDC

	IFD  _bootdos
dos_bootdos

	;init boot exe
		lea	(_bootdos,pc),a3
		move.l	a3,(bootfile_exe_j+2-_bootdos,a3)

	;fake startup-sequence
		lea	(bootname_ss_b,pc),a3	;bstr
		move.l	a3,d1

	;return
		rts

	CNOP 0,4
bootname_ss_b	dc.b	10
bootname_ss	dc.b	"WHDBoot.ss",0
bootfile_ss	dc.b	"WHDBoot.exe",10
bootfile_ss_e
bootname_exe	dc.b	"WHDBoot.exe",0
	EVEN
bootfile_exe	dc.l	$3f3,0,1,0,0,2,$3e9,2
bootfile_exe_j	jmp	$99999999
		dc.w	0
		dc.l	$3f2
bootfile_exe_e
	ENDC

;---------------
; performs a C:Assign
; IN:	A0 = BSTR destination name (null terminated BCPL string, at long word address!)
;	A1 = CPTR directory (could be 0 meaning SYS:)
; OUT:	-

	IFD	DOSASSIGN
_dos_assign	movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory

	;get memory for node
		move.l	#DosList_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		move.l	d0,a5			;A5 = DosList

	;open doslib
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6

	;lock directory
		move.l	a4,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
	IFD DEBUG
		beq	_debug3
	ENDC
		lsl.l	#2,d1
		move.l	d1,a0
		move.l	(fl_Task,a0),(dol_Task,a5)
		move.l	d0,(dol_Lock,a5)

	;init structure
		move.l	#DLT_DIRECTORY,(dol_Type,a5)
		move.l	a3,d0
		lsr.l	#2,d0
		move.l	d0,(dol_Name,a5)

	;add to the system
		move.l	(dl_Root,a6),a6
		move.l	(rn_Info,a6),a6
		add.l	a6,a6
		add.l	a6,a6
		move.l	(di_DevInfo,a6),(dol_Next,a5)
		move.l	a5,d0
		lsr.l	#2,d0
		move.l	d0,(di_DevInfo,a6)

		movem.l	(a7)+,d2/a3-a6
		rts
	ENDC

;============================================================================

	IFD HDINIT

hd_init		sub.l	#$7e,a5				;original

	INCLUDE	Sources:whdload/kickfs.s
	
	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

_waitvb
.1		btst	#0,(_custom+vposr+1)
		beq	.1
.2		btst	#0,(_custom+vposr+1)
		bne	.2
		rts

;============================================================================

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d2) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
_debug4		tst	-4	;wrong mode while read
_debug5		tst	-5	;wrong mode while write
		illegal		;security if executed without mmu
	ENDC

;============================================================================

_kick		dc.b	"33192.a500",0
	EVEN
_tags		dc.l	WHDLTAG_CBSWITCH_SET
_cbswitch_tag	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0

;============================================================================

	END
