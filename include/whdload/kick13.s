;*---------------------------------------------------------------------------
;  :Program.	Lotus2.asm
;  :Contents.	Slave for
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick.asm 0.2 1999/12/07 23:18:05 jah Exp jah $
;  :History.	19.10.99 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/exec.i
	INCLUDE	devices/trackdisk.i

	;OUTPUT	"wart:k-l/lotus2/Lotus2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=0

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1110

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
NOFPU

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
HRTMON

; amount of
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000


KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Kickstarter",0
_copy		dc.b	"1989 Amiga",0
_info		dc.b	"Emulation by Wepl",10
		dc.b	"Version 0.1 "
		INCBIN	"T:date"
		dc.b	0
_kick		dc.b	"devs:kickstarts/kick34005.a500",0
_rtb		dc.b	"devs:kickstarts/kick34005.a500.rtb",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

	;set caches
		move.l	#0,d0
		move.l	#WCPUF_All,d1
	;	jsr	(resload_SetCPU,a5)

	;get tags
		lea	(_tags),a0
		jsr	(resload_Control,a5)
	
	;load kickstart
		lea	(_kick),a0
		move.l	(_expmem),a1
		move.l	a1,a4				;A4 = kickstart
		jsr	(resload_LoadFileDecrunch,a5)
		cmp.l	#KICKSIZE,d0
		bne	.wrongkick
		move.l	a4,a0
		jsr	(resload_CRC16,a5)
		cmp.w	#$f9e3,d0
		bne	.wrongkick

	;load relocation table
		lea	(_rtb),a0
		lea	($400),a1
		move.l	a1,a2				;A2 = rtb
		jsr	(resload_LoadFileDecrunch,a5)
		
	;relocate the kickstart
		addq.l	#4,a2				;skip kick-chksum
		move.l	#$fc0000,d2
		sub.l	a4,d2
		moveq	#0,d1
		bra	.1

.add		add.l	d0,d1
.2		sub.l	d2,(a4,d1.l)
		moveq	#0,d0
		move.b	(a2)+,d0
		bne	.add
		move.l	a2,d3
		btst	#0,d3
		beq	.3
		addq.l	#1,a2
.3		move.w	(a2)+,d0
		bne	.add
.1		move.l	(a2)+,d0
		bpl	.add

		asr.l	#2,d2
		bra	.4
.5		sub.l	d2,(a4,d1.l)
.4		move.l	(a2)+,d1
		bne	.5
		
	;patch the kickstart
		lea	kick_patch,a0
		move.l	a4,a1
		jsr	(resload_Patch,a5)

	;call
	;	jmp	(2,a4)				;original entry
		jmp	($fe,a4)			;34.005

.wrongkick	pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a5)

kick_patch	PL_START
		PL_W	$132,0				;color00 $444 -> $000
		PL_P	$61a,kick_detectfast
		PL_P	$592,kick_detectchip
		PL_W	$25a,0				;color00 $888 -> $000
	IFD HRTMON
		PL_PS	$286,kick_hrtmon
	ENDC
		PL_P	$546,kick_detectcpu
		PL_PS	$15b2,exec_MakeFunctions
		PL_PS	$14b6,exec_SetFunction
		PL_PS	$422,exec_Supervisor
		PL_L	$4f4,-1				;disable search for residents at $f00000
		PL_S	$4cce,4				;skip autoconfiguration at $e80000
		PL_P	$af96,gfx_detectgenlock
		PL_P	$b00c,gfx_detectdisplay
		PL_W	$aece,0				;color00 $fff -> $000
		PL_W	$aed4,0				;color01 $fff -> $000
	;	PL_PS	$aec6,gfx_fix1
	;	PL_B	$d57a,$66
	;	PL_I	$d568
	IFD _bootblock
		PL_PS	$285c6,_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$2a3b4,td_readwrite
		PL_I	$2a5d8				;internal readwrite
		PL_P	$2a0e2,td_motor
		PL_I	$2a694				;td_seek
		PL_P	$29cfa,td_format
		PL_PS	$2a6d6,td_protstatus
		PL_I	$2af68				;td_rawread
		PL_I	$2af6e				;td_rawwrite
		PL_I	$2a19c				;empty dbf-loop in trackdisk.device
		PL_P	$2960c,td_task
	;	PL_L	$29c54,-1			;disable asynchron io
		PL_P	$4984,disk_getunitid
		
		PL_PS	$33ef0,dos_init
		PL_PS	$3c9b6,dos_1

		PL_END		

;DANGER:
;	$3c9ae

;============================================================================

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem),a4
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
.1		sub.l	#8,d0
		rts
	ENDC

kick_detectcpu	move.l	(_attnflags),d0
	IFD NOFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_MakeFunctions
		subq.l	#8,a7
		move.l	(8,a7),(a7)
		move.l	a3,(4,a7)		;original
		lea	(_flushcache),a3
		move.l	a3,(8,a7)
		moveq	#0,d0			;original
		move.l	a2,d1			;original
		rts

