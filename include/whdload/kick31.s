;*---------------------------------------------------------------------------
;  :Modul.	kick31.s
;  :Contents.	interface code and patches for kickstart 3.1
;  :Author.	JOTD, Wepl, Psygore
;  :Version.	$Id$
;  :History.	04.03.03 cleanup
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
		PL_PS	$1c6c,_flushcache		;exec.MakeFunctions using exec.CacheClearU without
							;proper init for cpu's providing CopyBack
	IFD MEMFREE
		PL_P	$1e86,exec_AllocMem
	ENDC
	;	PL_L	$329a,$70004e71			;SAD, movec vbr,d0 -> moveq #0,d0
		PL_S	$38f8,$3a00-$38f8		;autoconfiguration at $e80000
	IFD _bootblock
		PL_PS	$4896,_bootblock		;a1=ioreq a4=buffer a6=execbase
		PL_NOP	$4896+6,6			;d2-d7/a2-a6 must be untouched
	ENDC
		PL_S	$b4a0,$b4b0-$b4a0		;snoop, byte writes to bpl1dat-bpl6dat, strange?
		PL_S	$b73c,6				;blit wait, graphics init
		PL_S	$b758,6				;blit wait, graphics init
		PL_P	$bb7e,gfx_detectgenlock
		PL_PS	$f6d8,gfx_beamcon01
		PL_PS	$f72e,gfx_vbstrt1
		PL_PS	$f748,gfx_vbstrt2
		PL_PS	$f796,gfx_vbstrt2
		PL_PS	$f7be,gfx_beamcon02
		PL_PS	$f7e0,gfx_snoop1
		PL_CB	$3504a				;dont init scsi.device
		PL_CB	$3ddf2				;dont init battclock.ressource
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
	;	PL_NOP	$44294,2			;skip rom menu


;		PL_S	$aecc,$e4-$cc			;skip color stuff & strange gb_LOFlist set
;		PL_P	$bc48,gfx_detectdisplay		; patched at a lower level (NTSC/PAL)
;		PL_PS	$8568,gfx_read_vpos		; gfx_VBeamPos, unpatched
		PL_PS	$B484,gfx_read_vpos		; patched to set NTSC/PAL
		PL_PS	$14B4E,gfx_read_vpos		; patched to set NTSC/PAL

	IFD _bootearly
		PL_P	$4794,do_bootearly		; 3.1
	ENDC
	IFD _bootdos
		PL_PS	$22814,dos_bootdos		; 3.1
	ENDC
	IFD	HDINIT
		PL_P	$42F4,hd_init			; 3.1
	ENDC
		PL_P	$40D3A,timer_init		; 3.1
		PL_P	$4598C,trd_readwrite		; 3.1
		PL_P	$4569C,trd_motor		; 3.1
		PL_P	$45258,trd_format		; 3.1
		PL_PS	$45D5A,trd_protstatus		; 3.1
	;	PL_I	$2af68				;trd_rawread
	;	PL_I	$2af6e				;trd_rawwrite
	;	PL_I	$2a19c				;empty dbf-loop in trackdisk.device
		PL_P	$44A5A,trd_task			; 3.1
	;	PL_L	$29c54,-1			;disable asynchron io
		PL_P	$40442,disk_getunitid		; 3.1
	IFD	_cb_dosLoadSeg
		PL_PS	$2726A,dos_LoadSeg		; 3.1 loadseg entrypoint
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
		move.l	(_cbswitch_beamcon0,pc),(_custom+beamcon0)
.nobeamcon0	tst.b	(_cbflag_vbstrt,pc)
		beq	.novbstrt
		move.l	(_cbswitch_vbstrt,pc),(_custom+vbstrt)
.novbstrt	jmp	(a0)


; JFF: fake PAL (resp NTSC) on a NTSC (resp PAL) amiga
gfx_read_vpos
	move	(vposr+_custom),d0
		move.l	d1,-(a7)
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq.b	.pal
		; ntsc
		bset	#12,d0
		bra.b	.sk
.pal
		bclr	#12,d0
.sk
		move.l	(a7)+,d1

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

;============================================================================

disk_getunitid
	; compute number of drives

	IFEQ NUMDRIVES
		; NUMDRIVES = 0: try to read CUSTOM1
		clr.l	-(a7)
		subq.l	#4,a7
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		move.l	(_resload,pc),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7),d1
		addq.l	#8,a7
		tst.l	d1
		bne.b	.nz
		moveq.l	#1,d1	; 0 or less: set 1		
.nz
		cmp.l	#5,d1
		bcs.b	.le4
		moveq.l	#4,d1	; 5 or more: set 4
.le4
	ELSE
		moveq	#NUMDRIVES,d1
	ENDC
		moveq.l	#1,d0
		addq.l	#2,d1
		lsl	d1,d0	; 2^(numdrive+3-1)

		moveq	#-1,D1
		cmp.b	d3,d0
		bcs.b	.d	; no more drives
		moveq	#0,D1
