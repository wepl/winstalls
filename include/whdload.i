;*---------------------------------------------------------------------------
;  :Module.	whdload.i
;  :Contens.	include file for WHDLoad and his Slaves
;  :Author.	Bert Jahn
;  :EMail.	wepl@kagi.com
;  :Address.	Franz-Liszt-Straße 16, Rudolstadt, 07404, Germany
;  :Version.	$Id: whdload.i 9.0 1999/01/17 14:06:48 jah Exp jah $
;  :History.
;  :Copyright.	© 1996,1997,1998 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;---------------------------------------------------------------------------*

 IFND WHDLOAD_I
WHDLOAD_I=1

	IFND	EXEC_EXECBASE_I
	INCLUDE	exec/execbase.i
	ENDC
	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC
	IFND	GRAPHICS_MODEID_I
	INCLUDE	graphics/modeid.i
	ENDC
	IFND	HARDWARE_CIA_I
	INCLUDE	hardware/cia.i
	ENDC
	IFND	HARDWARE_CUSTOM_I
	INCLUDE	hardware/custom.i
	ENDC
	IFND	HARDWARE_INTBITS_I
	INCLUDE	hardware/intbits.i
	ENDC
	IFND	HARDWARE_DMABITS_I
	INCLUDE	hardware/dmabits.i
	ENDC
	IFND	UTILITY_TAGITEM_I
	INCLUDE	utility/tagitem.i
	ENDC

;some custom stuff

 BITDEF POTGO,OUTRY,15
 BITDEF POTGO,DATRY,14
 BITDEF POTGO,OUTRX,13
 BITDEF POTGO,DATRX,12
 BITDEF POTGO,OUTLY,11
 BITDEF POTGO,DATLY,10
 BITDEF POTGO,OUTLX,9
 BITDEF POTGO,DATLX,8
 BITDEF POTGO,START,0

_ciaa		= $bfe001
_ciab		= $bfd000
_custom		= $dff000

;=============================================================================
;	misc
;=============================================================================

SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"WHDLOADS"
		ENDM

;=============================================================================
;	some useful macros
;=============================================================================
****************************************************************
***** write opcode ILLEGAL to specified address
ill	MACRO
	IFNE	NARG-1
		FAIL	arguments "ill"
	ENDC
		move.w	#$4afc,\1
	ENDM
****************************************************************
***** write opcode RTS to specified address
ret	MACRO
	IFNE	NARG-1
		FAIL	arguments "ret"
	ENDC
		move.w	#$4e75,\1
	ENDM
****************************************************************
***** skip \1 instruction bytes on address \2
skip	MACRO
	IFNE	NARG-2
		FAIL	arguments "skip"
	ENDC
	IFLE \1-126
		move.w	#$6000+\1-2,\2
	ELSE
	IFLE \1-32766
		move.l	#$60000000+\1-2,\2
	ELSE
		FAIL	"skip: distance to large"
	ENDC
	ENDC
	ENDM
****************************************************************
***** write \1 times opcode NOP starting at address \2
***** (better to use "skip" instead)
nops	MACRO
	IFNE	NARG-2
		FAIL	arguments "nops"
	ENDC
		movem.l	d0/a0,-(a7)
		IFGT \1-127
			move.w	#\1-1,d0
		ELSE
			moveq	#\1-1,d0
		ENDC
		lea	\2,a0
.lp\@		move.w	#$4e71,(a0)+
		dbf	d0,.lp\@
		movem.l	(a7)+,d0/a0
	ENDM
****************************************************************
***** write opcode JMP \2 to address \1
patch	MACRO
	IFNE	NARG-2
		FAIL	arguments "patch"
	ENDC
		move.w	#$4ef9,\1
		pea	\2
		move.l	(a7)+,2+\1
	ENDM
****************************************************************
***** write opcode JSR \2 to address \1
patchs	MACRO
	IFNE	NARG-2
		FAIL	arguments "patchs"
	ENDC
		move.w	#$4eb9,\1
		pea	\2
		move.l	(a7)+,2+\1
	ENDM
