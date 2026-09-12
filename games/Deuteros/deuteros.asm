;*---------------------------------------------------------------------------
;  :Program.	deuteros.asm
;  :Contents.	Slave for "Deuteros"
;  :Author.	Wepl
;  :History.	14.05.98 started
;		10.08.98 reading from second disk fixed
;		02.09.98 sound play fixed
;		05.09.98 icache enabled
;		23.09.98 access fault late in the game fixed (olivier schott)
;		30.09.98 first patch for random routine changed
;		08.10.98 patch for "reaching stars" sequence added (Björn Hagström)
;			 new patch routine
;		16.12.98 on second version also bad version requester appears
;			 cache disabled by default
;		07.07.99 reworked for whdload v10
;		03.08.01 adapted for kickemu
;		29.05.02 support for v4 added
;		12.09.26 support for v2/3 added
;  :Originals.	v1 ingame=v1
;		v2 crack of v3
;		v3 sps-958 ingame=v2
;		v4 ingame=v1
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:d/deuteros/Deuteros.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

	STRUCTURE	globals,$100
		LONG	ACTDISK
		LONG	DOIO_OS
		LONG	SIZE3
		WORD	VER

SAVEFILES=0

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %1111

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
;HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 4096		;cache for the filesystem handler (per fh)
;MEMFREE	= $100		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_Disk|WHDLF_NoError|WHDLF_EmulPriv
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir = slv_base
slv_name	dc.b	"Deuteros",0
slv_copy	dc.b	"1991 Ian Bird",0
slv_info	dc.b	"installed & fixed by Wepl",10
		dc.b	"Version 1.11 "
		INCBIN	.date
		dc.b	0
_savename	dc.b	"Disk.3",0
	EVEN

;============================================================================

_bootearly

	;init vars
		move.l	#1,ACTDISK

	;get savedisksize
		lea	(_savename),a0
		move.l	(_resload),a1
		jsr	(resload_GetFileSize,a1)
		move.l	d0,(SIZE3)
		
	;bootblock stuff
		move.l	#$2c00,d0		;offset
		move.l	d0,d1			;size
		moveq	#1,d2			;disk
		lea	$12800,a0		;destination = a4
		move.l	a0,a4
		move.l	(_resload),a3
		jsr	(resload_DiskLoad,a3)
		move.l	#$2c00,d0
		move.l	a4,a0
		jsr	(resload_CRC16,a3)
		moveq	#1,d2
		lea	_pl1,a0
		cmp	#$d84b,d0
		beq	.vok
		moveq	#2,d2
		lea	_pl23,a0
		cmp	#$8ab8,d0
		beq	.v23
		cmp	#$e6dd,d0
		beq	.v23
		moveq	#4,d2
		lea	_pl4,a0
		cmp	#$a1cb,d0
		beq	.vok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a3)

	;v23: move binary from $12800 -> $12500
.v23		move.l	a4,a1
		sub	#$12800-$12500,a4
		move.l	a4,a2
		move	#$2c00/4-1,d1
.copy		move.l	(a1)+,(a2)+
		dbf	d1,.copy

.vok		move	d2,VER

	;patch
		move.l	a4,a1
		jsr	(resload_Patch,a3)

	;hook for doio required for v14
		move.l	(4),a0
		move.l	(_LVODoIO+2,a0),(DOIO_OS)
		lea	(_doio),a1
		move.l	a1,(_LVODoIO+2,a0)
	;start
		jmp	(a4)

_pl1		PL_START
		PL_PS	$30c,_delay14
		PL_R	$9ae			;rn-copylock
		PL_END

_pl23		PL_START
		PL_R	$d2			;motor on
		PL_R	$f0			;motor off
		PL_P	$13c,_diskload
		PL_P	$17e,_diskwrite
		PL_P	$1b6,_diskformat
		PL_PS	$9e0,_delay23
		PL_R	$d38			;rn-copylock
		PL_END

	;d0=length d1=address d7=starttrack
_diskload	movem.l	d0-d2/d7-a2,-(a7)
		mulu	#$1600,d7		;offset

	;savedisk?
		cmp.l	#3,(ACTDISK)
		bne	.go
	;check read size
		move.l	d7,d2
		add.l	d0,d2
		cmp.l	(SIZE3),d2
		bls	.go
	;clear buffer
		move.l	d1,a0
.clr		clr.l	(a0)+
		subq.l	#4,d0
		bhi	.clr
		bra	.end
.go
		move.l	d1,a0			;destination
		move.l	d0,d1			;size
		move.l	d7,d0			;offset
		move.l	(ACTDISK),d2		;disk
		move.l	(_resload),a2
		jsr	(resload_DiskLoad,a2)

		movem.l	(a7),d0-d1
		move.l	d1,d2			;data
		move.l	d0,d1			;size
		move.l	d7,d0			;starttrack
		bsr	_patchfiles