.d
		move.l	D1,(A3)+
		move.l	D1,D0
		rts

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
		move.b	(99,a3),d1		;unit number (67 in kick 1.3)
		clr.b	(IO_ERROR,a1)

		btst	#1,(96,a3)		;disk inserted? (64 in 1.3)
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
		bchg	#7,(97,a3)		;motor status (65 in 1.3)
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	(99,a3),d1		;unit number
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

trd_task
	IFD DISKSONBOOT
		bclr	#1,(96,a3)		;set disk inserted (40 in 1.3)
		beq	.1
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.1
	ENDC
		move.b	(67,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,(64,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,(64,a3)		;set disk inserted
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

	ENDC
	ENDC

	IFD  _bootdos
dos_bootdos
	IFD	INITAGA
	bsr	init_aga
	ENDC

	;init boot exe
		lea	(_bootdos,pc),a0
		move.l	a0,(bootfile_exe_j+2-_bootdos,a0)

	;fake startup-sequence
		lea	(bootname_ss_b,pc),a0	;bstr
		addq.l	#1,a0
		move.l	a0,d1

	;return
		rts
	ENDC

;============================================================================

	IFD HDINIT

hd_init:
	movem.l	D2/A2-A6,-(A7)	
	move.l	#-1,A2
	bsr	.init
	movem.l	(A7)+,D2/A2-A6
;;	moveq	#0,D0		; original
	rts

.init
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

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d2) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
		illegal		;security if executed without mmu
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

; not done as in kick13.s at all!
; sorry Bert, but anyway doslib was completely rewritten after all :)

	IFD	_cb_dosLoadSeg
dos_LoadSeg
	move.l	(A7)+,a0
	movem.l	D2-D3,-(A7)
	move.l	d1,d2			;save name
	pea	.cont(pc)
	MOVEM.L	D2/D7/A6,-(A7)		;original
	MOVEA.L	4.W,A6	;code
	jmp	(2,a0)
.cont:
	move.l	d0,d3			;save seglist
	movem.l	d0/d1/d4-d6/a0-a6,-(A7)	; save rest of registers

	; allocate some stack space

	lea	-120(a7),a7

	move.l	a7,d4
	addq.l	#2,d4
	and.l	#$FFFFFFFC,d4	; longword aligned
	move.l	d4,a0
	move.l	d2,a1
	addq.l	#1,a0
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy
	sub.l	d4,a0
	move.l	d4,a1
	move.l	a0,d5
	subq.l	#2,d5
	move.b	d5,(a1)		; BSTR length
	
	move.l	d4,d0
	lsr.l	#2,d0		; BSTR name
	move.l	d3,d1		; seglist

	; call user routine

	bsr	_cb_dosLoadSeg

	; free the stack space

	lea	120(a7),a7

	; cache flush

	bsr	_flushcache

	; restore registers and return to caller

	movem.l	(a7)+,d0/d1/d4-d6/a0-a6
	movem.l	(a7)+,D2-D3
	tst.l	d0
	rts
		
	ENDC

	IFD	INITAGA
init_aga
	movem.l	d0-d1/a0-a1/a6,-(a7)

	; enable enhanced gfx modes

	lea	.gfxname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6
	move.l	#SETCHIPREV_BEST,D0
	jsr	_LVOSetChipRev(a6)

	movem.l	(a7)+,d0-d1/a0-a1/a6
	rts

.gfxname:
	dc.b	"graphics.library",0
	even

	ENDC

	IFD _bootearly
do_bootearly:
	IFD	INITAGA
	bsr	_INITAGA
	ENDC

	; initialize audio device

	IFD	INIT_AUDIO
	lea	.audioname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_GADTOOLS
	lea	.gadtoolsname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_INPUT
	lea	.inputname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_MATHFFP
	lea	.mathffpname(pc),a1
	bsr	.init_resident
	ENDC
	bra	_bootearly

	IFD	INIT_AUDIO
.audioname:
	dc.b	"audio.device",0
	ENDC
	IFD	INIT_GADTOOLS
.gadtoolsname:
	dc.b	"gadtools.library",0
	ENDC
	IFD	INIT_MATHFFP
.mathffpname:
	dc.b	"mathffp.library",0
	ENDC
	IFD	INIT_INPUT
.inputname:
	dc.b	"input.device",0
	ENDC

	even
.init_resident:
	move.l	$4.W,A6
	jsr	_LVOFindResident(a6)
	tst.l	D0
	bne.b	.ok
	illegal
.ok
	move.l	D0,A1
	moveq.l	#0,D1
	jsr	_LVOInitResident(a6)
	rts
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
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0
_cbswitch_beamcon0	dc.w	0
_cbswitch_vbstrt	dc.w	0
_cbflag_beamcon0	dc.b	0
_cbflag_vbstrt		dc.b	0

;============================================================================