****************************************************************
***** wait that blitter has finished his job
***** (this is adapted from graphics.WaitBlit, see autodocs for
*****  hardware bugs and possible problems ...)
***** if \1 is given it must be an address register containing _custom
BLITWAIT MACRO
	IFEQ	NARG-1
		tst.b	(dmaconr,\1)
.waitb\@	tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)
		btst	#DMAB_BLTDONE-8,(dmaconr,\1)
		bne.b	.waitb\@
		tst.b	(dmaconr,\1)
	ELSE
		tst.b	(_custom+dmaconr)
.waitb\@	tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		bne.b	.waitb\@
		tst.b	(_custom+dmaconr)
	ENDC
	ENDM
****************************************************************
***** wait of vertical blank
***** if \1 is given it must be an address register containing _custom
waitvb	MACRO
	IFEQ	NARG-1
.1\@		btst	#0,(vposr+1,\1)
		beq	.1\@
.2\@		btst	#0,(vposr+1,\1)
		bne	.2\@
	ELSE
.1\@		btst	#0,(_custom+vposr+1)
		beq	.1\@
.2\@		btst	#0,(_custom+vposr+1)
		bne	.2\@
	ENDC
	ENDM
****************************************************************
***** wait for pressing any button
***** if \1 is given it must be an address register containing _custom
waitbutton	MACRO
	IFEQ	NARG
		move.l	a0,-(a7)
		lea	(_custom),a0
.down\@		bsr	.wait\@
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	.down\@
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	a0
		rts
.done\@		move.l	(a7)+,a0
	ELSE
	IFEQ	NARG-1
.down\@		bsr	.wait\@
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		bne	.down\@
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	\1
		rts
.done\@
	ELSE
		FAIL	arguments "waitbutton"
	ENDC
	ENDC
	ENDM

waitbuttonup	MACRO
	IFEQ	NARG
		move.l	a0,-(a7)
		lea	(_custom),a0
.up\@		bsr	.wait\@					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,a0)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		bsr	.wait\@					;entprellen
		bra	.done\@
.wait\@		waitvb	a0
		rts
.done\@		move.l	(a7)+,a0
	ELSE
	IFEQ	NARG-1
.up\@		waitvb	\1					;entprellen
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)		;LMB
		beq	.up\@
		btst	#POTGOB_DATLY-8,(potinp,\1)		;RMB
		beq	.up\@
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)		;FIRE
		beq	.up\@
		waitvb	\1					;entprellen
	ELSE
		FAIL	arguments "waitbuttonup"
	ENDC
	ENDC
	ENDM
****************************************************************
***** flash the screen and wait for LMB
blitz		MACRO
		move	#$1200,bplcon0+_custom
	;	move	#DMAF_SETCLR|DMAF_RASTER,dmacon+_custom
		move.l	d0,-(a7)
.lpbl\@		move.w	d0,$dff180
		subq.w	#1,d0
		btst	#6,$bfe001
		bne	.lpbl\@
		waitvb					;entprellen
		waitvb					;entprellen
.lp2bl\@	move.w	d0,$dff180
		subq.w	#1,d0
		btst	#6,$bfe001
		beq	.lp2bl\@
		waitvb					;entprellen
		waitvb					;entprellen
		clr.w	color+_custom
		move.l	(a7)+,d0
		ENDM
****************************************************************
***** color the screen and wait for LMB
bwait		MACRO
		move	#$1200,bplcon0+_custom
.wd\@
	IFEQ NARG
		move.w	#$ff0,color+_custom		;yellow
	ELSE
		move.w	#\1,color+_custom
	ENDC
		btst	#6,$bfe001
		bne	.wd\@
		waitvb					;entprellen
		waitvb					;entprellen
.wu\@		btst	#6,$bfe001
		beq	.wu\@
		waitvb					;entprellen
		waitvb					;entprellen
		clr.w	color+_custom
		ENDM
****************************************************************
***** install Vertical-Blank-Interrupt which quits on LMB pressed
QUITVBI		MACRO
		move.l	a0,-(a7)
		lea	.vbi,a0
		move.l	a0,$6c
		bra	.g
.vbi		btst	#6,$bfe001
		beq	.vbi+1		;create "address error"
		move.w	#INTF_VERTB,_custom+intreq
		rte
