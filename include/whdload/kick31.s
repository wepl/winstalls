;*---------------------------------------------------------------------------
;  :Modul.	kick31.s
;  :Contents.	interface code and patches for kickstart 3.1
;  :Author.	Wepl, JOTD, Psygore
;  :Version.	$Id: kick31.s 1.6 2003/04/07 06:51:54 wepl Exp wepl $
;  :History.	04.03.03 rework/cleanup
;		04.04.03 disk.ressource cleanup
;		06.04.03 some dosboot changes
;			 cache option added
;		15.05.03 patch for exec.ExitIntr to avoid double ints
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
	INCLUDE	exec/resident.i
	INCLUDE	graphics/gfxbase.i

KICKVERSION = 40
	MC68020

;============================================================================

_boot		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

	IFD CACHE
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)
	ENDC

	;relocate some addresses
		lea	(_cbswitch,pc),a0
		lea	(_cbswitch_tag,pc),a1
		move.l	a0,(a1)
		
	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a5)
	
	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#$9FF5,d1			;crc16
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
		PL_S	$d6,$166-$d6
		PL_PS	$166,kick_leaveled
		PL_S	$1a6,$1ac-$1a6			;kick chksum
		PL_PS	$240,kick_detectchip
		PL_S	$246,$26a-$246			;kick_detectchip
		PL_S	$334,6				;kick_detectfast
		PL_L	$376,-1				;disable search for residents at $f00000
		PL_P	$38e,kick_detectfast
	;	PL_S	$422,6				;LED, reboot unexpected int
	;	PL_S	$430,6				;LED, reboot unexpected int
		PL_R	$460				;check Fat Gary, RAMSEY, Gayle $de1000
	IFEQ FASTMEMSIZE
	IFD HRTMON
		PL_PS	$5aa,kick_hrtmon
	ENDC
	ENDC
		PL_P	$c1c,kick_detectcpu
		PL_P	$d36,_flushcache		;exec.CacheControl
		PL_P	$db8,kick_reboot		;exec.ColdReboot
		PL_P	$1394,exec_ExitIntr
		PL_PS	$1c6c,_flushcache		;exec.MakeFunctions using exec.CacheClearU without
							;proper init for cpu's providing CopyBack
	IFD MEMFREE
		PL_P	$1e86,exec_AllocMem
	ENDC
	;	PL_L	$329a,$70004e71			;SAD, movec vbr,d0 -> moveq #0,d0
		PL_S	$38f8,$3a00-$38f8		;autoconfiguration at $e80000
	IFD HDINIT
		PL_PS	$42f4,hd_init
	ENDC
	IFHI NUMDRIVES-4
		PL_B	$439f,7				;allow 7 floppy drives
	ENDC
	IFD _bootearly
		PL_PS	$4798,kick_bootearly
	ENDC
	IFD _bootblock
		PL_PS	$4896,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_PS	$b484,gfx_readvpos		;patched to set NTSC/PAL
		PL_S	$b4a0,$b4b0-$b4a0		;snoop, byte writes to bpl1dat-bpl6dat, strange?
		PL_S	$b73c,6				;blit wait, graphics init
		PL_S	$b758,6				;blit wait, graphics init
	IFD INITAGA
		PL_PS	$b9f8,gfx_initaga
	ENDC
		PL_P	$bb7e,gfx_detectgenlock
		PL_PS	$f6d8,gfx_beamcon01
		PL_PS	$f72e,gfx_vbstrt1
		PL_PS	$f748,gfx_vbstrt2
		PL_PS	$f796,gfx_vbstrt2
		PL_PS	$f7be,gfx_beamcon02
		PL_PS	$f7e0,gfx_snoop1
		PL_PS	$14b4e,gfx_readvpos		;patched to set NTSC/PAL
	IFD STACKSIZE
		PL_L	$22772,STACKSIZE/4
	ENDC
	IFD _bootdos
		PL_PS	$22814,dos_bootdos
	ENDC
	IFD _cb_dosLoadSeg
		PL_PS	$272b0,dos_LoadSeg
	ENDC
		PL_CB	$3504a				;dont init scsi.device
	IFD INIT_AUDIO					;audio.device
		PL_B	$3b7ae,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_CB	$3ddf2				;dont init battclock.ressource
		PL_S	$40414,$40436-$40414		;skip disk unit detect
		PL_P	$40566,disk_getunitid
		PL_P	$4056e,disk_getunitid
	IFD INIT_MATHFFP				;mathffp.library
		PL_B	$40632,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_P	$40D3A,timer_init
	;	PL_NOP	$44294,2			;skip rom menu
		PL_P	$44A5A,trd_task
		PL_P	$45258,trd_format
		PL_P	$4569C,trd_motor
		PL_P	$4598C,trd_readwrite
		PL_PS	$45D5A,trd_protstatus
		PL_PS	$46230,trd_init
	IFD FONTHEIGHT
		PL_B	$68CB0,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$68D16,6			;color17,18,19
		PL_C	$68D1E,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$68D1C,POINTERTICKS
	ENDC
	IFD INIT_GADTOOLS				;gadtools.library
		PL_B	$68e1e,RTF_COLDSTART|RTF_AUTOINIT
	ENDC
		PL_END

