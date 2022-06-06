
	;	Include file for RawDIC

		ifnd	EXEC_TYPES_I
		include	exec/types.i
		endc

	; RawDIC library:

	; calling conventions:	all registers remain unchanged except
	;			for registers containing return values.

 STRUCTURE	RawDIC,0

	ULONG	rawdic_ReadTrack
		; Reads a track into the trackbuffer. This function
		; will use the tle_Decoder routine for MFM decoding.
		; DO NOT USE THIS FUNCTION IN YOUR TRACK DECODER
		; ROUTINES!

		; D0.w=track
		; => D0.l=errorcode
		; => A1=trackbuffer

		; errors:
		; IERR_NOSYNC
		; IERR_CHECKSUM
		; IERR_NOSECTOR
		; IERR_NODISK
		; IERR_NOTRACK

	ULONG	rawdic_NextSync
		; Search for the next sync-signal on the track.
		; The trackbuffer will be shifted to the END of the
		; sync signal (may contain more than one sync word).
		; If no sync is found, this routine will not return
		; but display an errormessage. Set DFLG_ERRORS if
		; you want this function to return.

		; => D0.l=errorcode
		; => A0=MFM data buffer

		; errors:
		; IERR_NOSYNC

	ULONG	rawdic_NextMFMword
		; Search for the next sync-signal on the track.
		; D0 must contain the bit pattern of the signal.
		; The trackbuffer will be shifted to the END of the
		; sync signal (may contain more than one sync word).
		; If no sync is found, this routine will not return
		; but display an errormessage. Set DFLG_ERRORS if
		; you want this function to return.

		; D0.w=bitpattern
		; => D0.l=errorcode
		; => A0=MFM data buffer

		; errors:
		; IERR_NOSYNC

	ULONG	rawdic_SaveFile
		; Stores a memory block as file.
		; An existing file will be overwritten.

		; A0=filename
		; A1=memory adress
		; D0.l=length
		; => D0.l=errorcode

		; errors:
		; IERR_NOWFILE

	ULONG	rawdic_SaveDiskFile
		; Stores a part of the diskimage as file.
		; An existing file will be overwritten.
		; ONLY USE IN dsk_DiskCode!

		; A0=filename
		; D0.l=offset in diskimage
		; D1.l=length
		; => D0.l=errorcode

		; errors:
		; IERR_NOWFILE

	ULONG	rawdic_AppendFile
		; Similar to rawdic_SaveFile, but if the file already
		; exists, the data will be appended to the existing file.

		; A0=filename
		; A1=memory adress
		; D0.l=length
		; => D0.l=errorcode

		; errors:
		; IERR_NOWFILE

	ULONG	rawdic_AppendDiskFile
		; Stores a part of the diskimage as file (append)
		; An existing file will be appended with new data
		; ONLY USE IN dsk_DiskCode!

		; A0=filename
		; D0.l=offset in diskimage
		; D1.l=length
		; => D0.l=errorcode

		; errors:
		; IERR_NOWFILE

	ULONG	rawdic_DMFM_STANDARD
		; Decodes the MFM buffer as standard DOS track.
		; This function will behave like a standard tle_Decoder and will
		; ALWAYS return on errors, even with DFLG_ERRORS is not set!

		; D0.b=sectors per track (normally 11)
		; => D0.l=errorcode

		; errors:
		; IERR_NOSYNC
		; IERR_CHECKSUM
		; IERR_NOSECTOR

	ULONG	rawdic_Print
		; print message to stdout, for debugging purposes (v4.6)
		; all registers are preserved

		; A0.l = CPTR format string
		; A1.l = APTR arg array

	ULONG	rawdic_SetSync
		; sets a new wordsync value for the actual tracklist (v5.0)
		; all registers are preserved
		; requires that slave version >= 5

		; D0.w = WORD sync

	ULONG	rawdic_Reserved_3
	ULONG	rawdic_Reserved_4
		; DO NOT USE!

	; error codes:

IERR_OK		equ	0	; ok
IERR_CHECKSUM	equ	-1	; checksum error
IERR_NOSYNC	equ	-2	; MFM 16-bit pattern not found
IERR_NOSECTOR	equ	-3	; sector not found (for sector-based disk formats)
IERR_NOWFILE	equ	-4	; a file could not be stored
IERR_OUTOFMEM	equ	-5	; no memory to allocate memory
IERR_DISKRANGE	equ	-6	; a file exceeds diskrange
IERR_NOTRACK	equ	-7	; not existant track (tracklist...)
IERR_UNDEFINED	equ	-8	; undefined error message, for private use only!
IERR_NODISK	equ	-9	; no disk in drive
IERR_CRCFAIL	equ	-10	; CRC check failed
IERR_TRACKLIST	equ	-11	; tracklist is invalid
IERR_FILELIST	equ	-12	; filelist is invalid
IERR_VERSION	equ	-13	; slave has higher version number than imager
IERR_DSKVERSION	equ	-14	; disk structure has not supported version number
IERR_FLAGS	equ	-15	; slave uses flags not to be used with the specified version
IERR_NOFUNCTION	equ	-16	; function may not be called at the current programstate
IERR_INP_OPEN	equ	-17	; input file would not open
IERR_INP_SEEK	equ	-18	; input file seek error
IERR_INP_READ	equ	-19	; input file read error
IERR_INP_NOTRK	equ	-20	; input file does not contain the track we wanted
IERR_INP_BADHD	equ	-21	; input file has a bad track header
IERR_XPK_DEPACK	equ	-22	; mfmwarp xpk depack routine failed
IERR_MC1_DEPACK	equ	-23	; mfmwarp mc1 depack routine failed
IERR_DIP_DEPACK	equ	-24	; mfmwarp dip depack routine failed
IERR_MFM_CSUM	equ	-25	; mfmwarp checksum error
IERR_INP_ILLEN	equ	-26	; input file has an illegal track length
IERR_FORMAT_UNS	equ	-27	; format of the input file is currently unsupported
IERR_INP_INCOMP	equ	-28	; format of the input file is not compatible with what the slave wants (eg. contains dos and wants mfm)
IERR_NMD_DEPACK	equ	-29	; nomadwarp depack routine failed
IERR_WWP_UNS	equ	-30	; wwarp file format is unsupported
IERR_TABL_DATA	equ	-31	; wwarp table data error
IERR_TABL_UNS	equ	-32	; wwarp table header version unsupported
IERR_TRCK_UNS	equ	-33	; wwarp track header version unsupported
IERR_TRCK_TYPE	equ	-34	; wwarp track type unsupported
IERR_TRCK_FLAG	equ	-35	; wwarp track flags unsupported
IERR_TWLIB	equ	-36	; trackwarp library not found or wrong version
IERR_SLAVEVERSION equ	-36	; rawdic function called requires a higher slave version

 STRUCTURE	SlaveStructure,0

	UBYTE	slv_Version	; slave version, starting v5 this must be <= rawdic version
	UBYTE	slv_Flags	; slave flags
	APTR	slv_FirstDisk	; pointer to the first disk structure
	APTR	slv_Text	; pointer to the text displayed in the imager window
	LABEL	slv_SIZEOF

SFLG_DEBUG	equ	1	; automatically output debug information
SFLG_VERSION1	equ	SFLG_DEBUG

	; Following files will be saved when SFLG_DEBUG is set:

	; .RawDIC_Debug		; contains all CRC16 values and the errorcodes which
				; tle_Decoder returned

	; While SFLG_DEBUG is set, tle_Decoder errors will NOT terminate slave execution!
	; All other errors (i.e. while RawDIC function calls) WILL terminate execution!

 STRUCTURE	Disk,0

	APTR	dsk_NextDisk	; pointer to next disk structure
	UWORD	dsk_Version	; disk structure version
	UWORD	dsk_Flags	; flags (look below)
	APTR	dsk_TrackList	; list of tracks which contain data
	APTR	dsk_TLExtension	; CURRENTLY NOT SUPPORTED, ALWAYS SET TO 0!
	APTR	dsk_FileList	; list of files to be saved
	APTR	dsk_CRCList	; table of tracks with CRC values
	APTR	dsk_AltDisk	; alternative disk structure, if CRC failed
	FPTR	dsk_InitCode	; called before a disk is read
	FPTR	dsk_DiskCode	; called after a disk has been read
	LABEL	dsk_SIZEOF_v1
	APTR	dsk_DiskName	; plain text name of the disk to insert
	LABEL	dsk_SIZEOF

 ; dsk_NextDisk: contains the pointer to the next disk structure or 0
 ;              if this is the last disk

 ; dsk_Flags: possible flags are...