.g		move.w	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,_custom+intena
		move.w	#INTF_VERTB,_custom+intreq
		move.l	(a7)+,a0
	ENDM
****************************************************************
***** set all registers to zero
resetregs	MACRO
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		sub.l	a0,a0
		sub.l	a1,a1
		sub.l	a2,a2
		sub.l	a3,a3
		sub.l	a4,a4
		sub.l	a5,a5
		sub.l	a6,a6
	ENDM
;=============================================================================
;	return-values for termination (resload_Abort)
;=============================================================================

TDREASON_OK		= -1	;normal termination
TDREASON_DOSREAD	= 1	;error with resload_ReadFile
				;primary   = dos errorcode
				;secondary = file name
TDREASON_DOSWRITE	= 2	;error with resload_SaveFile/resload_SaveFileOffset
				;primary   = dos errorcode
				;secondary = file name
TDREASON_DEBUG		= 5	;make coredump and quit
				;primary   = PC
				;secondary = SR
TDREASON_DOSLIST	= 6	;error with resload_ListFiles
				;primary   = dos errorcode
				;secondary = directory name
TDREASON_DISKLOAD	= 7	;error with resload_DiskLoad
				;primary   = dos errorcode
				;secondary = disk number
TDREASON_DISKLOADDEV	= 8	;error with resload_DiskLoadDev
				;primary   = trackdisk errorcode
TDREASON_WRONGVER	= 9	;an version check (e.g. crc16) has detected an
				;unsupported version of data files