;============================================================================

kick_leaveled	and.b	#~CIAB_LED,$BFE001
		rts

kick_detectchip	move.l	#CHIPMEMSIZE,a3
		rts

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem,pc),a0
		add.l	#KICKSIZE,a0
		move.l	a0,a4
		add.l	#FASTMEMSIZE,a4
	ENDC
		rts

	IFEQ FASTMEMSIZE
	IFD HRTMON
kick_hrtmon	add.l	d2,d0
		subq.l	#8,d0			;hrt reads too many from stack -> avoid af
		move.l	d0,(SysStkUpper,a6)
		rts
	ENDC
	ENDC

kick_detectcpu	move.l	(_attnflags,pc),d0
	IFND NEEDFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_ExitIntr	tst.w	(_custom+intreqr)	;delay to make sure int is cleared
		movem.l	(a7)+,d0-d1/a0-a1/a5-a6
		rte

	IFD MEMFREE
exec_AllocMem	move.l	d0,-(a7)
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
.2		move.l	(a7)+,d0
		addq.l	#4,a7
		rts
	ENDC

	IFD _bootearly
kick_bootearly	movem.l	d0-a6,-(a7)
		bsr	_bootearly
		movem.l	(a7)+,d0-a6
		moveq	#0,d2			;original
		lea	($1c,a2),a3		;original
		rts
	ENDC

	IFD _bootblock
kick_bootblock	move.l	(a7)+,d1		;original
		addq.l	#2,d1
		movem.l	d1-d7/a2-a6,-(a7)	;original
		bra	_bootblock
	ENDC

;============================================================================

gfx_beamcon01	bclr	#4,(gb_Bugs,a1)			;original
		move.l	a0,d2
		lea	(_cbswitch_beamcon0,pc),a0
		move.w	d4,(a0)
		st	(_cbflag_beamcon0-_cbswitch_beamcon0,a0)
		move.l	d2,a0
		rts

gfx_vbstrt1	move.l	d2,(vbstrt,a0)			;original
		move.l	(gb_SHFlist,a1),(cop2lc,a0)	;original
		move.l	a0,d0
		lea	(_cbswitch_vbstrt,pc),a0
		move.w	d2,(a0)
		st	(_cbflag_vbstrt-_cbswitch_vbstrt,a0)
		move.l	(gb_SHFlist,a1),(_cbswitch_cop2lc-_cbswitch_vbstrt,a0)
		move.l	d0,a0
		addq.l	#4,(a7)
		rts

gfx_vbstrt2	move.l	d2,(vbstrt,a0)			;original
		move.l	(gb_LOFlist,a1),(cop2lc,a0)	;original
		move.l	a0,d0
		lea	(_cbswitch_vbstrt,pc),a0
		move.w	d2,(a0)
		st	(_cbflag_vbstrt-_cbswitch_vbstrt,a0)
		move.l	(gb_LOFlist,a1),(_cbswitch_cop2lc-_cbswitch_vbstrt,a0)
		move.l	d0,a0
		addq.l	#4,(a7)
		rts

gfx_beamcon02	bclr	#13,d4				;original
		move.w	d4,(beamcon0,a0)		;original
		move.l	a0,d0
		lea	(_cbswitch_beamcon0,pc),a0
		move.w	d4,(a0)
		st	(_cbflag_beamcon0-_cbswitch_beamcon0,a0)
		move.l	d0,a0
		addq.l	#2,(a7)
		rts

	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		tst.b	(_cbflag_beamcon0,pc)
		beq	.nobeamcon0
		move.w	(_cbswitch_beamcon0,pc),(_custom+beamcon0)
.nobeamcon0	tst.b	(_cbflag_vbstrt,pc)
		beq	.novbstrt
		move.w	(_cbswitch_vbstrt,pc),(_custom+vbstrt)
.novbstrt	jmp	(a0)

gfx_readvpos	move	(vposr+_custom),d0
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.pal
		bset	#12,d0
		bra.b	.end
