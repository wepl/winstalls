;*---------------------------------------------------------------------------
;  :Module.	whdload.i
;  :Contens.	include file for WHDLoad and Slaves
;  :Author.	Bert Jahn
;  :EMail.	wepl@whdload.de
;  :Address.	Feodorstraße 8, Zwickau, 08058, Germany
;  :Version.	$Id: whdload.i 15.3 2003/06/03 06:38:08 wepl Exp wepl $
;  :History.	11.04.99 marcos moved to separate include file
;		08.05.99 resload_Patch added
;		09.03.00 new stuff for whdload v11
;		10.07.00 new stuff for whdload v12
;		25.11.00 new stuff for whdload v13
;		13.01.01 some comments spelling errors fixed
;		15.03.01 v14 stuff added
;		15.04.01 FAILMSG added
;		29.04.01 resload_Relocate tags added
;		09.12.01 v15 stuff added
;		20.08.02 WHDLTAG_ALIGN added
;		19.11.02 WHDLTAG_CHKCOPCON added
;		03.06.03 EmulDivZero added
;		16.06.03 new PL's added
;		18.07.03 EmulIllegal added
;  :Copyright.	© 1996-2002 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
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
	IFND	UTILITY_TAGITEM_I
	INCLUDE	utility/tagitem.i
	ENDC

;=============================================================================
;	misc
;=============================================================================

SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"WHDLOADS"
		ENDM

;=============================================================================
;	return-values for termination (resload_Abort)
;=============================================================================

TDREASON_OK		= -1	;normal termination
TDREASON_DOSREAD	= 1	;error caused by resload_ReadFile
				; primary   = dos errorcode
				; secondary = file name
TDREASON_DOSWRITE	= 2	;error caused by resload_SaveFile or
				;resload_SaveFileOffset
				; primary   = dos errorcode
				; secondary = file name
TDREASON_DEBUG		= 5	;cause WHDLoad to make a coredump and quit
				; primary   = PC (writing to dump files)
				; secondary = SR (writing to dump files)
TDREASON_DOSLIST	= 6	;error caused by resload_ListFiles
				; primary   = dos errorcode
				; secondary = directory name
TDREASON_DISKLOAD	= 7	;error caused by resload_DiskLoad
				; primary   = dos errorcode
				; secondary = disk number
TDREASON_DISKLOADDEV	= 8	;error caused by resload_DiskLoadDev
				; primary   = trackdisk errorcode
TDREASON_WRONGVER	= 9	;an version check (e.g. crc16) has detected an
				;unsupported version of the installed program
TDREASON_OSEMUFAIL	= 10	;error in the OS emulation module
				; primary   = subsystem (e.g. "exec.library")
				; secondary = error number (e.g. _LVOAllocMem)
; version 7
TDREASON_REQ68020	= 11	;installed program requires a MC68020
TDREASON_REQAGA		= 12	;installed program requires the AGA chip set
TDREASON_MUSTNTSC	= 13	;installed program needs NTSC videomode to run
TDREASON_MUSTPAL	= 14	;installed program needs PAL videomode to run
; version 8
TDREASON_MUSTREG	= 15	;WHDLoad must be registered
TDREASON_DELETEFILE	= 27	;error caused by resload_DeleteFile
				; primary   = dos errorcode
				; secondary = file name
; version 14.1
TDREASON_FAILMSG	= 43	;failure with variable message text
				; primary   = text

