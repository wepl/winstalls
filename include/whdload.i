;*---------------------------------------------------------------------------
;  :Module.	whdload.i
;  :Contens.	include file for WHDLoad and Slaves
;  :Author.	Bert Jahn
;  :EMail.	wepl@kagi.com
;  :Address.	Franz-Liszt-Straße 16, Rudolstadt, 07404, Germany
;  :Version.	$Id: whdload.i 9.2125 1999/02/14 23:31:57 jah Exp jah $
;  :History.	11.04.99 marcos moved to separate include file
;		08.05.99 resload_Patch added
;  :Copyright.	© 1996,1997,1998,1999 Bert Jahn, All Rights Reserved
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
; additional	Version 8
;=============================================================================

	ULONG	ws_ExpMem	;size of required expansions memory, during
				;initialisation overwritten by WHDLoad with
				;address of the memory (multiple of $1000)

;=============================================================================
; additional	Version 10
;=============================================================================

	RPTR	ws_name		;name of the installed program
	RPTR	ws_copy		;year and owner of the copyright
	RPTR	ws_info		;additional informations (author, version...)
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

;=============================================================================
; properties for resload_SetCPU
;=============================================================================

WCPUF_Base	= 3		;BaseMem mask
WCPUF_Base_NCS	= 0		;BaseMem = non cacheable serialized
WCPUF_Base_NC	= 1		;BaseMem = non cacheable
WCPUF_Base_WT	= 2		;BaseMem = cacheable write trough
WCPUF_Base_CB	= 3		;BaseMem = cacheable copyback
WCPUF_Exp	= 12		;ExpMem mask
WCPUF_Exp_NCS	= 0		;ExpMem = non cacheable serialized
WCPUF_Exp_NC	= 4		;ExpMem = non cacheable
WCPUF_Exp_WT	= 8		;ExpMem = cacheable write trough
WCPUF_Exp_CB	= 12		;ExpMem = cacheable copyback
WCPUF_Slave	= 48		;Slave mask
WCPUF_Slave_NCS	= 0		;Slave = non cacheable serialized
WCPUF_Slave_NC	= 16		;Slave = non cacheable
WCPUF_Slave_WT	= 32		;Slave = cacheable write trough
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
		; IN :	a0 = CPTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = ULONG  success (size of file)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_SaveFile
		; write memory to file
		; IN :	d0 = LONG   size
		;	a0 = CPTR   filename
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
		;	a0 = CPTR   name of directory to scan
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
		; IN :	a0 = CPTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = ULONG  success (size of file)
		;	d1 = ULONG  dos errorcode
	ULONG	resload_FlushCache
		; clear CPU caches
		; IN :	-
		; OUT :	-
	ULONG	resload_GetFileSize
		; get size of file
		; IN :	a0 = CPTR   filename
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
		;	a0 = CPTR   filename
		;	a1 = APTR   address
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errcode

******* the following functions require ws_Version >= 6

	ULONG	resload_ProtectRead
		; mark memory as read protected
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectReadWrite
		; mark memory as read and write protected
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectWrite
		; mark memory as write protected
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_ProtectRemove
		; remove memory protection
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
		; OUT :	-
	ULONG	resload_LoadFileOffset
		; load part of file to memory
		; IN :	d0 = ULONG  offset
		;	d1 = ULONG  size
		;	a0 = CPTR   name of file
		;	a1 = APTR   destination
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 8

	ULONG	resload_Relocate
		; relocate AmigaDOS executable
		; IN :	a0 = APTR   address (source/destination)
		;	a1 = STRUCT taglist
		; OUT :	d0 = ULONG  size
	ULONG	resload_Delay
		; wait some time
		; IN :	d0 = ULONG  time to wait in 1/10 seconds
		; OUT :	-
	ULONG	resload_DeleteFile
		; delete file
		; IN :	a0 = CPTR   filename
		; OUT :	d0 = BOOL   success
		;	d1 = ULONG  dos errorcode

******* the following functions require ws_Version >= 10

	ULONG	resload_ProtectSMC
		; detect self modifying code
		; IN :	d0 = ULONG  length
		;	a0 = CPTR   address
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

	LABEL	resload_SIZEOF

******* compatibility for older slave sources:

resload_CheckFileExist = resload_GetFileSize

;=============================================================================
; commands used in patchlist
; each command follows the address to modify, if bit 16 of the command is
; cleared address follows as 32 bit, if bit 16 of the command is set it
; follows as 16 bit (nonsigned extended to 32 bit)

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

;=============================================================================
; macros to build patchlist

PL_START	MACRO			;start of patchlist
.patchlist
		ENDM

PL_END		MACRO			;end of patchlist
	dc.w	PLCMD_END
		ENDM

PL_CMDADR	MACRO			;set cmd and address
	IFMI $ffff-\2
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

PL_PS		MACRO			;set "jmp"
	PL_CMDADR PLCMD_PS,\1
	dc.w	\2-.patchlist		;destination (inside slave!)
		ENDM

PL_P		MACRO			;set "jsr"
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

;=============================================================================

 ENDC