DFLG_SINGLESIDE	equ	1	; only one side of the disk contains data
DFLG_SWAPSIDES	equ	2	; swap sides in the trackcounter
DFLG_ERRORSWAP	equ	4	; swap sides on read error
DFLG_ERRORS	equ	8	; RawDIC functions will return on errors
DFLG_RAWREADONLY equ	16	; RawDIC will not try to read standard tracks via CMD_READ first
DFLG_NORESTRICTIONS equ	32	; RawDIC will not check the TrackList
DFLG_DOUBLEINC	equ	64|DFLG_NORESTRICTIONS	; The track counter will increment by 2 and not 1 as usual
DFLG_VERSION1	equ	DFLG_SWAPSIDES|DFLG_SINGLESIDE|DFLG_ERRORSWAP|DFLG_ERRORS|DFLG_RAWREADONLY|DFLG_NORESTRICTIONS|DFLG_DOUBLEINC	; used bits

 ; dsk_TrackList: A pointer to a table of tracks defined as "valid", other
 ;               tracks will not be read. This is the ONLY field which
 ;               absolutely MUST be used.
 ;               Look below for structure definition.

 ; dsk_FileList: A pointer to a table of files which will be written.
 ;              In normal cases files are just parts of the disk image,
 ;              and this is how they are described in this list.
 ;              Setting this pointer to FL_DISKIMAGE will automatically save the
 ;              diskimage as "Disk.#".
 ;		Setting to FL_NULL will save no files.

 ; dsk_CRCList:  A table of track numbers and their CRC16 values.
 ;              Use this table to check for special versions.
 ;              Set to 0 when no version check is needed.
 ;              Look below for structure definition.
 ;		To get the CRC16 values, use the SFLG_DEBUG flag and look into the
 ;		debug file.

 ; dsk_AltDisk:  A pointer to an ALTERNATIVE disk structure which is
 ;              used when the above CRC check failed.
 ;              Set to 0 if this disk structure has no alternative.

 ; dsk_InitCode: A pointer to a subroutine which is called once every time
 ;              RawDIC starts to read a disk. Put your initialisations
 ;              here... if you have any. If not, set to 0!

 ;		A5=RawDIC library base
 ;              D0.b=disknumber
 ;              => D0.l=errorcode

 ; dsk_DiskCode: A pointer to a subroutine which is called once every time
 ;              RawDIC has FINISHED reading a disk. If you build up your
 ;              FileList out of the disks data, put the routines here!
 ;              Otherwise set to 0.

 ;		A5=RawDIC library base
 ;              D0.b=disknumber
 ;              => D0.l=errorcode

 STRUCTURE	TrackListEntry,0

	WORD	tle_FirstTrack		; first track of a segment (-1 for last entry)
	WORD	tle_LastTrack		; last track of a segment
	UWORD	tle_BlockLength		; length of each track in bytes
	UWORD	tle_Sync		; sync signal for each track
	FPTR	tle_Decoder		; MFM decoder routine
	LABEL	tle_SIZEOF

 ; tle_Decoder: A pointer to a subroutine which is called after the MFM data of
 ;		a track has been read.
 ;		Put your MFM track to RAW track conversion routines here!!!

 ;		A0=MFM data
 ;		A1=trackbuffer
 ;		A5=RawDIC library base
 ;              D0.w=tracknumber
 ;              => D0.l=errorcode


 STRUCTURE	FileListEntry,0

	APTR	fle_Name		; name of the file (0 for last entry)
	LONG	fle_Offset		; starting offset in the diskimage
	LONG	fle_Length		; length of the file
	LABEL	fle_SIZEOF

 STRUCTURE	CRCListEntry,0

	WORD	crc_Track	; number of track (-1 for last entry)
	UWORD	crc_Checksum	; CRC16 value for this track
	LABEL	crc_SIZEOF


	; macros:

	; header of imager slaves:

SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"RAWDIC"
		ENDM

	; ### macros for MFM decoding:

	; word to byte conversion by skipping every odd bit

	; \1 must be a data register, d7 will be used as loopcounter
	; d7 is a working register

	; example:	BITSKIP_B d0

BITSKIP_B	MACRO
		moveq	#7,d7		; d7 should be unused
.l0\@		add.w	\1,\1
		add.l	\1,\1
		dbra	d7,.l0\@
		swap	\1
		ENDM

	; long to word conversion by skipping every odd bit

	; \1 must be a data register
	; d7 is a working register

	; example:	BITSKIP_W d0

BITSKIP_W	MACRO
		swap	\1
		move.l	\1,d7
		move.w	#7,d7		; d7 should be unused
