;*---------------------------------------------------------------------------
;  :Program.	simcity.asm
;  :Contents.	Slave for "Sim City" from Maxis
;  :Author.	Galahad, Wepl
;  :History.	01.01.10 V1.4 three separate Slaves 512K/1.2/CDTV (Galahad)
;		08.11.26 repo import
;			 one floppy Slave for 512K/1.0/1.2, version detected at
;			 runtime, ws_MemConfig for 512K Chip + 512K Fast or 1 MB
;			 Chip, unused code from FA18 template removed
;		10.11.26 CDTV Slave built from the same source (define CDTV)
;			 CDTV: cdtv.device via INIT_CDDEVICE, CD audio via
;			 resload_Audio
;		15.11.26 CDTV: language from WHDLTAG_LANG_GET instead of bookmark
;		16.11.26 version check via CRC16 and patch lists instead of
;			 pattern search, random generator init kept on floppy
;			 versions
;			 Custom1 starts PrintCity
;		17.11.26 version 1.0 supported, HLS protection removed
;		18.11.26 CDTV: memory card detection patched to 'no card'
;			 1.0/1.2: stack size passed like CLI (Aztec startup)
;			 access fault on window title update fixed
;			 current directory set, saving cities failed
;			 cache flush after building the segment for the processes
;			 started by the game (Simulator, Maps, Graphs)
;			 1.0/1.2: access fault on message line update fixed
;			 1.0/1.2: exception vectors overwritten by graphs window
;			 CDTV: 960 KB Chip + 48 KB Fast (system structures only)
;			 floppy: ws_MemConfig removed, WHDLoad 17+
;  :Requires.	kick13.s
;		floppy Slave: WHDLoad 17+, CDTV Slave: WHDLoad 21+
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, vasm
;  :To Do.
;---------------------------------------------------------------------------*

; build:
;   SimCity.Slave	floppy versions 512K, 1.0, 1.2
;   SimCityCDTV.Slave	CDTV version, assembled with CDTV defined
;
;   version  SPS            volume       executable                CRC16
;   512K     888 1870 2192  SimCity512K  SimCity 184220 23.10.1989 $9c4b
;					 identical on all three disks
;   1.2      2193           SimCity1.2   SimCity 139380 23.10.1989 $d38f
;   1.2      1953           SimCity1.2   SimCity 139324 22.05.1990 $84a4
;   1.0      1992           SimCity 1.0  SimCity 137304            $6391
;					 encrypted with HLS (Ben Herndon)
;   CDTV     -              SIM_CITY     Sim     117128 "SIM CDTV 1.11" $eaf5
; not part of the install: Graphics Set 1 Ancient Cities (SPS 1993),
; Graphics Set 2 Future Cities (SPS 1987), Terrain Editor (SPS 1954)
;
; the version is detected via the CRC16 of the first 300 bytes of the
; executable, the patches are applied via resload_PatchSeg
;
; floppy versions: the manual check (protection routine) is skipped, the
; 'passed' flag is $047c(a4) (512K) or $2fce(a4) (1.2)
;   version 1.0 is encrypted with HLS, it gets decrypted by the Slave without
;   executing the protection code (see _hls), there is no manual check
;   Custom1 starts PrintCity instead of the game (only on the 512K disks),
;   it loads cities and prints them via printer.device, no patches required
;
; CDTV version:
;   the language is set via WHDLTAG_LANG_GET instead of reading it from the
;   bookmark.device
;   the memory card is accessed directly at $e00000 (access fault), the
;   detection is patched to report no card, cities can be saved via the
;   disk option instead (DF0:C1.CTY..C6.CTY, assigned to the data directory)
;   INIT_CDDEVICE adds a cdtv.device (whdload/cddevice.s) which plays the CD
;   audio tracks via resload_Audio, all commands sent to it are written to
;   the WHDLoad log (option FileLog)

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	IFD CDTV
	OUTPUT	"wart:sh/simcity/SimCityCDTV.Slave"
	ELSE
	OUTPUT	"wart:sh/simcity/SimCity.Slave"
	ENDC
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimize warnings
	SUPER
	ENDC