.end		movem.l	(a7)+,d0-d2/d7-a2
		moveq	#0,d0
		rts

	;d0=length d1=address d7=starttrack -> d0=error (0=ok 2=writeprotected)
_diskwrite	cmp.l	#3,(ACTDISK)
		beq	.go
		moveq	#2,d0			;write protected
		rts

.go		movem.l	d1-a6,-(a7)
		move.l	d0,d3			;length
		move.l	d1,a1			;data
		mulu	#$1600,d7		;offset
		move.l	d7,d1
		lea	(_savename,pc),a0
		move.l	(_resload),a2
		jsr	(resload_SaveFileOffset,a2)
		add.l	d7,d3
		cmp.l	(SIZE3),d3		;enlarged ?
		blo	.ok
		move.l	d3,(SIZE3)		;new disk 3 size
.ok		moveq	#0,d0			;success
		movem.l	(a7)+,d1-a6
		rts

	;format savedisk -> d0=error, pretend success (id and directory are written afterwards)
_diskformat	moveq	#0,d0
		rts

_pl4		PL_START
		PL_PS	$306,_delay14
		PL_END

_delay23	move.l	$12500+$22,a1		;original
		bra	_delay

_delay14	move.l	(4),a6			;original
		jsr	(_LVORemPort,a6)	;original
		add.l	#2,(a7)

_delay		movem.l	d0-d1/a0-a1,-(a7)
		moveq	#40,d0			;4 seconds
		move.l	(_resload),a0
		jsr	(resload_Delay,a0)
		movem.l	(a7)+,_MOVEMREGS
		rts

;--------------------------------

_doio		move.l	(IO_DEVICE,a1),a0	;only handle trackdisk.device
		move.l	(LN_NAME,a0),a0		;(keyboard.device is used by v23)
		cmp.l	#"trac",(a0)
		beq	.td
.os		move.l	(DOIO_OS),-(a7)		;other devices/commands go directly to os
		rts
.td
		movem.l	d0-d1/a0-a1,-(a7)
		moveq	#0,d0			;unit
		move.l	(ACTDISK),d1		;image
		bsr	_trd_changedisk
		movem.l	(a7)+,_MOVEMREGS

		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		beq	.read
		cmp.w	#ETD_WRITE,(IO_COMMAND,a1)
		beq	.write
		cmp.l	#3,(ACTDISK)		;other commands not allowed on savedisk
		bne	.os
		st	(IO_ERROR,a1)
		moveq	#-1,d0
		rts

	;read
.read		cmp.l	#3,(ACTDISK)
		bne	.rd
		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(SIZE3),d0
		bls	.rd			;inside savedisk size
	;beyond savedisk size -> clear buffer
		move.l	(IO_DATA,a1),a0
		move.l	(IO_LENGTH,a1),d0
.clr		clr.l	(a0)+
		subq.l	#4,d0
		bhi	.clr
		sf	(IO_ERROR,a1)
		moveq	#0,d0
		rts

.rd		bsr	.callos			;d0 = io_Error
		movem.l	d0-d2,-(a7)
		move.l	(IO_OFFSET,a1),d0
		move.l	(IO_LENGTH,a1),d1
		move.l	(IO_DATA,a1),d2
		bsr	_patchfiles
		movem.l	(a7)+,_MOVEMREGS
		rts

	;write
.write		bsr	.callos			;d0 = io_Error
		tst.b	(IO_ERROR,a1)		;success ?
		bne	.q
		move.l	(IO_OFFSET,a1),d1
		add.l	(IO_LENGTH,a1),d1
		cmp.l	(SIZE3),d1		;enlarged ?
		blo	.q
		move.l	d1,(SIZE3)		;new disk 3 size
.q		rts

.callos		move.l	(DOIO_OS),-(a7)		;enter os function
		rts

;--------------------------------
; d0=offset d1=length d2=data

_patchfiles	movem.l	d0-a2,-(a7)

	IFNE SAVEFILES
	;save files
		bsr	_savefiles
	ENDC

		lea	(.base),a0
		cmp	#2,(VER)
		bne	.vok
		lea	(.base23),a0
.vok		move.l	a0,a2
.next		movem.l	(a0)+,d3-d7
		tst.l	d3
		beq	.end
		cmp.l	(ACTDISK),d3
		bne	.next
		cmp.l	d1,d4
		bne	.next
		cmp.l	d2,d5
		bne	.next
		cmp.l	d0,d6
		bne	.next
		jsr	(a2,d7.l)