;=============================================================================
; tagitems for the resload_Control function
;=============================================================================

 ENUM	TAG_USER+$8000000
 EITEM	WHDLTAG_ATTNFLAGS_GET	;get info about current CPU/FPU/MMU
 EITEM	WHDLTAG_ECLOCKFREQ_GET	;get frequency custom chips operate on
 EITEM	WHDLTAG_MONITOR_GET	;get the used monitor/video mode
				;(NTSC_MONITOR_ID or PAL_MONITOR_ID)
 EITEM	WHDLTAG_Private1
 EITEM	WHDLTAG_Private2
 EITEM	WHDLTAG_Private3
 EITEM	WHDLTAG_BUTTONWAIT_GET	;get value of WHDLoad option ButtonWait/S (0/-1)
 EITEM	WHDLTAG_CUSTOM1_GET	;get value of WHDLoad option Custom1/N (integer)
 EITEM	WHDLTAG_CUSTOM2_GET	;get value of WHDLoad option Custom2/N (integer)
 EITEM	WHDLTAG_CUSTOM3_GET	;get value of WHDLoad option Custom3/N (integer)
 EITEM	WHDLTAG_CUSTOM4_GET	;get value of WHDLoad option Custom4/N (integer)
 EITEM	WHDLTAG_CUSTOM5_GET	;get value of WHDLoad option Custom5/N (integer)
; version 7
 EITEM	WHDLTAG_CBSWITCH_SET	;set a function to be executed during switch
				;from operating system to installed program
 EITEM	WHDLTAG_CHIPREVBITS_GET	;get info about current custom chip set
; version 8
 EITEM	WHDLTAG_IOERR_GET	;get last dos errorcode
 EITEM	WHDLTAG_Private4
; version 9
 EITEM	WHDLTAG_CBAF_SET	;set a function to be executed when an access
				;fault exception occurs
 EITEM	WHDLTAG_VERSION_GET	;get WHDLoad major version number
 EITEM	WHDLTAG_REVISION_GET	;get WHDLoad minor version number
 EITEM	WHDLTAG_BUILD_GET	;get WHDLoad build number
 EITEM	WHDLTAG_TIME_GET	;get current time and date
; version 11
 EITEM	WHDLTAG_BPLCON0_GET	;get system bplcon0
; version 12
 EITEM	WHDLTAG_KEYTRANS_GET	;get pointer to a 128 byte table to convert
				;rawkey's to ascii-chars
; version 13
 EITEM	WHDLTAG_CHKBLTWAIT	;enable/disable blitter wait check
 EITEM	WHDLTAG_CHKBLTSIZE	;enable/disable blitter size check
 EITEM	WHDLTAG_CHKBLTHOG	;enable/disable dmacon.blithog (bltpri) check
 EITEM	WHDLTAG_CHKCOLBST	;enable/disable bplcon0.color check
; version 14
 EITEM	WHDLTAG_LANG_GET	;GetLanguageSelection like lowlevel.library
; version 14.5
 EITEM	WHDLTAG_DBGADR_SET	;set debug base address
; version 15
 EITEM	WHDLTAG_DBGSEG_SET	;set debug base segment address (BPTR!)
; version 15.2
 EITEM	WHDLTAG_CHKCOPCON	;enable/disable copcon check
 EITEM	WHDLTAG_Private5	;allows setting WCPU_Base_CB using SetCPU

;=============================================================================
; tagitems for the resload_Relocate function
;=============================================================================

; version 14.1
 ENUM	TAG_USER+$8100000
 EITEM	WHDLTAG_CHIPPTR		;relocate MEMF_CHIP hunks to this address
 EITEM	WHDLTAG_FASTPTR		;relocate MEMF_FAST hunks to this address
; version 15.1
 EITEM	WHDLTAG_ALIGN		;round up hunk lengths to the given boundary

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

    STRUCTURE	WHDLoadSlave,0
	STRUCT	ws_Security,4
	STRUCT	ws_ID,8		;"WHDLOADS"
	UWORD	ws_Version	;required WHDLoad version
	UWORD	ws_Flags	;see below
	ULONG	ws_BaseMemSize	;size of required memory (multiple of $1000)
	ULONG	ws_ExecInstall	;must be 0
	RPTR	ws_GameLoader	;Slave code, called by WHDLoad
	RPTR	ws_CurrentDir	;subdirectory for data files
	RPTR	ws_DontCache	;pattern for files not to cache

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
; additional	Version 8..9
;=============================================================================

	ULONG	ws_ExpMem	;size of required expansions memory, during
				;initialisation overwritten by WHDLoad with
				;address of the memory (multiple of $1000)
				;if negative it is optional