exec_SetFunction
		move.l	(a7)+,d1
		pea	(_flushcache)
		move.l	d1,-(a7)
		bset	#1,(14,a1)		;original
		rts

exec_Supervisor	lea	(.1),a0
		move.l	a0,(_LVOSupervisor+2,a6)
		lea	(_custom),a0		;original
		bra	_flushcache

.1		movem.l	a0-a1,-(a7)
		move.l	($bc),a0
		lea	(.2),a1
		move.l	a1,($bc)
		move.l	a7,a1
		trap	#15
		addq.l	#8,a7
		rts

.2		move.l	a0,($bc)
		movem.l	(a1),a0-a1
		jmp	(a5)

;============================================================================

gfx_detectgenlock
		moveq	#0,d0
		rts

gfx_detectdisplay
		moveq	#4,d0			;pal
		move.l	(_monitor),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.1
		moveq	#1,d0			;ntsc
.1		rts

gfx_fix1	waitvb	a3
		move.w	#DMAF_SPRITE|DMAF_COPPER|DMAF_RASTER|DMAF_SETCLR,(dmacon,a3)
		rts

;============================================================================

disk_getunitid
	IFNE NUMDRIVES-4
		lea	(12,a3),a3
	IFEQ NUMDRIVES
		clr.l	-(a7)
		subq.l	#4,a7
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		move.l	(_resload),a1
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

td_format
td_readwrite	moveq	#0,d1
		move.b	($43,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)
		btst	#1,($40,a3)		;disk inserted?
		beq	.diskok
		moveq	#TDERR_DiskChanged,d0
		move.b	d0,(IO_ERROR,a1)
		rts

.diskok		cmp.b	#CMD_READ,(IO_COMMAND+1,a1)
		bne	td_write
		
td_read		movem.l	d2/a1,-(a7)
		moveq	#0,d2
		move.b	(_td_disk,pc,d1.w),d2	;disk
		move.l	(IO_OFFSET,a1),d0	;offset
		move.l	(IO_LENGTH,a1),d1	;length
		move.l	(IO_DATA,a1),a0		;destination
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		movem.l	(a7),_MOVEMREGS
		bsr	td_endio
		movem.l	(a7)+,_MOVEMREGS
		moveq	#0,d0
		rts

td_write	movem.l	a1-a2,-(a7)
		move.b	(_td_prot,pc),d0
		btst	d1,d0
		beq	.prot
		lea	(.disk),a0
		move.b	(_td_disk,pc,d1.w),d0	;disk
		add.b	#"0",d0
		move.b	d0,(5,a0)		;name
		move.l	(IO_LENGTH,a1),d0	;length
		move.l	(IO_OFFSET,a1),d1	;offset
		move.l	(IO_DATA,a1),a1		;destination
		move.l	(_resload),a2
		jsr	(resload_SaveFileOffset,a2)
		movem.l	(a7),_MOVEMREGS
		bsr	td_endio
		movem.l	(a7)+,_MOVEMREGS
		moveq	#0,d0
		rts

.prot		moveq	#TDERR_WriteProt,d0
		move.b	d0,(IO_ERROR,a1)
		rts

.disk		dc.b	"Disk.",0,0,0

_td_disk	dc.b	1,2,3,4			;number of diskimage in drive
_td_prot	dc.b	WPDRIVES		;protection status
_td_chg		dc.b	0			;diskchanged

td_motor	moveq	#0,d0
		bchg	#7,($41,a3)		;motor status
		seq	d0
		rts

td_protstatus	moveq	#0,d0
		move.b	($43,a3),d1
		move.b	(_td_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$708-$6d6-6,(a7)
		rts

td_endio	move.l	(_expmem),-(a7)
		add.l	#$29e30,(a7)
		rts

tdtask_cause	move.l	(_expmem),-(a7)
		add.l	#$296e8,(a7)
		rts

td_task		bclr	#1,($40,a3)		;set disk inserted
		beq	.1
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.1
		move.b	($43,a3),d1		;unit number
		move.b	(_td_chg),d0
		btst	d1,d0
		beq	.2
		bset	#1,($40,a3)		;set no disk inserted
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
		bclr	#1,($40,a3)		;set disk inserted
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause

.2		rts

	;d0.b = unit
	;d1.b = new disk image number
_td_changedisk	movem.l	a6,-(a7)

		and.w	#3,d0
		lea	(_td_chg),a0
.wait		btst	d0,(a0)
		bne	.wait
		
		move.l	(4),a6
		jsr	(_LVOForbid,a6)
		
		move.b	d1,(-5,a0,d0.w)
		bset	d0,(a0)
		
		jsr	(_LVOPermit,a6)
		
		movem.l	(a7)+,_MOVEMREGS
		rts

;============================================================================

dos_init	move.l	#$10001,d1
		bra	_flushcache

dos_1		move.l	#$118,d1		;original
		bra	_flushcache

;============================================================================

_flushcache	move.l	(_resload),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

_tags		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	0
_resload	dc.l	0

;============================================================================

	END

