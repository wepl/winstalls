;*---------------------------------------------------------------------------
;  :Program.	xenon2.islave.asm
;  :Contents.	Imager for Xenon 2
;  :Author.	Wepl
;  :Version.	$Id: xenon2.islave.asm 1.1 2004/08/10 22:36:51 wepl Exp wepl $
;  :History.	10.08.04 created
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	v1/v2/v3:
;	Disk 1:		0	standard
;			1	rob northen copylock (some versions without)
;			2-159	standard
;	Disk 2:		0-159	standard
;
;	v4:
;	Disk 1:		0-159	standard
;
;	v5:
;	Disk 1:		0	standard
;			1-159	$1800 Rob Northen PDos
;
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	RawDic.i

	IFD BARFLY
	OUTPUT	"Develop:Installs/Xenon2 Install/Xenon2.ISlave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
		dc.l	_disk1v5	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Xenon 2 Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
	EVEN

;============================================================================

_disk1v5	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1v4	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY 1,159,$1800,$1448,_decode
		TLEND

.crc		CRCENTRY 0,$664a
		CRCEND

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decode		move.l	d0,d6			;D6 = track number
		moveq	#0,d7			;D7 = actual sector
		move.l	#$55555555,d2		;D2 = 55555555

.sector		cmp.w	#$4891,(a0)+
		bne	.error
		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		bclr	#31,d0
		move.w	d0,a2			;A2 = chksum
		swap	d0
		cmp.b	d0,d6
		bne	.error
		lsr.w	#8,d0
		cmp.b	d7,d0			;sector number
		bne	.error

		moveq	#512/4-1,d3
		moveq	#0,d4
		moveq	#0,d5			;diskkey

.dec		move.l	($200,a0),d1
		move.l	(a0)+,d0
		eor.l	d0,d4
		and.l	d2,d0
		eor.l	d1,d4
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		eor.l	d0,d5
		move.l	d5,(a1)+
		move.l	d0,d5
		dbf	d3,.dec

		and.l	d2,d4
		move.l	d4,d0
		swap	d4
		add.w	d4,d4
		or.w	d4,d0
		cmp.w	d0,a2
		bne	.error

		add.w	#$200,a0

		move.w	(a0)+,d0
		moveq	#0,d1
		moveq	#7,d3
.gap		roxl.w	#2,d0
		roxl.b	#1,d1
		dbf	d3,.gap

		add.w	d1,d1
		add.l	d1,a0		;sector gap

		addq.w	#1,d7
		cmp.w	#12,d7
		bne	.sector
		
		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

;============================================================================

_disk1v4	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	_disk1		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

.crc		CRCENTRY 0,$34dd
		CRCEND

;============================================================================

_disk1		dc.l	_disk2		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,0,$1600,SYNC_STD,DMFM_STD
		TLENTRY	1,1,$1600,SYNC_STD,DMFM_NULL
		TLENTRY	2,159,$1600,SYNC_STD,DMFM_STD
		TLEND

_disk2		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_DISKIMAGE	; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

.tl		TLENTRY	0,159,$1600,SYNC_STD,DMFM_STD
		TLEND

;============================================================================

	END