;============================================================================

	IFD CDTV
CHIPMEMSIZE	= $f0000	;size of chip memory, CDTV has 1 MB Chip, 64 KB less are sufficient
FASTMEMSIZE	= $c000		;size of fast memory, the code hunk of the exe ($1a0b0) contains graphics data and must
				;be loaded into Chip, so it must not fit into Fast, only system structures are placed here
	ELSE
CHIPMEMSIZE	= $80000	;size of chip memory
FASTMEMSIZE	= $80000	;size of fast memory
	ENDC
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %1111		;write protection of floppy drives

	IFD CDTV
BLACKSCREEN			;set all initial colors to black
	ENDC
;BOOTBLOCK			;enable _bootblock routine
BOOTDOS				;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
;CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
CACHE				;enable inst/data cache for fast memory with MMU
;CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
	IFD CDTV
INIT_CDDEVICE			;add cdtv.device, CD audio via resload_Audio
	ENDC
;DISKSONBOOT			;insert disks in floppy drives
DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;IOCACHE	= 1024		;cache for the filesystem handler (per fh)
;MEMFREE	= $200		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
;POINTERTICKS	= 1		;set mouse speed
;SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
SETPATCH			;enable patches from SetPatch 1.38
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

	IFD CDTV
slv_Version	= 21		;resload_Audio
	ELSE
slv_Version	= 17		;ws_config
	ENDC
slv_Flags	= WHDLF_NoError
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
	IFD CDTV
slv_name	dc.b	"Sim City CDTV",0
slv_copy	dc.b	"1991 Maxis/Infogrames",0
	ELSE
slv_name	dc.b	"Sim City",0
slv_copy	dc.b	"1989 Maxis/Infogrames",0
	ENDC
slv_info	dc.b	"installed and fixed by Galahad, Wepl",10
		dc.b	"Version 2.0 "
		INCBIN	.date
		dc.b	0
	IFD CDTV
slv_config	= slv_base
slv_MemConfig	= slv_base
_program	dc.b	"Sim",0
	ELSE
slv_config	dc.b	"C1:B:start PrintCity instead of the game (512K only)",0
_program	dc.b	"SimCity",0
_printcity	dc.b	"PrintCity",0
_noprintcity	dc.b	"PrintCity is only available in the 512K version.",0
	ENDC
_args		dc.b	10
_args_end	dc.b	0

	;volume names used by the different versions
_assign		dc.b	"DF0",0
	IFD CDTV
		dc.b	"SIM_CITY",0
	ELSE
		dc.b	"SimCity512K",0
		dc.b	"SimCity1.2",0
		dc.b	"SimCity 1.0",0
	ENDC
		dc.b	0
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	(_assign,pc),a3
.assign		move.l	a3,a0
		sub.l	a1,a1
		bsr	_dos_assign