;=============================================================================
; additional	Version 10..15
;=============================================================================

	RPTR	ws_name		;name of the installed program
	RPTR	ws_copy		;year and owner of the copyright
	RPTR	ws_info		;additional informations (author, version...)

;=============================================================================
; additional	Version 16
;=============================================================================

	RPTR	ws_kickname	;name of kickstart image
	ULONG	ws_kicksize	;size of kickstart image
	UWORD	ws_kickcrc	;crc16 of kickstart image
	LABEL	ws_SIZEOF

;=============================================================================
; Flags for ws_Flags
;=============================================================================

	BITDEF WHDL,Disk,0	;means diskimages are used by the Slave
				;starting WHDLoad 0.107 obsolete
	BITDEF WHDL,NoError,1	;forces WHDLoad to abort the installed program
				;if error during resload_#? function occurs
	BITDEF WHDL,EmulTrap,2	;forward "trap #n" exceptions to the handler
				;of the installed program
	BITDEF WHDL,NoDivZero,3	;ignore division by zero exceptions
; version 7
	BITDEF WHDL,Req68020,4	;abort if no MC68020 or better is available
	BITDEF WHDL,ReqAGA,5	;abort if no AGA chipset is available
; version 8
	BITDEF WHDL,NoKbd,6	;says WHDLoad that it doesn't should get the
				;keycode from the keyboard in conjunction with
				;NoVBRMove, must be used if the installed
				;program checks the keyboard from the VBI
	BITDEF WHDL,EmulLineA,7	;forward "line-a" exceptions to the handler
				;of the installed program
; version 9
	BITDEF WHDL,EmulTrapV,8	;forward "trapv" exceptions to the handler
				;of the installed program
; version 11
	BITDEF WHDL,EmulChk,9	;forward "chk, chk2" exceptions to the handler
				;of the installed program
	BITDEF WHDL,EmulPriv,10	;forward 'privilege violation' exceptions to
				;the handler of the installed program
; version 12
	BITDEF WHDL,EmulLineF,11 ;forward "line-f" exceptions to the handler
				;of the installed program
; version 13
	BITDEF WHDL,ClearMem,12	;initialize BaseMem and ExpMem with 0
; version 15
	BITDEF WHDL,Examine,13	;preload cache for Examine/ExNext
; version 16
	BITDEF WHDL,EmulDivZero,14 ;forward "division by zero" exceptions to
				;the handler of the installed program
	BITDEF WHDL,EmulIllegal,15 ;forward "illegal instruction" exceptions to
				;the handler of the installed program

;=============================================================================
; properties for resload_SetCPU
;=============================================================================

WCPUF_Base	= 3		;BaseMem mask
WCPUF_Base_NCS	= 0		;BaseMem = non cacheable serialized
WCPUF_Base_NC	= 1		;BaseMem = non cacheable
WCPUF_Base_WT	= 2		;BaseMem = cacheable write through
WCPUF_Base_CB	= 3		;BaseMem = cacheable copyback
WCPUF_Exp	= 12		;ExpMem mask
WCPUF_Exp_NCS	= 0		;ExpMem = non cacheable serialized
WCPUF_Exp_NC	= 4		;ExpMem = non cacheable
WCPUF_Exp_WT	= 8		;ExpMem = cacheable write through
WCPUF_Exp_CB	= 12		;ExpMem = cacheable copyback
WCPUF_Slave	= 48		;Slave mask
WCPUF_Slave_NCS	= 0		;Slave = non cacheable serialized
WCPUF_Slave_NC	= 16		;Slave = non cacheable
WCPUF_Slave_WT	= 32		;Slave = cacheable write through
WCPUF_Slave_CB	= 48		;Slave = cacheable copyback

	BITDEF WCPU,IC,8	;instruction cache (20-60)
	BITDEF WCPU,DC,9	;data cache (30-60)
	BITDEF WCPU,NWA,10	;disable write allocation (30)
	BITDEF WCPU,SB,11	;store buffer (60)
	BITDEF WCPU,BC,12	;branch cache (60)
	BITDEF WCPU,SS,13	;superscalar dispatch (60)
	BITDEF WCPU,FPU,14	;enable fpu (60)

