;*---------------------------------------------------------------------------
;  :Modul.	kick13.s
;  :Contents.	interface code and patches for kickstart 1.3
;  :Author.	Wepl
;  :Version.	$Id: kick13.s 0.20 2001/11/28 22:57:42 wepl Exp wepl $
;  :History.	19.10.99 started
;		18.01.00 trd_write with writeprotected fixed
;			 diskchange fixed
;		24.01.00 reworked to assemble with Asm-Pro
;		20.02.00 problems with Snoop/S on 68060 fixed
;		21.02.00 cbswitch added (cop2lc)
;		22.02.00 free memory count added
;		01.03.00 wait in _trd_changedisk removed because deadlocks
;		09.03.00 adapted for whdload v11
;		17.03.00 most stuff from SetPatch 1.38 added
;		20.03.00 some fixes for 68060 and snoop
;		16.04.00 loadview fixed
;		11.05.00 SetPatch can be enabled/disabled via a defined label
;		19.06.01 ChkBltWait problem fixed in blitter init
;		15.07.01 using time provided by whdload to init timer.device
;		02.08.01 exec.Supervisor fixed (to work with exec.SuperState)
;		03.08.01 NOFPU->NEEDFPU changed, DISKSONBOOT added
;			 bug in trackdisk fixed (endio missing on error)
;		04.08.01 flushcache and callback for dos.LoadSeg added
;		05.08.01 hd supported started
;		01.09.01 trap #15 to trap #14 changed in _Supervisor (debug rnc)
;			 BLACKSCREEN added
;		08.11.01 Supervisor patch removed, slaves now require 
;			 WHDLF_EmulPriv to be set
;		27.11.01 fs enhanced
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	.buildname: support for relative paths
;		more dos packets (maybe)
;---------------------------------------------------------------------------*

	INCLUDE	lvo/exec.i
	INCLUDE	lvo/expansion.i
	INCLUDE	lvo/graphics.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	dos/dosextens.i
	INCLUDE	dos/filehandler.i
	INCLUDE	exec/memory.i
	INCLUDE	exec/resident.i
	INCLUDE	graphics/gfxbase.i
	INCLUDE	libraries/configvars.i
	INCLUDE	libraries/expansionbase.i

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
		move.w	#$f9e3,d1			;crc16
		lea	(_kick,pc),a0			;name
		jsr	(resload_LoadKick,a5)
		
	;patch the kickstart
		lea	(kick_patch,pc),a0
		move.l	(_expmem,pc),a1
		jsr	(resload_Patch,a5)

	;call
		move.l	(_expmem,pc),a0
	;	jmp	(2,a0)				;original entry
		jmp	($fe,a0)			;this entry saves some patches