.assignnext	tst.b	(a3)+
		bne	.assignnext
		tst.b	(a3)
		bne	.assign

	IFND CDTV
	;set the current directory, it is 0 (root of the boot volume) for the
	;initial CLI, the original is started from the workbench which sets a
	;real lock, the game writes the icon of a saved city via
	;DupLock(pr_CurrentDir) and fails with 'Unable to write:' for lock 0
		lea	(_args_end,pc),a0	;empty string
		move.l	a0,d1
		moveq	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		jsr	(_LVOCurrentDir,a6)
	ENDC

	;load program
		lea	(_program,pc),a5	;A5 = program name
		moveq	#0,d6			;D6 = 1 for version 1.0 (HLS)

	;get tags
		lea	(_slv_tags,pc),a0
		jsr	(resload_Control,a2)

	IFND CDTV
	;Custom1 starts PrintCity (512K only), no patches required
		move.l	(_custom1,pc),d0
		beq	.game
		lea	(_printcity,pc),a5
		move.l	a5,a0
		jsr	(resload_GetFileSize,a2)
		sub.l	a3,a3			;no patch list
		tst.l	d0
		bne	.load
		pea	(_noprintcity,pc)
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a2)
.game
	ENDC

	;check version
		move.l	a5,a0			;name
		move.l	#300,d3			;length
		move.l	d3,d0
		moveq	#0,d1			;offset
		sub.l	d3,a7
		move.l	a7,a1			;buffer
		jsr	(resload_LoadFileOffset,a2)
		move.l	d3,d0
		move.l	a7,a0
		jsr	(resload_CRC16,a2)
		add.l	d3,a7
	IFD CDTV
		lea	(_pl_cdtv,pc),a3
		cmp.w	#$eaf5,d0		;SIM CDTV 1.11
		beq	.versionok
	ELSE
		lea	(_pl_512k,pc),a3
		cmp.w	#$9c4b,d0		;512K SPS 888/1870/2192
		beq	.versionok
		lea	(_pl_12_2193,pc),a3
		cmp.w	#$d38f,d0		;1.2 SPS 2193
		beq	.versionok
		lea	(_pl_12_1953,pc),a3
		cmp.w	#$84a4,d0		;1.2 SPS 1953
		beq	.versionok
		lea	(_pl_10,pc),a3
		moveq	#1,d6
		cmp.w	#$6391,d0		;1.0 SPS 1992, HLS encrypted
		beq	.versionok
	ENDC
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
.load		move.l	a5,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	IFD CDTV
	;set language in patch list
		lea	(_pl_cdtv_lang,pc),a0
		move.w	(_lang+2,pc),(a0)
	ELSE
	;remove HLS protection
		tst.l	d6
		beq	.nohls
		bsr	_hls
		jsr	(resload_FlushCache,a2)
.nohls
	ENDC

	;patch
		move.l	a3,d0
		beq	.nopatch
		move.l	a3,a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)
.nopatch

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call, the stack must look like on a CLI start: (a7) = return address,
	;4(a7) = stack size, the Aztec C startup of the 1.x versions uses it to
	;place the 'MANX' stack check mark at the bottom of the stack
		move.l	(4,a7),d2		;stack size given to _bootdos
		subq.l	#8,d2			;minus stack size + return address
		move.l	d2,-(a7)
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		lsl.l	#2,d7
		move.l	d7,a3
		jsr	(4,a3)
		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.program_err	jsr	(_LVOIoErr,a6)
		move.l	a5,-(a7)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

;============================================================================

	IFD CDTV

; the bookmark.device is only used to read the language (word at offset 4 of
; the bookmark, LANG_* like lowlevel.library), so the language is taken from
; WHDLoad instead, the program itself maps values > 10 to 0 and falls back to
; english if there are no files for the language
; the cleanup skips CloseDevice because io_Device is 0 and frees the
; IORequest and MsgPort created before, the 3 arguments for OpenDevice already
; pushed stay on the stack, the routine ends with unlk a5

_pl_cdtv	PL_START
		PL_DATA	$17fce,8		;pea (bookmark.device,pc)
						;jsr (OpenDevice,pc)
		dc.w	$397c			;move.w #lang,($1474,a4)
_pl_cdtv_lang	dc.w	0
		dc.w	$1474
		dc.w	$602e			;bra.b $18004 (cleanup)
		PL_DATA	$184a8,4		;memory card detection, returns
		moveq	#0,d0			;the number of slots, 0 = no card
		rts
		PL_END

	CNOP	0,4
_slv_tags	dc.l	WHDLTAG_LANG_GET
_lang		dx.l	2

	ELSE

; manual check: the test of the 'passed' flag at the start of the protection
; routine is replaced by setting the flag to 2 ('passed') and a branch to the
; end of the routine, the initialization of the random generator via
; dos.DateStamp before the test is kept

_pl_512k	PL_START
		PL_DATA	$9b3e,10		;tst.w ($047c,a4) / bne.w $9e1e
		move.w	#2,($047c,a4)
		dc.w	$6000,$9e1e-$9b46	;bra.w $9e1e
		PL_PS	$7ba8,_title512
		PL_PS	$1450a,_seg512
		PL_END

