 IFND	DEVICES_I
DEVICES_I = 1
;*---------------------------------------------------------------------------
;  :Author.	Bert Jahn
;  :Contens.	macros for processing devices
;  :History.	29.12.95 separated from WRip.asm
;		18.01.96 IFD Label replaced by IFD Symbol
;			 because Barfly optimize problems
;		12.07.15 no longer checks for dol_Task in _GetDeviceInfo
;  :Copyright.	© 1995,1996,1997,1998 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.130
;---------------------------------------------------------------------------*
*##
*##	devices.i
*##
*##	_GetDeviceInfo		devicename(a0) infostruct(a1) -> success(d0)
*##	_deviceerrors		device error strings
*##	_trackdiskerrors	trackdisk.device error strings

		IFND	DOS_DOSEXTENS_I
			INCLUDE	dos/dosextens.i
		ENDC
		IFND	DOS_FILEHANDLER_I
			INCLUDE	dos/filehandler.i
		ENDC
		IFND	STRINGS_I
			INCLUDE	strings.i
		ENDC
		IFND	_LVOLockDosList
			INCLUDE lvo/dos.i
		ENDC

;----------------------------------------
; Besorgt Infos über Device
; references: The Amiga Guru Book, Ralph Babel
;		S.618f  ACTION_GET_DISK_FSSM
;		S.551ff DosList structure
;		S.353ff DOS-internals and programming aspects
; Übergabe :	A0 = CPTR name of device without ":" (e.g. "DF1")
;		A1 = STRUCT DeviceInfo to fill
; Rückgabe :	D0 = LONG success
; Benötigt :	_PrintErrorDOS	(a0 = CPTR name of error | NIL)
;		_PrintError	(d0 = CPTR Subsystem | NIL
;				 a0 = CPTR Art des Fehlers | NIL
;				 a1 = CPTR bei Operation | NIL)

DEVNAMELEN = 64		;maximal length of the device name

	STRUCTURE	DeviceInfo,0
		STRUCT	devi_Device,DEVNAMELEN
		ULONG	devi_Unit
		ULONG	devi_DeviceFlags
		ULONG	devi_SizeBlock		;in Bytes !
		ULONG	devi_Surfaces
		ULONG	devi_SectorPerBlock
		ULONG	devi_BlocksPerTrack
		ULONG	devi_LowCyl
		ULONG	devi_HighCyl
		LABEL	devi_SIZEOF

GetDeviceInfo	MACRO
	IFND	GETDEVICEINFO
GETDEVICEINFO = 1
	IFND	COPYSTRING
		CopyString
	ENDC
 
DOSLISTFLAGS =	LDF_READ!LDF_DEVICES		;flags for LockDosList,FindDosEntry,UnLockDosList

_GetDeviceInfo	movem.l	d2-d7/a2/a6,-(a7)
		move.l	a0,d2				;D2 = DevName
		move.l	a1,a2				;A2 = STRUCT DeviceInfo
		moveq	#-1,d7				;D7 = ReturnCode (bool)
		
		moveq	#DOSLISTFLAGS,d1
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOLockDosList,a6)
		move.l	d0,d1				;D1 = doslist
		bne	.dlok
		lea	(_getdevinfo),a0
		bsr	_PrintErrorDOS
		moveq	#0,d7
		bra	.nodl
.dlok							;D2 = name
		moveq	#DOSLISTFLAGS,d3
		jsr	(_LVOFindDosEntry,a6)
		tst.l	d0
		bne	.dlfound
		moveq	#0,d0
		lea	(_nodev),a0
		lea	(_getdevinfo),a1
		bsr	_PrintError
		moveq	#0,d7
		bra	.unlockdl
.dlfound
		move.l	d0,a0				;A0 = APTR DosList
		move.l	(dol_Startup,a0),d0
		cmp.l	#64,d0				; $00000040 < d6 < $80000000 ?? BPTR!
		blt	.badstartup
		add.l	d0,d0
		add.l	d0,d0
		beq	.nostartup
		move.l	d0,a0				;A0 = APTR FileSystemStartupMessage

		tst.l	(fssm_Device,a0)
		beq	.nodevice
		move.l	a0,-(a7)
		move.l	(fssm_Device,a0),a0		;a BSTR !!!
		add.l	a0,a0
		add.l	a0,a0				;now it's a APTR
		moveq	#0,d0
		move.b	(a0)+,d0
		addq.l	#1,d0				;d0 size of needed space (length+1)
		moveq	#DEVNAMELEN,d1
		cmp.l	d0,d1				;buffer large enough ?
		bhs	.sizeok
		addq.l	#4,a7				;correct stack
		bra	.copyerr