WCPUF_All	= WCPUF_Base!WCPUF_Exp!WCPUF_Slave!WCPUF_IC!WCPUF_DC!WCPUF_NWA!WCPUF_SB!WCPUF_BC!WCPUF_SS!WCPUF_FPU

;=============================================================================
; resload_#? functions
; a JMP-tower inside WHDLoad (similar to a library)
; base is given on startup via A0
;=============================================================================

    STRUCTURE	ResidentLoader,0
	ULONG	resload_Install		;private
	ULONG	resload_Abort
		; return to operating system
		; IN: (a7) = ULONG  reason for aborting
		;   (4,a7) = ULONG  primary error code
		;   (8,a7) = ULONG  secondary error code
		; ATTENTION this routine must called via JMP! (not JSR)
	ULONG	resload_LoadFile
		; load file to memory
		; IN :	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = ULONG  success (size of file)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_SaveFile
		; write memory to file
		; IN :	d0 = ULONG  size
		;	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode
	ULONG	resload_SetCACR
		; set cachebility for BaseMem
		; IN :	d0 = ULONG  new setup
		;	d1 = ULONG  mask
		; OUT :	d0 = ULONG  old setup
	ULONG	resload_ListFiles
		; list filenames of directory
		; IN :	d0 = ULONG  buffer size
		;	a0 = CSTR   name of directory to scan
		;	a1 = APTR   buffer (must be located in Slave)
		; OUT :	d0 = ULONG  amount of names in buffer
		;	d1 = ULONG  dos errorcode
	ULONG	resload_Decrunch
		; uncompress data in memory
		; IN :	a0 = APTR   source
		;	a1 = APTR   destination (can be equal to source)
		; OUT :	d0 = ULONG  uncompressed size
	ULONG	resload_LoadFileDecrunch
		; load file and uncompress
		; IN :	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = ULONG  success (size of file)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_FlushCache
		; clear CPU caches
		; IN :	-
		; OUT :	-
	ULONG	resload_GetFileSize
		; get size of a file
		; IN :	a0 = CSTR   filename
		; OUT :	d0 = ULONG  size of file
	ULONG	resload_DiskLoad
		; load part from diskimage
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	d2 = ULONG  disk number
		;	a0 = APTR   destination
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 2

	ULONG	resload_DiskLoadDev
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	a0 = APTR   destination
		;	a1 = STRUCT taglist
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  trackdisk errorcode

******* the following functions require ws_Version >= 3

	ULONG	resload_CRC16
		; calculate 16 bit CRC checksum
		; IN :	d0 = ULONG  size
		;	a0 = APTR   address
		; OUT :	d0 = UWORD  CRC checksum

******* the following functions require ws_Version >= 5

	ULONG	resload_Control
		; IN :	a0 = STRUCT taglist
		; OUT :	d0 = BOOL   success
	ULONG	resload_SaveFileOffset
		; write memory to file at offset
		; IN :	d0 = ULONG  size
		;	d1 = ULONG  offset
		;	a0 = CSTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errcode