_pl_12_2193	PL_START
		PL_DATA	$b214,14		;tst.w ($2fce,a4) / lea (14,a7),a7 / bne.w $b542
		move.w	#2,($2fce,a4)
		lea	(14,a7),a7
		dc.w	$6000,$b542-$b220	;bra.w $b542
		PL_PS	$965a,_title12
		PL_PS	$15d32,_seg12
		PL_PSS	$9826,_msgrp12,2
		PL_PSS	$9914,_msg12,2
		PL_PSS	$120fc,_graph12,2
		PL_END

_pl_12_1953	PL_START
		PL_DATA	$b208,14		;tst.w ($2fce,a4) / lea (14,a7),a7 / bne.w $b536
		move.w	#2,($2fce,a4)
		lea	(14,a7),a7
		dc.w	$6000,$b536-$b214	;bra.w $b536
		PL_PS	$965a,_title12
		PL_PS	$15cfc,_seg12
		PL_PSS	$9826,_msgrp1953,2
		PL_PSS	$9908,_msg1953,2
		PL_PSS	$120d8,_graph1953,2
		PL_END

_pl_10		PL_START
		PL_PS	$93bc,_title10
		PL_PS	$15a00,_seg12
		PL_PSS	$9558,_msgrp10,2
		PL_PSS	$9646,_msg10,2
		PL_PSS	$1189e,_graph10,2
		PL_END

; the update of the window title (city name, date) is called after creating a
; new city (terraforming) before the pointer to the structure containing the
; window has been set, it then uses the long at address 8 as window, on the
; original this is a pointer into the rom and the writes are ignored, here
; it is an access fault, so the update is skipped if the pointer is 0
; replaces the test of the 'no title' flag at the start of the routine, the
; following bne skips the update
; OUT:	ccr Z = 0 skip update

_title512	btst	#6,($03ca,a4)		;original
		bne	.end
		tst.l	($0408,a4)		;structure containing the window
		eor.b	#4,ccr			;invert Z
.end		rts

; the update of the message line may be called before the window is open,
; then the rastport pointer is 0 and the text is drawn into a rastport at
; address 0, this overwrites the exception vectors $10..$2f and the next
; Supervisor call of exec crashes, so the whole update is skipped if the
; rastport is 0
; replaces 'link a5,#-4 / move.w #1,-(a7)' at the start of the routine

_msgrp10	tst.l	($34be,a4)
		bra	_msgrp
_msgrp12	tst.l	($456a,a4)
		bra	_msgrp
_msgrp1953	tst.l	($456c,a4)
_msgrp		bne	.ok
		addq.l	#4,a7			;return from the routine
		rts

.ok		move.l	(a7)+,a0		;return address
		link	a5,#-4			;original
		move.w	#1,-(a7)		;original
		jmp	(a0)

; the graphs process draws the legend of the graph window with the rastport
; of its structure before it is set, this overwrites the exception vectors
; $10..$2f like above, so the drawing is skipped if the rastport is 0
; replaces 'link a5,#-22 / movem.l d4-d5/a2,-(a7)' at the start of the routine

_graph10	tst.l	($358a,a4)
		bra	_graph
_graph12	tst.l	($463c,a4)
		bra	_graph
_graph1953	tst.l	($463e,a4)
_graph		bne	.ok
		addq.l	#4,a7			;return from the routine
		rts

.ok		move.l	(a7)+,a0		;return address
		link	a5,#-22			;original
		movem.l	d4-d5/a2,-(a7)		;original
		jmp	(a0)

; the update of the message line refreshes a gadget from a structure which
; may not be allocated yet, the pointer is 0 and the gadget at $348 is used,
; on the original this is low memory, here it is $cccccccc and RefreshGList
; crashes, so the refresh is skipped if the pointer is 0
; replaces 'move.l (x,a4),a0 / pea ($348,a0)' before RefreshGList, the
; arguments window/requester/count are already on the stack, the routine
; ends after the call with 'lea (16,a7),a7 / unlk a5 / rts'

_msg10		move.l	($34aa,a4),d0
		bra	_msg