.l0\@		add.w	\1,\1
		add.l	\1,\1
		dbra	d7,.l0\@
		swap	d7
		move.w	d7,\1
		moveq	#7,d7		; d7 should be unused
.l1\@		add.w	\1,\1
		add.l	\1,\1
		dbra	d7,.l1\@
		swap	\1
		ENDM

	; decodes a byte

	; \1 can be a register, an adress, an indirekt adress etc.
	; \2 is the source of the bitmask ($5555), it can be
	;    immediate or a data register
	; \3 is the target data register which will contain the decoded word
	; d7 is a working register

	; example:	DECODE_W d6,d1,d0

DECODE_B	MACRO
		move.w	\1,\3
		and.w	\2,\3
		move.w	\3,d7
		lsr.w	#7,d7
		add.b	d7,\3
		ENDM

	; decodes a word

	; \1 can be a register, an adress, an indirekt adress etc.
	; \2 is the source of the bitmask ($55555555), it can be
	;    immediate or a data register
	; \3 is the target data register which will contain the decoded word
	; d7 is a working register

	; example:	DECODE_W d6,d1,d0

DECODE_W	MACRO
		move.l	\1,\3
		and.l	\2,\3
		move.l	\3,d7
		swap	d7
		add.w	d7,d7
		add.w	d7,\3
		ENDM

	; decodes a longword

	; \1 must be of (A?)+
	; \2 is the source of the bitmask ($55555555), it can be
	;    immediate or a data register
	; \3 is the target data register which will contain the decoded word
	; d7 is a working register

	; example:	DECODE_L (a0)+,#$55555555,d0

DECODE_L	MACRO
		move.l	\1,\3
		move.l	\1,d7
		and.l	\2,\3
		and.l	\2,d7
		add.l	\3,\3
		add.l	d7,\3
		ENDM

	; values which terminate lists:

TL_END		equ	-1
FL_END		equ	-1
CRC_END		equ	-1

 ; TL_ENTRY: a tracklist entry
 ; format:	TL_ENTRY tle_FirstTrack,tle_LastTrack,tle_BlockLength,tle_Sync,tle_Decoder
 ; example:	TL_ENTRY 0,19,$1600,SYNC_STD,DMFM_STD

	; defines for sync signals: (tle_Sync)

SYNC_INDEX	equ	0	; used for indexsync (this is NOT syncword 0)
SYNC_STD	equ	$4489	; standard sync signal
;SYNC_STANDARD	equ	SYNC_STD	; obsolete

	; defines for decoder routines: (tle_Decoder)

DMFM_NULL	equ	0	; track contains no data (filled with zeros)
DMFM_STD	equ	1	; track will be decoded with standard dos track decoder
;DMFM_STANDARD	equ	DMFM_STD	; obsolete

TLENTRY	MACRO
		dc.w	\1,\2,\3,\4
		dc.l	\5
		ENDM

 ; TL_END: terminates a tracklist

TLEND		MACRO
		dc.w	TL_END
		ENDM

	; dsk_FileList pre-defined FileLists:

FL_DISKIMAGE	equ	0	; Diskimage only.
FL_NULL		equ	-1	; Empty FileList, no files will be saved!
FL_NOFILES	equ	FL_NULL

 ; FL_ENTRY: a filelist entry
 ; format:	FL_ENTRY fle_Name,fle_Offset,fle_Length
 ; example:	FL_ENTRY FL_DISKNAME,$400,$18a00
 ; diskimage:	FL_ENTRY FL_DISKNAME,0,FL_DISKLENGTH

	; defines for special FLENTRY values:

FL_DISKNAME	equ	0	; put this at fle_Name to get "Disk.???" as filename.
FL_DISKLENGTH	equ	-1	; put this at fle_Length to get the length of the diskimage (fle_Offset should be 0)

FLENTRY	MACRO
		dc.l	\1,\2,\3
		ENDM

 ; FL_END: terminates a filelist

FLEND		MACRO
		dc.l	FL_END
		ENDM

 ; CRC_ENTRY: a crclist entry
 ; format:	FL_ENTRY crc_Track,crc_Checksum
 ; example:	FL_ENTRY 19,$b25a

CRCENTRY	MACRO
		dc.w	\1,\2
		ENDM

 ; CRC_END: terminates a crclist

CRCEND		MACRO
		dc.w	CRC_END
		ENDM