******* the following functions require ws_Version >= 6

	ULONG	resload_ProtectRead
		; mark memory as read protected
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	-
	ULONG	resload_ProtectReadWrite
		; mark memory as read and write protected
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	-
	ULONG	resload_ProtectWrite
		; mark memory as write protected
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	-
	ULONG	resload_ProtectRemove
		; remove memory protection
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	-
	ULONG	resload_LoadFileOffset
		; load part of file to memory
		; IN :	d0 = ULONG  size
		;	d1 = ULONG  offset
		;	a0 = CSTR   name of file
		;	a1 = APTR   destination
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 8

	ULONG	resload_Relocate
		; relocate AmigaDOS executable
		; IN :	a0 = APTR   address (source=destination)
		;	a1 = STRUCT taglist
		; OUT :	d0 = ULONG  size
	ULONG	resload_Delay
		; wait some time
		; IN :	d0 = ULONG  time to wait in 1/10 seconds
		; OUT :	-
	ULONG	resload_DeleteFile
		; delete file
		; IN :	a0 = CSTR   filename
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 10

	ULONG	resload_ProtectSMC
		; detect self modifying code
		; IN :	d0 = ULONG  length
		;	a0 = APTR   address
		; OUT :	-
	ULONG	resload_SetCPU
		; control CPU setup
		; IN :	d0 = ULONG  properties
		;	d1 = ULONG  mask
		; OUT :	d0 = ULONG  old properties
	ULONG	resload_Patch
		; apply patchlist
		; IN :	a0 = APTR   patchlist
		;	a1 = APTR   destination address
		; OUT :	-

******* the following functions require ws_Version >= 11

	ULONG	resload_LoadKick
		; load kickstart image
		; IN :	d0 = ULONG  length of image
		;	d1 = UWORD  crc16 of image
		;	a0 = CSTR   basename of image
		; OUT :	-
	ULONG	resload_Delta
		; apply wdelta
		; IN :	a0 = APTR   src data
		;	a1 = APTR   dest data
		;	a2 = APTR   wdelta data
		; OUT :	-
	ULONG	resload_GetFileSizeDec
		; get size of a packed file
		; IN :	a0 = CSTR   filename
		; OUT :	d0 = ULONG  size of file

******* the following functions require ws_Version >= 15

	ULONG	resload_PatchSeg
		; apply patchlist to a segment list
		; IN :	a0 = APTR   patchlist
		;	a1 = BPTR   segment list
		; OUT :	-

	ULONG	resload_Examine
		; apply patchlist to a segment list
		; IN :	a0 = CSTR   name
		;	a1 = APTR   struct FileInfoBlock (260 bytes)
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

	ULONG	resload_ExNext
		; apply patchlist to a segment list
		; IN :	a0 = APTR   struct FileInfoBlock (260 bytes)
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

	ULONG	resload_GetCustom
		; get Custom argument
		; IN :	d0 = ULONG  length of buffer
		;	d1 = ULONG  reserved, must be 0
		;	a0 = APTR   buffer
		; OUT :	d0 = BOOL   true if Custom has fit into buffer

	LABEL	resload_SIZEOF

******* compatibility for older slave sources:

resload_CheckFileExist = resload_GetFileSize

;=============================================================================
; commands used in patchlist
; each command follows the address to modify, if bit 16 of the command is
; cleared address follows as 32 bit, if bit 16 of the command is set it
; follows as 16 bit (unsigned extended to 32 bit)

	ENUM	0
	EITEM	PLCMD_END		;end of list
	EITEM	PLCMD_R			;set "rts"
	EITEM	PLCMD_P			;set "jmp"
	EITEM	PLCMD_PS		;set "jsr"
	EITEM	PLCMD_S			;set "bra.w" (skip)
	EITEM	PLCMD_I			;set "illegal"
	EITEM	PLCMD_B			;write byte to specified address
	EITEM	PLCMD_W			;write word to specified address
	EITEM	PLCMD_L			;write long to specified address
; version 11
	EITEM	PLCMD_A			;write address which is calculated as
					;base + arg to specified address
; version 14
	EITEM	PLCMD_PA		;write address given by argument to
					;specified address
	EITEM	PLCMD_NOP		;fill given area with nop instructions
; version 15
	EITEM	PLCMD_C			;clear n bytes
	EITEM	PLCMD_CB		;clear one byte
	EITEM	PLCMD_CW		;clear one word
	EITEM	PLCMD_CL		;clear one long
; version 16
	EITEM	PLCMD_PSS		;set "jsr","nop..."
	EITEM	PLCMD_NEXT		;continue with another patch list
	EITEM	PLCMD_AB		;add byte to specified address
	EITEM	PLCMD_AW		;add word to specified address
	EITEM	PLCMD_AL		;add long to specified address
	EITEM	PLCMD_DATA		;write n data bytes to specified address