.pal		bclr	#12,d0
.end		rts

gfx_detectgenlock
		moveq	#0,d0
		rts

	IFD INITAGA					;enable enhanced gfx modes
gfx_initaga	move.l	#SETCHIPREV_BEST,d0
		jsr	(_LVOSetChipRev,a6)
		moveq	#-1,d0
		movem.l	(-$34,a5),d2/d6/d7/a2/a3/a6	;original
		rts
	ENDC

;============================================================================

disk_getunitid
	IFMI NUMDRIVES
		cmp.l	#1,d0			;at least one drive
		bcs	.set
		cmp.l	(_custom1,pc),d0
	ELSE
		subq.l	#NUMDRIVES,d0
	ENDC
.set		scc	d0
		extb.l	d0
		rts

;============================================================================

timer_init	move.l	(_time),a0
		move.l	(whdlt_days,a0),d0
		mulu	#24*60,d0
		add.l	(whdlt_mins,a0),d0
		mulu.l	#60,d0
		move.l	(whdlt_ticks,a0),d1
		divu	#50,d1
		ext.l	d1
		add.l	d1,d0
		move.l	d0,($40,a2)
		movem.l	(a7)+,d2/a2-a3		;original
		rts

;============================================================================
;  $60.1 0-disk in drive 1-no disk
;  $60.4 0-readwrite 1-readonly
;  $61.7 motor status
;  $63 unit
;  $3c disk change count

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)

		moveq	#0,d1
		move.b	($63,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)

		btst	#1,($60,a3)		;disk inserted?
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
	IFD DISKSONBOOT
_trd_chg	dc.b	%1111111		;diskchanged
	ELSE
_trd_chg	dc.b	0			;diskchanged
	ENDC

trd_motor	moveq	#0,d0
		bchg	#7,($61,a3)		;motor status
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	($63,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$d74-$d5a-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$453A4,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$44BDC,(a7)
		rts

trd_init	lea	($14c,a3),a0		;original
		move.l	a0,($10,a3)		;original
		bset	#1,($60,a3)		;no disk in drive
		addq.l	#2,(a7)
		rts

trd_task	move.b	($63,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,($60,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($3c,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,($60,a3)		;set disk inserted
		addq.l	#1,($3c,a3)		;inc change count
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

	IFD _cb_dosLoadSeg
dos_LoadSeg	move.l	d0,d1		;original
		beq	.end		;successful?
		tst.l	d7		;filename
		beq	.end

		movem.l	d0-a6,-(a7)
		move.l	d7,a0
.cnt		tst.b	(a0)+
		bne	.cnt
		subq.l	#1,a0
		sub.l	d7,a0
		move.l	a0,d0
		
		sub.w	#260,a7		;BSTR cannot be longer than 255
		move.l	a7,d4
		addq.l	#2,d4
		and.w	#$fffc,d4	;longword aligned
		move.l	d4,a0
		move.b	d0,(a0)+
		move.l	d7,a1
.cpy		move.l	(a1)+,(a0)+	;mc68020+!
		subq.b	#4,d0
		bcc	.cpy

		move.l	d4,d0
		lsr.l	#2,d0
		bsr	_cb_dosLoadSeg
		bsr	_flushcache

		add.w	#260,a7
		movem.l	(a7)+,d0-a6

.end		move.l	(a7)+,a0
		lea	(12,a7),a7	;original
		tst.l	d0
		jmp	(a0)
	ENDC

	IFD _bootdos
dos_bootdos
	;init boot exe
		lea	(_bootdos,pc),a0
		move.l	a0,(bootfile_exe_j+2-_bootdos,a0)
	;fake startup-sequence
		lea	(bootname_ss,pc),a0
		move.l	a0,d1
	;return
		rts
	ENDC

;============================================================================

	IFD HDINIT
hd_init		move.l	(a7)+,d0
		movem.l	d0/d2/a2-a6,-(a7)	;original
		moveq	#0,d0			;original

	INCLUDE	Sources:whdload/kickfs.s
	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d2) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
		illegal		;security if executed without mmu
	ENDC

;============================================================================

_kick		dc.b	"40068.a1200",0
	CNOP 0,4
_tags		dc.l	WHDLTAG_CBSWITCH_SET
_cbswitch_tag	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
	IFMI NUMDRIVES
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
	ENDC
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0
_cbswitch_beamcon0	dc.w	0
_cbswitch_vbstrt	dc.w	0
_cbflag_beamcon0	dc.b	0
_cbflag_vbstrt		dc.b	0

;============================================================================

	END