TDREASON_OSEMUFAIL	= 10	;error in the OS emulation module
				;primary   = subsystem (e.g. "exec.library")
				;secondary = error number (e.g. #_LVOAllocMem)
; version 7
TDREASON_REQ68020	= 11	;Slave/installed program requires 68020
TDREASON_REQAGA		= 12	;Slave/installed program requires AGA Chip Set
TDREASON_MUSTNTSC	= 13	;installed program needs NTSC to run
TDREASON_MUSTPAL	= 14	;installed program needs PAL to run
; version 8
TDREASON_MUSTREG	= 15	;whdload must be registered
TDREASON_DELETEFILE	= 27	;error with resload_DeleteFile
				;primary   = dos errorcode
				;secondary = file name

;=============================================================================
; tagitems for various resload functions
;=============================================================================

 ENUM	TAG_USER+$8000000
 EITEM	WHDLTAG_ATTNFLAGS_GET	;get exec.AttnFlags
 				;(see "Includes:exec/execbase.i")
 EITEM	WHDLTAG_ECLOCKFREQ_GET	;get exec.EClockFrequency
 				;(see "Includes:exec/execbase.i")
 EITEM	WHDLTAG_MONITOR_GET	;get the used monitor (NTSC_MONITOR_ID or PAL_MONITOR_ID)
 EITEM	WHDLTAG_Private1
 EITEM	WHDLTAG_Private2
 EITEM	WHDLTAG_Private3
 EITEM	WHDLTAG_BUTTONWAIT_GET	;get value of argument/tooltype ButtonWait/S (0/-1)
 EITEM	WHDLTAG_CUSTOM1_GET	;get value of argument/tooltype Custom1/N (integer)
 EITEM	WHDLTAG_CUSTOM2_GET	;get value of argument/tooltype Custom2/N (integer)
 EITEM	WHDLTAG_CUSTOM3_GET	;get value of argument/tooltype Custom3/N (integer)
 EITEM	WHDLTAG_CUSTOM4_GET	;get value of argument/tooltype Custom4/N (integer)
 EITEM	WHDLTAG_CUSTOM5_GET	;get value of argument/tooltype Custom5/N (integer)
; version 7
 EITEM	WHDLTAG_CBSWITCH_SET	;set callback function to execute on switch to
				;installed program (see autodoc)
 EITEM	WHDLTAG_CHIPREVBITS_GET	;get gfx.ChipRevBits
				;(see "Includes:graphics/gfxbase.i")
; version 8
 EITEM	WHDLTAG_IOERR_GET	;get dos error code from last resload function
 EITEM	WHDLTAG_Private4
; version 9
 EITEM	WHDLTAG_CBAF_SET	;set callback function to execute when access 
				;fault occurs (see autodoc)
 EITEM	WHDLTAG_VERSION_GET	;get WHDLoad version number (major)
 EITEM	WHDLTAG_REVISION_GET	;get WHDLoad revision number (minor)
 EITEM	WHDLTAG_BUILD_GET	;get WHDLoad build number
 EITEM	WHDLTAG_TIME_GET	;gets pointer to filled whdload_time structure

;=============================================================================
;	structure returned by WHDLTAG_TIME_GET
;=============================================================================

	STRUCTURE whdload_time,0
		ULONG	whdlt_days	;days since 1.1.1978
		ULONG	whdlt_mins	;minutes since last day
		ULONG	whdlt_ticks	;1/50 seconds since last minute
		UBYTE	whdlt_year	;78..77 (1978..2077)
		UBYTE	whdlt_month	;1..12
		UBYTE	whdlt_day	;1..31
		UBYTE	whdlt_hour	;0..23
		UBYTE	whdlt_min	;0..59
		UBYTE	whdlt_sec	;0..59
		LABEL	whdlt_SIZEOF

;=============================================================================
; Slave		Version 1..3
;=============================================================================

    STRUCTURE	WhdloadSlave,0
	STRUCT	ws_Security,4	;moveq #-1,d0 + rts
	STRUCT	ws_ID,8		;"WHDLOADS"
	UWORD	ws_Version	;version of Whdload that is required
	UWORD	ws_Flags	;see below
	ULONG	ws_BaseMemSize	;size of mem required by game
				;(must be multiple of $1000, max=$200000)
	ULONG	ws_ExecInstall	;address in BaseMem where is space for a fake
				;ExecLibrary installed by the WHDLoad to
				;survive a RESET
				;for example $400
				;required are at least 84 Bytes
				;=0 means unsupported
	RPTR	ws_GameLoader	;start of slave-code
				;will called from WHDLoad after init in
				;SuperVisor
				;slave must be 100.00% PC-RELATIVE !
	RPTR	ws_CurrentDir	;subdirectory in which WHDLoad should search
				;for files
	RPTR	ws_DontCache	;pattern string for files which must not cached
				;starting WHDLoad 0.107 this is obsolete

;=============================================================================
; additional	Version 4..7
;=============================================================================

	UBYTE	ws_keydebug	;raw key code to quit with debug
				;works only if vbr is moved !
				;=0 means no key
	UBYTE	ws_keyexit	;raw key code to exit
				;works only if vbr is moved !
				;=0 means no key

;=============================================================================
; additional	Version 8
;=============================================================================

	ULONG	ws_ExpMem	;size of required expansions memory, during
				;initialisation will be overwritten by WHDLoad
				;with address of the memory
	LABEL	ws_SIZEOF

;=============================================================================
; Flags for ws_Flags
;=============================================================================

	BITDEF WHDL,Disk,0	;means diskimages are used by the slave
				;result is a different PRELOAD
				;starting WHDLoad 0.107 this is obsolete
	BITDEF WHDL,NoError,1	;if enabled every error occuring in a
				;resload_#? function will immedately quit the
				;slave, and whdload will prompt an error
				;requester
	BITDEF WHDL,EmulTrap,2	;if set and the vbr is moved TRAP #0-15 are
				;emulated like the autovectors
	BITDEF WHDL,NoDivZero,3	;if set and the VBR is moved by WHDLoad, it
				;will not quit if a "Division by Zero"
				;exception occurs, a simple rte will performed
				;instead
; version 7
	BITDEF WHDL,Req68020,4	;indicates that the Slave/installed program
				;requires at least a MC68020 cpu
	BITDEF WHDL,ReqAGA,5	;indicates that the Slave/installed program
				;requires the AGA chipset
; version 8
	BITDEF WHDL,NoKbd,6	;says WHDLoad that it doesn't should get the
				;keycode from the keyboard in conjunction with
				;NoVBRMove, must be used if the installed
				;program checks the keyboard from the VBI
	BITDEF WHDL,EmulLineA,7	;if set and the vbr is moved Line-A
				;instructions (opcodes starting with %1010)
				;are emulated like the autovectors
; version 9
	BITDEF WHDL,EmulTrapV,8	;if set and the vbr is moved trap-v
				;instructions are emulated like the
				;autovectors

;=============================================================================
; resload_#? functions
; a JMP-tower in WHDLoad (similar to a library)
; base is given on startup via A0
;=============================================================================

    STRUCTURE	ResidentLoader,0
	ULONG	resload_Install		;(private)
	ULONG	resload_Abort
		; return to operating system
		; IN: (a7) = ULONG  success (one of TDREASON_xxx)
		;   (4,a7) = ULONG  primary error code
		;   (8,a7) = ULONG  secondary error code
		; OUT :	-
		; DANGER this routine must called via JMP ! (not JSR)
	ULONG	resload_LoadFile
		; load to BaseMem
		; IN :	a0 = CPTR   name of file
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success (size of file)
		;	d1 = ULONG  dos errcode (0 if all went ok)
	ULONG	resload_SaveFile
		; save from BaseMem
		; IN :	d0 = LONG   length to save
		;	a0 = CPTR   name of file
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errcode (0 if all went ok)
	ULONG	resload_SetCACR
		; sets the CACR (also ok with 68000's and from user-state)
		; IN :	d0 = ULONG  new cacr
		;	d1 = ULONG  mask (bits to change)
		; OUT :	d0 = ULONG  old cacr
	ULONG	resload_ListFiles
		; list files in dir to buffer
		; IN :	d0 = ULONG  buffer size (a1)
		;	a0 = CPTR   name of directory to scan (relative)
		;	a1 = APTR   buffer (MUST reside in Slave !!!)
		; OUT :	d0 = ULONG  amount of listed names
		;	d1 = ULONG  dos errcode (0 if all went ok)
	ULONG	resload_Decrunch
		; decrunch memory
		; IN :	a0 = APTR   source
		;	a1 = APTR   destination (can be equal to source)
		; OUT :	d0 = BOOL   success (size of file unpacked)
	ULONG	resload_LoadFileDecrunch
		; IN :	a0 = CPTR   name of file (anywhere)
		;	a1 = APTR   address (MUST inside BaseMem !!!)
		; OUT :	d0 = BOOL   success (size of file)
		;	d1 = ULONG  dos errcode (0 if all went ok)
	ULONG	resload_FlushCache
		; flush all caches
		; IN :	-
		; OUT :	-
	ULONG	resload_GetFileSize
		; IN :	a0 = CPTR   name of file
		; OUT :	d0 = LONG   size of file or 0 if does'nt exist
	ULONG	resload_DiskLoad
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	d2 = ULONG  disk number
		;	a0 = APTR   destination
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode (if failed)

******* the following functions require ws_Version >= 2

	ULONG	resload_DiskLoadDev
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	a0 = APTR   destination
		;	a1 = STRUCT taglist
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  trackdisk errorcode (if failed)

******* the following functions require ws_Version >= 3

	ULONG	resload_CRC16
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	d0 = UWORD  crc checksum

******* the following functions require ws_Version >= 5

	ULONG	resload_Control
		; IN :	a0 = STRUCT taglist
		; OUT :	d0 = BOOL   success
	ULONG	resload_SaveFileOffset
		; save from BaseMem
		; IN :	d0 = ULONG  length to save
		;	d1 = ULONG  offset
		;	a0 = CPTR   name of file
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errcode (if failed)

******* the following functions require ws_Version >= 6

	ULONG	resload_ProtectRead
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectReadWrite
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectWrite
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectRemove
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_LoadFileOffset
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	a0 = CPTR   name of file
		;	a1 = APTR   destination
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode (if failed)

******* the following functions require ws_Version >= 8

	ULONG	resload_Relocate
		; IN :	a0 = APTR   address of executable (source/destination)
		;	a1 = STRUCT taglist
		; OUT :	d0 = ULONG  size of relocated executable
	ULONG	resload_Delay
		; IN :	d0 = ULONG  time to wait in 1/10 seconds
		; OUT :	-
	ULONG	resload_DeleteFile
		; IN :	a0 = CPTR   name of file
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode (if failed)

	LABEL	resload_SIZEOF

******* compatibility for older slave sources:

resload_CheckFileExist = resload_GetFileSize

;=============================================================================

 ENDC