_msg12		move.l	($4552,a4),d0
		bra	_msg
_msg1953	move.l	($4554,a4),d0
_msg		beq	.skip
		move.l	d0,a0
		move.l	(a7)+,d0		;return address
		pea	($348,a0)		;original, gadget
		move.l	d0,-(a7)
		rts

.skip		lea	(4+12,a7),a7		;return address and arguments
		unlk	a5
		rts

; the game starts the simulation (512K) or the maps and graphs windows (1.x)
; as separate processes, the segment for CreateProc is built in allocated
; memory (jmp to the entry), without a cache flush the cpu executes stale
; data from the instruction cache if the memory is in fast memory

_seg512		move.l	(-8,a5),(10,a2)		;original, entry as jmp target
		bra	_flush

_seg12		move.l	(12,a5),(10,a3)		;original, entry as jmp target

_flush		move.l	a0,-(a7)
		move.l	(_resload,pc),a0
		jsr	(resload_FlushCache,a0)
		move.l	(a7)+,a0
		rts

_title12	btst	#6,($447c,a4)		;original
		bne	.end
		tst.l	($0b44,a4)		;structure containing the window
		eor.b	#4,ccr			;invert Z
.end		rts

_title10	btst	#6,($33d6,a4)		;original
		bne	.end
		tst.l	(-$07cc,a4)		;structure containing the window
		eor.b	#4,ccr			;invert Z
.end		rts

;============================================================================
; version 1.0: remove the HLS protection (Ben Herndon)
; the executable contains two nested HLS stubs (at $188b0 and $182f0), each
; decrypts itself in 2 stages and then the program in a 3rd stage, the key
; for stage 3 depends on a measurement of a protection track, the map of the
; encrypted blocks is read from block 17/20 of the disk
; here all stages are performed directly with the fixed keys, the stub code
; itself is never executed, the decryption does not depend on the load
; address (no relocations inside the stubs)
; IN:	D7 = BPTR  segment list
; OUT:	-

_hls		movem.l	d0-d3/a0-a5,-(a7)
		move.l	d7,d0
		lsl.l	#2,d0
		addq.l	#4,d0
		move.l	d0,a5			;A5 = hunk 0
		lea	(_hls_pass1,pc),a4
		bsr	.pass
		lea	(_hls_pass2,pc),a4
		bsr	.pass
		movem.l	(a7)+,d0-d3/a0-a5
		rts

; A4 = pass parameters, A5 = hunk 0

.pass		move.l	a5,a3
		add.l	(a4),a3			;A3 = stub

	;stage 1, the 1st dbf uses the displacement prefetched by the 68000
	;and executes the code at stub+$528 once
		lea	(-$20,a3),a0		;key words
		lea	($1a,a3),a1		;encrypted code
		move.w	#$285,d3
		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		subq.w	#1,d3
		move.l	a0,a2
		moveq	#14,d1
.s1not		not.w	(a2)+
		dbf	d1,.s1not
		move.w	#$5369,-(a0)
		moveq	#30,d1
.s1a		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		subq.w	#1,d3
		dbf	d1,.s1a
.s1b		move.w	(a0)+,d0
		eor.w	d0,(a1)+
		dbf	d3,.s1b

	;stage 2, key is a checksum over the stub
		lea	($24e,a3),a0
		move.w	(4,a4),d0
		move.w	#$16a,d2
.s2		move.w	(a0)+,d1
		add.w	d0,d1
		eor.w	d1,(a0)
		dbf	d2,.s2

	;stage 3, decrypt the program blocks of the map
		move.w	(6,a4),d2		;key
		move.l	a4,a2
		add.w	(8,a4),a2		;map
.s3entry	moveq	#0,d0
		move.w	(a2)+,d0		;offset in words
		move.w	(a2)+,d3		;count
		beq	.s3end
		move.l	a5,a0
		add.l	d0,a0
		add.l	d0,a0
		lea	(-$20,a3),a1		;key bytes
		subq.w	#2,d3
