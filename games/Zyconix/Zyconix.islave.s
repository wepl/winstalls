
		; Zyconix Imager
		;
		; Disk 1: Tracks 000-000: Sync ($4489), length $1600 bytes
		;         Tracks 001-159: Sync ($4489), length $1600 bytes
		;
		; Each track has a $14 byte header containing the track
		; number as a byte (twice), followed by "graemes format"
		; followed by the remaining length of data to load (as a
		; longword). Then $1600 bytes of useful data, followed by
		; a longword checksum.
		;
		; This imager supports the original version and the Crystal
		; crack, so existing versions can still be installed.

		incdir	include:
		include	RawDIC.i

		OUTPUT	"Zyconix.islave"

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	DSK_1		; Pointer to the first disk structure
		dc.l	Text		; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"Zyconix imager V1.1",10
		dc.b	"by Codetapper "
		IFD	BARFLY
		IFND	.passchk
		DOSCMD	"WDate >T:date"
.passchk
		ENDC
		INCBIN	"T:date"
		ELSE
		dc.b	"(25.05.2021)"
		ENDC
		dc.b	0
		cnop	0,4

;=====================================================================

DSK_1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	CRC_1		; Table of certain tracks with CRC values
		dc.l	DSK_Crystal	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_1		TLENTRY 000,000,$1600,SYNC_STD,DMFM_STD
		TLENTRY 001,159,$1600,SYNC_STD,_RipTrack
		TLEND
		EVEN

CRC_1		CRCENTRY 000,$582b
		CRCEND
		EVEN

DSK_Crystal	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_NORESTRICTIONS	; Disk flags
		dc.l	TL_Crystal	; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

TL_Crystal	TLENTRY 000,159,$1600,SYNC_STD,DMFM_STD
		TLEND
		EVEN

;=====================================================================

_TrackHeader	dc.b	0,0,"graemes format"
		EVEN
_ChecksumValue	dc.l	0

_RipTrack	addq	#4,a0			;Skip first longword
		lea	_TrackHeader(pc),a3	;Decode to buffer
		move.l	#$14,d0			;d0 = Decode $14 bytes
		bsr	_DecodeD0Bytes
		move.l	d4,d5			;d5 = Header checksum

		move.l	a1,a3			;Decode data to final location
		move.l	#$1600,d0		;d0 = Decode $1600 bytes
		bsr	_DecodeD0Bytes
		move.l	d4,d6			;d6 = Data checksum

		lea	_ChecksumValue(pc),a3
		moveq	#4,d0			;d0 = Decode $4 bytes
		bsr	_DecodeD0Bytes

		add.l	d5,d6
		cmp.l	d4,d6
		bne	_Checksum

_OK		moveq	#IERR_OK,d0
		rts

_Checksum	moveq	#IERR_CHECKSUM,d0
		rts

_DecodeD0Bytes	move.l	a0,a2
		add.l	d0,a2
		moveq	#0,d4			;d4 = Checksum
.DecodeLoop	move.l	(a0)+,d1
		move.l	(a2)+,d2
		andi.l	#$55555555,d1
		andi.l	#$55555555,d2
		lsl.l	#1,d1
		or.l	d1,d2
		move.l	d2,(a3)+
		add.l	d2,d4
		subq	#4,d0
		bne	.DecodeLoop
		move.l	a2,a0
		rts