.end
		movem.l	(a7)+,d0-a2
		rts

		    ;disk,length,data  ,offset,patch
.base		dc.l	1,$6ca00,$13000,$6e000,.main-.base	;v14 loaded first time			;OK
		dc.l	1,$55400,$1e000,$79000,.main-.base	;loaded after "reaching stars" sequence	;OK
		dc.l	1,$4200,$20000,$5800,.intro-.base						;OK
		dc.l	2,$4200,$20000,$5800,.stars-.base	;"reaching stars"
		dc.l	2,$1600,$256ce,$25200,.late1-.base	;after loading game			;OK
		dc.l	2,$1600,$256c0,$25200,.late4-.base	;after loading game			;OK
		dc.l	0
.base23		dc.l	1,$6bcfc,$13000,$6e000,.main23-.base23	;v23 loaded first time			;OK
		dc.l	1,$55400,$1e000,$79000,.main23-.base23	;bootblock reload after "reaching stars"
		dc.l	2,$4200,$20000,$5800,.stars23-.base23	;"reaching stars"
;		dc.l	2,$2880,$25398,$25200,.late23-.base23	;after loading game, UNVERIFIED
		dc.l	0

	;main exe
.main		lea	_plm1,a0
		cmp	#1,(VER)
		beq	.main_patch
		lea	_plm4,a0
		bra	.main_patch

.main23		lea	_plm23,a0
.main_patch	lea	$13000,a1
		move.l	_resload,a2
		jmp	(resload_Patch,a2)

	;intro
.intro		ret	$2080c			;access fault (intro)
		rts

	;"reaching stars"
.stars		patchs	$2085c,.af1
		rts
.af1		clr.w	$2174c			;access fault (extro)
		clr.w	$21750			;access fault (extro)
		move.l	#1,ACTDISK
		move.l	$2174c,a0		;original
		rts

	;"reaching stars" v23
.stars23	patchs	$20842,.af23
		rts
.af23		clr.w	$2186a			;access fault (extro)
		clr.w	$2186e			;access fault (extro)
		move.l	#1,ACTDISK
		move.l	$2186a,a0		;original
		rts

	;after late loading (oliver schott)
.late1		move.l	#$20000,$7bb7a		;ff0000 -> 20000 tries to read from ROM area
		rts
.late4		move.l	#$20000,$7bbd2
		rts
.late23		move.l	#$20000,$7b3cc		;candidate, verify at runtime
		rts

_plm1		PL_START
		PL_PS	$25116,_disk3		;insert savedisk
		PL_R	$2567c			;format savedisk
		PL_P	$25818,_disk2		;insert data disk
		PL_L	$2c764+2,$20000		;bad random generator reading from $ff0000
		PL_S	$2cc0e,2		;sound play fix
		PL_END

_plm23		PL_START
		PL_PS	$24cee,_disk3		;insert savedisk
		PL_R	$2527e			;format savedisk
		PL_P	$253d6,_disk2		;insert data disk
		PL_L	$2c35a+2,$20000		;bad random generator reading from $ff0000
		PL_S	$2c804,2		;sound play fix
		PL_END

_plm4		PL_START
		PL_PS	$25108,_disk3		;insert savedisk
		PL_R	$2566e			;format savedisk
		PL_P	$2580a,_disk2		;insert data disk
		PL_L	$2c756+2,$20000		;bad random generator reading from $ff0000
		PL_S	$2cc00,2		;sound play fix
		PL_END

;--------------------------------

_disk2		move.l	#2,ACTDISK
		rts
_disk3		move.l	#3,ACTDISK
		add.l	#$130-$116-6,(a7)
		rts

;--------------------------------
; for debugging save all loaded files

	IFNE SAVEFILES
	;save files
_savefiles	movem.l	d0-a6,-(a7)
		lea	.sname,a0
		move.l	(ACTDISK),d3
		add.b	#"0",d3
		move.b	d3,(a0)+
		bsr	.itoa
		move.l	d1,d0
		bsr	.itoa
		move.l	d2,d0
		bsr	.itoa
		move.l	d1,d0				;length
		lea	.sname,a0			;name
		move.l	d2,a1				;data
		move.l	_resload,a6
		jsr	(resload_SaveFile,a6)
		movem.l	(a7)+,d0-a6
		rts

.sname		dc.b	"0-00000-00000-00000",0		;disk offset length data
.itoa		addq.l	#1,a0
		swap	d0
		move.b	.list(PC,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	.list(PC,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	.list(PC,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	.list(PC,d0.w),(a0)+
		clr.w	d0
		rol.l	#4,d0
		move.b	.list(PC,d0.w),(a0)+
		rts
.list		dc.b	"0123456789abcdef"
	ENDC
		
;============================================================================

	END