.s3		move.w	(a0)+,d0
		move.b	(a1)+,d1
		eor.w	d2,d0
		eor.b	d1,d0
		eor.w	d0,(a0)
		dbf	d3,.s3
		bra	.s3entry
.s3end
	;restore the original code at the program start
		lea	($572,a3),a0
.rest		moveq	#0,d1
		move.w	(a0)+,d0		;count
		beq	.restend
		move.w	(a0)+,d1		;offset in words
		move.l	a5,a1
		add.l	d1,a1
		add.l	d1,a1
		subq.w	#1,d0
.restw		move.w	(a0)+,(a1)+
		dbf	d0,.restw
		bra	.rest
.restend	rts

; parameters: stub offset, key stage 2, key stage 3, map

_hls_pass1	dc.l	$188b0
		dc.w	$2d20,$3f3c
		dc.w	_hls_map17-_hls_pass1
_hls_pass2	dc.l	$182f0
		dc.w	$b4e0,$c600
		dc.w	_hls_map20-_hls_pass2

_hls_map17	;block 17 of the disk, 61 entries: offset (words), count
		dc.w	$3,$590,$593,$590,$b23,$590,$10b3,$590
		dc.w	$1643,$590,$1bd3,$590,$2163,$590,$26f3,$590
		dc.w	$2c83,$590,$3213,$590,$37a3,$590,$3d33,$590
		dc.w	$42c3,$590,$4853,$590,$4de3,$590,$5373,$590
		dc.w	$5903,$590,$5e93,$590,$6423,$590,$69b3,$590
		dc.w	$6f43,$590,$74d3,$590,$7a63,$590,$7ff3,$25a
		dc.w	$824f,$5,$8256,$8,$8260,$8,$826a,$b
		dc.w	$8277,$590,$8807,$590,$8d97,$289,$9040,$fe
		dc.w	$9140,$24,$9166,$47,$91af,$1e,$91cf,$36
		dc.w	$9207,$1a,$9223,$8,$922d,$22,$925d,$8
		dc.w	$9278,$a,$9284,$5,$92bd,$5,$92e5,$a
		dc.w	$92f1,$15,$9313,$12,$932a,$a,$933a,$6
		dc.w	$9356,$8,$9360,$c,$936e,$8,$9378,$590
		dc.w	$9908,$590,$9e98,$590,$a428,$590,$a9b8,$590
		dc.w	$af48,$576,$b4c0,$590,$ba50,$590,$bfe0,$454
		dc.w	$c436,$12,$0,$0
_hls_map20	;block 20 of the disk, 60 entries: offset (words), count
		dc.w	$3,$590,$593,$590,$b23,$590,$10b3,$590
		dc.w	$1643,$590,$1bd3,$590,$2163,$590,$26f3,$590
		dc.w	$2c83,$590,$3213,$590,$37a3,$590,$3d33,$590
		dc.w	$42c3,$590,$4853,$590,$4de3,$590,$5373,$590
		dc.w	$5903,$590,$5e93,$590,$6423,$590,$69b3,$590
		dc.w	$6f43,$590,$74d3,$590,$7a63,$590,$7ff3,$25a
		dc.w	$824f,$5,$8256,$8,$8260,$8,$826a,$b
		dc.w	$8277,$590,$8807,$590,$8d97,$289,$9040,$fe
		dc.w	$9140,$24,$9166,$47,$91af,$1e,$91cf,$36
		dc.w	$9207,$1a,$9223,$8,$922d,$22,$925d,$8
		dc.w	$9278,$a,$9284,$5,$92bd,$5,$92e5,$a
		dc.w	$92f1,$15,$9313,$12,$932a,$a,$933a,$6
		dc.w	$9356,$8,$9360,$c,$936e,$8,$9378,$590
		dc.w	$9908,$590,$9e98,$590,$a428,$590,$a9b8,$590
		dc.w	$af48,$576,$b4c0,$590,$ba50,$590,$bfe0,$188
		dc.w	$0,$0

	CNOP	0,4
_slv_tags	dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dx.l	2

	ENDC

;============================================================================

	END