kick_patch	PL_START
		PL_CW	$132				;color00 $444 -> $000
		PL_P	$61a,kick_detectfast
		PL_P	$592,kick_detectchip
		PL_CW	$25a				;color00 $888 -> $000
	IFD HRTMON
		PL_PS	$286,kick_hrtmon
	ENDC
		PL_P	$546,kick_detectcpu
		PL_P	$1354,exec_snoop1
		PL_PS	$15b2,exec_MakeFunctions
		PL_PS	$14b6,exec_SetFunction
		PL_PS	$422,exec_flush
	IFD MEMFREE
		PL_P	$1826,exec_AllocMem
	ENDC
		PL_L	$4f4,-1				;disable search for residents at $f00000
		PL_S	$4cce,4				;skip autoconfiguration at $e80000
		PL_PS	$6d70,gfx_vbserver
		PL_PS	$6d86,gfx_snoop1
		PL_PS	$ad5e,gfx_setcoplc
		PL_S	$ad7a,6				;avoid ChkBltWait problem
		PL_S	$aecc,$e4-$cc			;skip color stuff & strange gb_LOFlist set
		PL_P	$af96,gfx_detectgenlock
		PL_P	$b00c,gfx_detectdisplay
		PL_PS	$d5be,gfx_fix1			;gfx_LoadView
	IFD _bootearly
		PL_P	$284ee,_bootearly
	ENDC
	IFD _bootblock
		PL_PS	$285c6,_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$28f88,timer_init
		PL_P	$2a3b4,trd_readwrite
	;	PL_I	$2a5d8				;internal readwrite
		PL_P	$2a0e2,trd_motor
	;	PL_I	$2a694				;trd_seek
		PL_P	$29cfa,trd_format
		PL_PS	$2a6d6,trd_protstatus
	;	PL_I	$2af68				;trd_rawread
	;	PL_I	$2af6e				;trd_rawwrite
	;	PL_I	$2a19c				;empty dbf-loop in trackdisk.device
		PL_P	$2960c,trd_task
	;	PL_L	$29c54,-1			;disable asynchron io
		PL_P	$4984,disk_getunitid
	IFD BLACKSCREEN
		PL_C	$1b9d2,6			;color17,18,19
		PL_C	$1b9da,8			;color0,1,2,3
	ENDC
	IFD HDINIT
		PL_PS	$28452,hd_init			;enter while starting strap
	ENDC
	IFND _bootearly
	IFND _bootblock
		PL_PS	$33ef0,dos_init
		PL_PS	$3c9b6,dos_1
		PL_PS	$36e4c,dos_LoadSeg
	ENDC
	ENDC
	;the following stuff is from SetPatch 1.38
	IFD SETPATCH
		PL_PS	$582c,gfx_MrgCop
		PL_PS	$7f66,gfx_SetFont
		PL_P	$7fa6,gfx_SetSoftStyle
		PL_P	$195a,exec_AllocEntry
		PL_P	$11b0,exec_UserState
		PL_P	$1696,exec_FindName
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
		add.l	#$ad72-$ad5e-6,(a7)
		rts

	;somewhere there will used a empty view, too stupid
gfx_fix1	move.l	(v_LOFCprList,a1),d0
		beq	.s1
		move.l	d0,a0
		move.l	(4,a0),(gb_LOFlist,a3)
.s1		move.l	(v_SHFCprList,a1),d0
		beq	.s2
		move.l	d0,a0
		move.l	(4,a0),(gb_SHFlist,a3)
.s2		add.l	#$d5d2-$d5be-6,(a7)
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
		add.l	#-6-$582c+$a5b4,(a7)
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

timer_init	move.l	(_time),a0
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
		add.l	#$708-$6d6-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$29e30,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$296e8,(a7)
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
		jmp	($34128-$34134,a5)	;call original

.end51		lea	($34128-$34134,a5),a6	;restore original
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

;============================================================================
;
; BootNode
; 08 LN_TYPE = NT_BOOTNODE
; 0a LN_NAME -> ConfigDev
;		10 cd_Rom+er_Type = ERTF_DIAGVALID
;		1c cd_Rom+er_Reserved0c -> DiagArea
;					   00 da_Config = DAC_CONFIGTIME
;					   06 da_BootPoint -> .bootcode
;					   0e da_SIZEOF
;		44 cd_SIZEOF
; 10 bn_DeviceNode -> DeviceNode (exp.MakeDosNode)
*		      04 dn_Type = 2
;		      24 dn_SegList -> .seglist
;		      2c dn_SIZEOF
; 14 bn_SIZEOF

	IFD HDINIT