;=============================================================================
; macros to build patchlist

PL_START	MACRO			;start of patchlist
.patchlist
		ENDM

PL_END		MACRO			;end of patchlist
	dc.w	PLCMD_END
		ENDM

PL_CMDADR	MACRO			;set cmd and address
	IFLT $ffff-\2
	dc.w	\1
	dc.l	\2
	ELSE
	dc.w	$8000+\1
	dc.w	\2
	ENDC
	ENDM

PL_R		MACRO			;set "rts"
	PL_CMDADR PLCMD_R,\1
		ENDM

PL_PS		MACRO			;set "jsr"
	PL_CMDADR PLCMD_PS,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_P		MACRO			;set "jmp"
	PL_CMDADR PLCMD_P,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_S		MACRO			;skip bytes, set "bra"
	PL_CMDADR PLCMD_S,\1
	dc.w	\2-2			;distance
		ENDM

PL_I		MACRO			;set "illegal"
	PL_CMDADR PLCMD_I,\1
		ENDM

PL_B		MACRO			;write byte
	PL_CMDADR PLCMD_B,\1
	dc.w	\2			;data to write
		ENDM

PL_W		MACRO			;write word
	PL_CMDADR PLCMD_W,\1
	dc.w	\2			;data to write
		ENDM

PL_L		MACRO			;write long
	PL_CMDADR PLCMD_L,\1
	dc.l	\2			;data to write
		ENDM

; version 11

PL_A		MACRO			;write address (base+arg)
	PL_CMDADR PLCMD_A,\1
	dc.l	\2			;data to write
		ENDM

; version 14

PL_PA		MACRO			;write address
	PL_CMDADR PLCMD_PA,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_NOP		MACRO			;fill area with nop's
	PL_CMDADR PLCMD_NOP,\1
	dc.w	\2			;distance
		ENDM

; version 15

PL_C		MACRO			;clear area
	PL_CMDADR PLCMD_C,\1
	dc.w	\2			;length
		ENDM

PL_CB		MACRO			;clear one byte
	PL_CMDADR PLCMD_CB,\1
		ENDM

PL_CW		MACRO			;clear one word
	PL_CMDADR PLCMD_CW,\1
		ENDM

PL_CL		MACRO			;clear one long
	PL_CMDADR PLCMD_CL,\1
		ENDM

PL_PSS		MACRO			;set "jsr","nop..."
	PL_CMDADR PLCMD_PSS,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
	dc.w	\3			;byte count of nop's to append
		ENDM

PL_NEXT		MACRO			;continue with another patch list
	PL_CMDADR PLCMD_NEXT,0
	dc.w	\1-.patchlist		;destination (inside slave!)
		ENDM

PL_AB		MACRO			;add byte
	PL_CMDADR PLCMD_AB,\1
	dc.w	\2			;data to add
		ENDM

PL_AW		MACRO			;add word
	PL_CMDADR PLCMD_AW,\1
	dc.w	\2			;data to add
		ENDM

PL_AL		MACRO			;add long
	PL_CMDADR PLCMD_AL,\1
	dc.l	\2			;data to add
		ENDM

; there are two macros provided for the DATA command, if you want change a 
; string PL_STR can be used:
;	PL_STR	$340,<NewString!>
; for binary data you must use PL_DATA like to follwing example:
;	PL_DATA	$350,.stop-.strt
; .strt	dc.b	2,3,$ff,'a',0
; .stop	EVEN

PL_DATA		MACRO			;write n bytes to specified address
	PL_CMDADR PLCMD_DATA,\1
	dc.w	\2			;count of bytes to write
		ENDM

PL_STR		MACRO
	PL_CMDADR PLCMD_DATA,\1
	dc.w	.dat2\@-.dat1\@
.dat1\@	dc.b	'\2'
.dat2\@	EVEN
		ENDM	

;=============================================================================

 ENDC