.sizeok		lea	(devi_Device,a2),a1
		bsr	_CopyString
		move.l	(a7)+,a0

		move.l	(fssm_Unit,a0),(devi_Unit,a2)
		move.l	(fssm_Flags,a0),(devi_DeviceFlags,a2)
		move.l	(fssm_Environ,a0),d0
		add.l	d0,d0
		add.l	d0,d0
		beq	.noenvec

		move.l	d0,a0				;A0 = APTR DosEnvec
		move.l	(de_SizeBlock,a0),d0
		lsl.l	#2,d0				;size in Bytes
		move.l	d0,(devi_SizeBlock,a2)
		move.l	(de_Surfaces,a0),(devi_Surfaces,a2)
		move.l	(de_SectorPerBlock,a0),(devi_SectorPerBlock,a2)
		move.l	(de_BlocksPerTrack,a0),(devi_BlocksPerTrack,a2)
		move.l	(de_LowCyl,a0),(devi_LowCyl,a2)
		move.l	(de_HighCyl,a0),(devi_HighCyl,a2)
		bra	.unlockdl
.badstartup
.nostartup
.nodevice
.copyerr
.noenvec	moveq	#0,d0
		lea	(_baddev),a0
		lea	(_getdevinfo),a1
		bsr	_PrintError
		moveq	#0,d7
.unlockdl
		moveq	#DOSLISTFLAGS,d1
		jsr	(_LVOUnLockDosList,a6)
.nodl
		move.l	d7,d0
		movem.l	(a7)+,d2-d7/a2/a6
		rts
	ENDC
		ENDM

;----------------------------------------
; error strings for device operations
; for using with "Sources:strings.i" _DoString

deviceerrors	MACRO
	IFND	DEVICEERRORS
DEVICEERRORS = 1

_deviceerrors
.base		dc.w	-7		;min index
		dc.w	-1		;max index
		dc.l	0		;next list
		dc.w	.7-.base
		dc.w	.6-.base
		dc.w	.5-.base
		dc.w	.4-.base
		dc.w	.3-.base
		dc.w	.2-.base
		dc.w	.1-.base
.7		dc.b	"hardware failed selftest",0
.6		dc.b	"unit is busy",0
.5		dc.b	"invalid address (IO_DATA)",0
.4		dc.b	"invalid length (IO_LENGTH/IO_OFFSET)",0
.3		dc.b	"unsupported device CMD",0
.2		dc.b	"AbortIO()",0
.1		dc.b	"open device failed",0
		EVEN
	ENDC
		ENDM
		
;----------------------------------------
; error strings for trackdisk.device operations
; for using with "Sources:strings.i" _DoString

trackdiskerrors	MACRO
	IFND	TRACKDISKERRORS
TRACKDISKERRORS = 1
		IFND	DEVICEERRORS
			deviceerrors
		ENDC

_trackdiskerrors
.base		dc.w	20
		dc.w	50
		dc.l	_deviceerrors
		dc.w	.20-.base
		dc.w	.21-.base
		dc.w	.22-.base
		dc.w	.23-.base
		dc.w	.24-.base
		dc.w	.25-.base
		dc.w	.26-.base
		dc.w	.27-.base
		dc.w	.28-.base
		dc.w	.29-.base
		dc.w	.30-.base
		dc.w	.31-.base
		dc.w	.32-.base
		dc.w	.33-.base
		dc.w	.34-.base
		dc.w	.35-.base
		dc.w	.36-.base
		dc.w	.37-.base
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	.42-.base
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	0
		dc.w	.50-.base
.20		dc.b	"not specified",0
.21		dc.b	"no sector header",0
.22		dc.b	"bad sector preamble",0
.23		dc.b	"bad sector id",0
.24		dc.b	"bad header chksum",0
.25		dc.b	"bad sector chksum",0
.26		dc.b	"too few sectors",0
.27		dc.b	"bad sector header",0
.28		dc.b	"write protected",0
.29		dc.b	"no disk in drive",0
.30		dc.b	"couldn't find track 0",0
.31		dc.b	"not enough memory",0
.32		dc.b	"bad unit number",0
.33		dc.b	"bad drive type",0
.34		dc.b	"drive in use",0
.35		dc.b	"post reset",0
.36		dc.b	"data on disk is wrong type",0
.37		dc.b	"invalid CMD under current conditions",0
.42		dc.b	"illegal/unexpected SCSI phase",0
.50		dc.b	"nonexistent board",0
		EVEN
	ENDC
		ENDM

;---------------------------------------------------------------------------

	ENDC