hd_init		lea	-1,a2				;original
		movem.l	d0-a6,-(a7)

		moveq	#ConfigDev_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a5				;A5 = ConfigDev
		bset	#ERTB_DIAGVALID,(cd_Rom+er_Type,a5)
		lea	(.diagarea,pc),a0
		move.l	a0,(cd_Rom+er_Reserved0c,a5)

		lea	(.expansionname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a4				;A4 = expansionbase
		
		lea	(.parameterPkt+8,pc),a0
		lea	(.devicename,pc),a1
		move.l	a1,-(a0)
		lea	(.handlername,pc),a1
		move.l	a1,-(a0)
		move.l	a4,a6
		jsr	(_LVOMakeDosNode,a6)
		move.l	d0,a3				;A3 = DeviceNode
		lea	(.seglist,pc),a1
		move.l	a1,d1
		lsr.l	#2,d1
		move.l	d1,(dn_SegList,a3)
		move.l	#-1,(dn_GlobalVec,a3)		;no BCPL shit

		moveq	#BootNode_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
		jsr	(_LVOAllocMem,a6)
		move.l	d0,a1				;BootNode
		move.b	#NT_BOOTNODE,(LN_TYPE,a1)
		move.l	a5,(LN_NAME,a1)			;ConfigDev
		move.l	a3,(bn_DeviceNode,a1)

		lea	(eb_MountList,a4),a0
		jsr	(_LVOEnqueue,a6)

		movem.l	(a7)+,d0-a6
		rts

.diagarea	dc.b	DAC_CONFIGTIME		;da_Config
		dc.b	0			;da_Flags
		dc.w	0			;da_Size
		dc.w	0			;da_DiagPoint
		dc.w	.bootcode-.diagarea	;da_BootPoint
		dc.w	0			;da_Name
		dc.w	0			;da_Reserved01
		dc.w	0			;da_Reserved02

HD_Cyls			= 80
HD_Surfaces		= 2
HD_BlocksPerTrack	= 11
HD_NumBlocksRes		= 2
HD_NumBlocks		= HD_Cyls*HD_Surfaces*HD_BlocksPerTrack-HD_NumBlocksRes
HD_NumBlocksUsed	= HD_NumBlocks/2
HD_BytesPerBlock	= 512

.parameterPkt	dc.l	0			;name of dos handler
		dc.l	0			;name of exec device
		dc.l	0			;unit number for OpenDevice
		dc.l	0			;flags for OpenDevice
		dc.l	11			;amount following longwords
		dc.l	HD_BytesPerBlock/4	;longs per block
		dc.l	0			;sector start, unused
		dc.l	HD_Surfaces		;surfaces
		dc.l	1			;sectors per block, unused
		dc.l	HD_BlocksPerTrack	;blocks per track
		dc.l	HD_NumBlocksRes		;reserved blocks
		dc.l	0			;unused
		dc.l	0			;interleave
		dc.l	0			;lower cylinder
		dc.l	HD_Cyls-1		;upper cylinder
		dc.l	5			;buffers

	CNOP 0,4
.volumename	dc.b	7,"WHDLoad",0		;BSTR (here with the exception that it must be 0-terminated!)
.handlername	dc.b	"DH0",0
.devicename	dc.b	"whdload.device",0
.dosname	dc.b	"dos.library",0
.expansionname	dc.b	"expansion.library",0
	EVEN

.bootcode	lea	(.dosname,pc),a1
	;illegal
		jsr	(_LVOFindResident,a6)
		move.l	d0,a0
		move.l	(RT_INIT,a0),a0
		jmp	(a0)			;init dos.library

	CNOP 0,4
		dc.l	4			;segment length
.seglist	dc.l	0			;next segment

	;get own message port
		move.l	(4),a6			;A6 = execbase
		sub.l	a1,a1
		jsr	(_LVOFindTask,a6)
		move.l	d0,a1
		lea	(pr_MsgPort,a1),a5	;A5 = MsgPort

	;init volume structure
		lea	(.volumename,pc),a0
		move.l	a0,d0
		lsr.l	#2,d0
		move.l	d0,-(a7)		;dl_Name
		clr.l	-(a7)			;dl_unused
		move.l	#ID_DOS_DISK,-(a7)	;dl_DiskType (is normally 0!)
		clr.l	-(a7)			;dl_LockList
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_VolumeDate
		clr.l	-(a7)			;dl_Lock
		move.l	a5,-(a7)		;dl_Task (MsgPort)
		move.l	#DLT_VOLUME,-(a7)	;dl_Type
		clr.l	-(a7)			;dl_Next

		move.l	a7,d0
		lsr.l	#2,d0
		move.l	d0,a3			;A3 = Volume
		move.l	(_resload,pc),a2	;A2 = resload

	;fetch and reply startup message
		move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket
		moveq	#-1,d0			;success
		bra	.reply1
		
	;loop on receiving new packets
.mainloop	move.l	a5,a0
		jsr	(_LVOWaitPort,a6)
		move.l	a5,a0
		jsr	(_LVOGetMsg,a6)
		move.l	d0,a4
		move.l	(LN_NAME,a4),a4		;A4 = DosPacket

	;find and call appropriate action
		moveq	#0,d0
		move.l	(dp_Type,a4),d2
		lea	(.action,pc),a0
.next		movem.w	(a0)+,d0-d1
		tst.l	d0
		beq	.illegal		;unknown packet
		cmp.l	d0,d2
		bne	.next
		jmp	(.action,pc,d1.w)

.illegal	illegal

;---------------
; reply dos-packet
; IN:	D0 = res1
;	D1 = res2
;	A4 = DosPacket

.reply2		move.l	d1,(dp_Res2,a4)

;---------------
; reply dos-packet
; IN:	D0 = res1
;	A4 = DosPacket

.reply1		move.l	d0,(dp_Res1,a4)
		move.l	(dp_Port,a4),a0
		move.l	(dp_Link,a4),a1
		move.l	a5,(dp_Port,a4)
		jsr	(_LVOPutMsg,a6)
		bra	.mainloop

.action		dc.w	ACTION_LOCATE_OBJECT,.a_locate_object-.action		;8
		dc.w	ACTION_FREE_LOCK,.a_free_lock-.action			;f
		dc.w	ACTION_DELETE_OBJECT,.a_delete_object-.action		;10
		dc.w	ACTION_COPY_DIR,.a_copy_dir-.action			;13
		dc.w	ACTION_SET_PROTECT,.a_set_protect-.action		;15
		dc.w	ACTION_EXAMINE_OBJECT,.a_examine_object-.action		;17
		dc.w	ACTION_EXAMINE_NEXT,.a_examine_next-.action		;18
		dc.w	ACTION_DISK_INFO,.a_disk_info-.action			;19
		dc.w	ACTION_INHIBIT,.a_inhibit-.action			;1f
		dc.w	ACTION_PARENT,.a_parent-.action				;29
		dc.w	ACTION_READ,.a_read-.action				;52
		dc.w	ACTION_WRITE,.a_write-.action				;57
		dc.w	ACTION_FINDUPDATE,.a_findupdate-.action			;3ec
		dc.w	ACTION_FINDINPUT,.a_findinput-.action			;3ed
		dc.w	ACTION_FINDOUTPUT,.a_findoutput-.action			;3ee
		dc.w	ACTION_END,.a_end-.action				;3ef
		dc.w	ACTION_SEEK,.a_seek-.action				;3f0
		dc.w	0

	;file locking is not implemented! no locklist is used
	;fl_Key is used for the filename which makes it impossible to compare two locks for equality!
	
	STRUCTURE MyLock,fl_SIZEOF
		LONG	mfl_pos			;position in file
		STRUCT	mfl_fib,fib_Reserved	;FileInfoBlock
		LABEL	mfl_SIZEOF

MAXFILENAME = 96	;maximum length including path!

	; conventions for action functions:
	; IN:	a2 = resload
	;	a3 = BPTR volume node
	;	a4 = packet
	;	a5 = MsgPort
	;	a6 = execbase

;---------------

.a_locate_object
		bsr	.getarg1
		move.l	d7,d0
		bsr	.getarg2
		move.l	d7,d1
		move.l	(dp_Arg3,a4),d2
		bsr	.lock
		lsr.l	#2,d0			;APTR > BPTR
		bra	.reply2

;---------------

.a_free_lock	bsr	.getarg1
		move.l	d7,d0
		bsr	.unlock
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_delete_object
		bsr	.getarg1
		move.l	d7,d0
		bsr	.getarg2
		move.l	d7,d1
		bsr	.buildname
		tst.l	d0
		beq	.reply2
		move.l	d0,d2
		move.l	d0,a0
		jsr	(resload_DeleteFile,a2)
		move.l	#MAXFILENAME,d0
		move.l	d2,a1
		jsr	(_LVOFreeMem,a6)
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_copy_dir	bsr	.getarg1
		beq	.illegal
		move.l	d7,a0
		move.l	(fl_Key,a0),d1
		moveq	#0,d0
		move.l	#ACCESS_READ,d2
		bsr	.lock
		bra	.reply2

;---------------

.a_examine_object
		bsr	.getarg1
		move.l	d7,a0			;a0 = APTR lock
		bsr	.getarg2
		move.l	d7,a1			;a1 = APTR fib
		move.l	a0,d0
		beq	.examine_root
	;copy whdload's examine result
		move.l	a1,-(a7)
		add.w	#mfl_fib,a0
		moveq	#fib_Reserved/4-1,d0
.examine_fib	move.l	(a0)+,(a1)+
		dbf	d0,.examine_fib
		move.l	(a7)+,a1
	;adjust
.examine_adj
	;convert CSTR -> BSTR
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1
	;special handling of NULL lock
.examine_root
	illegal
		move.l	a1,d7
		clr.l	-(a7)
		move.l	a7,a0
		jsr	(resload_Examine,a2)
		addq.l	#4,a7
		lea	(.volumename+1,pc),a0
		move.l	d7,a1
		add.w	#fib_FileName,a1
.examine_root2	move.b	(a0)+,(a1)+
		bne	.examine_root2
		move.l	d7,a1
		bra	.examine_adj

;---------------

.a_examine_next
		bsr	.getarg2
		move.l	d7,a0			;a0 = APTR fib
		jsr	(resload_ExNext,a2)
		move.l	d7,a1
	;convert CSTR -> BSTR
		lea	(fib_FileName,a1),a0
		bsr	.bstr
		lea	(fib_Comment,a1),a0
		bsr	.bstr
		bra	.reply2

;---------------

.a_disk_info	move.l	(dp_Arg1,a4),a0
		add.l	a0,a0
		add.l	a0,a0
		clr.l	(a0)+			;id_NumSoftErrors
		clr.l	(a0)+			;id_UnitNumber
		move.l	#ID_VALIDATED,(a0)+	;id_DiskState
		move.l	#HD_NumBlocks,(a0)+	;id_NumBlocks
		move.l	#HD_NumBlocksUsed,(a0)+	;id_NumBlocksUsed
		move.l	#HD_BytesPerBlock,(a0)+	;id_BytesPerBlock
		move.l	#ID_DOS_DISK,(a0)+	;id_DiskType
		move.l	a3,(a0)+		;id_VolumeNode
		clr.l	(a0)+			;id_InUse

;---------------

.a_set_protect
.a_inhibit	moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_parent	bsr	.getarg1
		beq	.parent_root
		move.l	d7,a0			;d7 = lock
		move.l	(fl_Key,a0),a0
		tst.b	(a0)
		beq	.parent_root
	;get string length
		moveq	#-1,d0
.parent_strlen	addq.l	#1,d0
		tst.b	(a0)+
		bne	.parent_strlen		;d0 = strlen
	;search for "/"
		move.l	d7,a0
		move.l	(fl_Key,a0),a0
		lea	(a0,d0.l),a1
.parent_search	cmp.b	#"/",-(a1)
		beq	.parent_slash
		cmp.l	a0,a1
		bne	.parent_search
	;no slash found, so we are locking root
	;lock the parent directory
.parent_slash
	;build temporary bstr
		move.l	a1,d0
		sub.l	a0,d0			;length
		move.l	d0,d3
		addq.l	#4,d3			;+1 and align4
		and.b	#$fc,d3
		sub.l	d3,a7
		move.l	a7,a1
		move.b	d0,(a1)+
.parent_cpy	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bhi	.parent_cpy
	;lock it
		moveq	#0,d0			;lock
		move.l	a7,d1			;name
		move.l	#ACCESS_READ,d2		;mode
		bsr	.lock
		add.l	d3,a7
		lsr.l	#2,d0			;APTR > BPTR
		bra	.reply2
	;that is a special case!
.parent_root	moveq	#0,d0
		moveq	#0,d1
		bra	.reply2

;---------------

.a_read		move.l	(dp_Arg1,a4),a0		;APTR lock
		move.l	(mfl_fib+fib_Size,a0),d0
		move.l	(mfl_pos,a0),d1		;offset
		sub.l	d1,d0			;bytes left in file
		move.l	(dp_Arg3,a4),d3		;bytes to read
		cmp.l	d0,d3
		bls	.read_ok
		move.l	d0,d3
.read_ok	move.l	d3,d0
		beq	.reply1			;eof
		add.l	d0,(mfl_pos,a0)
		move.l	(fl_Key,a0),a0		;name
		move.l	(dp_Arg2,a4),a1		;buffer
		jsr	(resload_LoadFileOffset,a2)
		move.l	d3,d0			;bytes read
		bra	.reply1

;---------------

.a_write	move.l	(dp_Arg1,a4),a0		;APTR lock
		move.l	(dp_Arg3,a4),d0		;len
		move.l	(mfl_pos,a0),d1		;offset
		move.l	d1,d2
		add.l	d0,d2
		move.l	d2,(mfl_pos,a0)
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bls	.write1
		move.l	d2,(mfl_fib+fib_Size,a0)	;new length
.write1		move.l	d0,d3
		move.l	(fl_Key,a0),a0		;name
		move.l	(dp_Arg2,a4),a1		;buffer
		jsr	(resload_SaveFileOffset,a2)
		move.l	d3,d0			;bytes written
		bra	.reply1

;---------------

.a_findinput
.a_findupdate
	;check exist and lock it
		bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		moveq	#ACCESS_READ,d2		;mode
		bsr	.lock
		tst.l	d0			;APTR lock
		beq	.reply2
	;init fh
		bsr	.getarg1
		move.l	d7,a0			;fh
		move.l	d0,(fh_Arg1,a0)		;using the lock we refer the filename later
	;return
		moveq	#DOSTRUE,d0
		bra	.reply1
		
.a_findoutput	bsr	.getarg2
		move.l	d7,d0			;APTR lock
		bsr	.getarg3
		move.l	d7,d1			;BSTR name
		bsr	.buildname
		move.l	d0,d2			;d2 = name
		beq	.reply2
	;create an empty file
		move.l	d2,a0
		sub.l	a1,a1
		moveq	#0,d0
		jsr	(resload_SaveFile,a2)
	;free the name
		move.l	d2,a1
		move.l	#MAXFILENAME,d0
		jsr	(_LVOFreeMem,a6)
		bra	.a_findupdate

;---------------

.a_end		move.l	(dp_Arg1,a4),d0		;APTR lock
		bsr	.unlock
		moveq	#DOSTRUE,d0
		bra	.reply1

;---------------

.a_seek		move.l	(dp_Arg1,a4),a0		;APTR lock
		move.l	(dp_Arg2,a4),d2		;offset
		move.l	(dp_Arg3,a4),d1		;mode
	;calculate new position
		beq	.seek_cur
		bmi	.seek_beg
.seek_end	add.l	(mfl_fib+fib_Size,a0),d2
		bra	.seek_chk
.seek_cur	add.l	(mfl_pos,a0),d2
.seek_beg
.seek_chk
	;validate new position
		cmp.l	(mfl_fib+fib_Size,a0),d2
		bhi	.seek_err
	;set new
		move.l	(mfl_pos,a0),d0
		move.l	d2,(mfl_pos,a0)
		bra	.reply1
.seek_err	move.l	#-1,d0
		move.l	#ERROR_SEEK_ERROR,d1
		bra	.reply2

;---------------
; these functions get the respective arg converted from a BPTR to a APTR in D7

.getarg1	move.l	(dp_Arg1,a4),d7
		lsl.l	#2,d7
		rts
.getarg2	move.l	(dp_Arg2,a4),d7
		lsl.l	#2,d7
		rts
.getarg3	move.l	(dp_Arg3,a4),d7
		lsl.l	#2,d7
		rts

;---------------
; convert c-string into bcpl-string
; IN:	a0 = CSTR
; OUT:	-

.bstr		movem.l	d0-d2,-(a7)
		moveq	#-1,d0
		move.b	(a0)+,d2
.bstr_1		addq.l	#1,d0
		move.b	d2,d1
		move.b	(a0),d2
		move.b	d1,(a0)+
		bne	.bstr_1
		sub.l	d0,a0
		move.b	d0,(-2,a0)
		movem.l	(a7)+,d0-d2
		rts

;---------------
; lock a disk object
; IN:	d0 = APTR lock
;	d1 = BSTR name
;	d2 = LONG mode
; OUT:	d0 = APTR lock
;	d1 = LONG errcode

.lock		movem.l	d4/a4,-(a7)
	;get name
		bsr	.buildname
		tst.l	d0
		beq	.lock_quit
		move.l	d0,d4			;D4 = name
	;get memory for lock
		move.l	#mfl_SIZEOF,d0
		move.l	#MEMF_PUBLIC,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq	.lock_nomem
		move.l	d0,a4			;A4 = myfilelock
	;examine
		move.l	d4,a0			;name
		lea	(mfl_fib,a4),a1		;fib
		jsr	(resload_Examine,a2)
		tst.l	d0
		beq	.lock_notfound
	;set return values
		move.l	a4,d0
		moveq	#0,d1
	;fill lock structure
		clr.l	(a4)+			;fl_Link
		move.l	d4,(a4)+		;fl_Key (name)
		move.l	d2,(a4)+		;fl_Access
		move.l	a5,(a4)+		;fl_Task (MsgPort)
		move.l	a3,(a4)+		;fl_Volume
		clr.l	(a4)+			;mfl_pos
.lock_quit	movem.l	(a7)+,d4/a4
.rts		rts
.lock_notfound	move.l	#mfl_SIZEOF,d0
		move.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		pea	ERROR_OBJECT_NOT_FOUND
		bra	.lock_err
.lock_nomem	pea	ERROR_NO_FREE_STORE
	;on error free the name
.lock_err	move.l	#MAXFILENAME,d0
		move.l	d4,a1
		jsr	(_LVOFreeMem,a6)
		move.l	(a7)+,d1
		moveq	#DOSFALSE,d0
		bra	.lock_quit

;---------------
; free a lock
; IN:	d0 = APTR lock
; OUT:	-

.unlock		tst.l	d0
		beq	.rts
		move.l	d0,a1
		move.l	(fl_Key,a1),-(a7)	;name
		move.l	#mfl_SIZEOF,d0
		jsr	(_LVOFreeMem,a6)
		move.l	(a7)+,a1
		move.l	#MAXFILENAME,d0
		jmp	(_LVOFreeMem,a6)

;---------------
; build name for disk object
; IN:	d0 = APTR lock (can represent a directory or a file)
;	d1 = BSTR name (an object name relative to the lock, may contain assign or volume in front)
; OUT:	d0 = APTR name (size=MAXFILENAME, must be freed via exec.FreeMem)
;	d1 = LONG errcode

.buildname	movem.l	d4-d7,-(a7)
		moveq	#0,d6			;d6 = length path
		moveq	#0,d7			;d7 = length name
	;get length of lock
		tst.l	d0
		beq	.buildname_nolock
		move.l	d0,a0
		move.l	(fl_Key,a0),a0
		move.l	a0,d4			;d4 = ptr path
		moveq	#-1,d6
.buildname_cl	addq.l	#1,d6
		tst.b	(a0)+
		bne	.buildname_cl
.buildname_nolock
	;get length of name
		move.l	d1,a0			;BSTR
		move.b	(a0)+,d7		;length
		beq	.buildname_noname
	;remove leading "xxx:"
		lea	(a0,d7.l),a1		;end
.buildname_col	cmp.b	#":",-(a1)
		beq	.buildname_fc
		cmp.l	a0,a1
		bne	.buildname_col
		subq.l	#1,a1
.buildname_fc	addq.l	#1,a1
		sub.l	a1,d7
		add.l	a0,d7
		move.l	a1,d5			;d5 = ptr name
.buildname_noname
	;check length
		moveq	#1,d0			;the possible seperator "/"
		add.l	d6,d0
		add.l	d7,d0
		cmp.l	#MAXFILENAME,d0
		bhs	.illegal
	;allocate memory for object name
		move.l	#MAXFILENAME,d0
		move.l	#MEMF_PUBLIC,d1
		jsr	(_LVOAllocMem,a6)
		tst.l	d0			;d0 = new object memory
		beq	.buildname_nomem
		move.l	d0,a0
	;copy name
		move.l	d4,a1
		move.l	d6,d1
		beq	.buildname_name
.buildname_cp	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cp
	;add seperator
		tst.l	d7
		beq	.buildname_name
		move.b	#"/",(a0)+
	;copy path
.buildname_name	move.l	d5,a1
		move.l	d7,d1
		beq	.buildname_ok
.buildname_cn	move.b	(a1)+,(a0)+
		subq.l	#1,d1
		bne	.buildname_cn
	;finish
.buildname_ok	clr.b	(a0)			;terminate
		moveq	#0,d1			;errorcode
.buildname_quit	movem.l	(a7)+,d4-d7
		rts

.buildname_nomem
		moveq	#DOSFALSE,d0
		move.l	#ERROR_NO_FREE_STORE,d1
		bra	.buildname_quit

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

_kick		dc.b	"34005.a500",0
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

