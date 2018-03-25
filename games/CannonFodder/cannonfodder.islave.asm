;*---------------------------------------------------------------------------
;  :Program.	cannonfodder.islave.asm
;  :Contents.	Imager for Cannonfodder
;  :Author.	Wepl
;  :Version.	$Id: cannonsoccer.islave.asm 1.2 2004/12/09 08:32:09 wepl Exp wepl $
;  :History.	19.06.2017 created
;		22.03.2018 updated to v5 RawDIC
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	v1 original:
;	Disk 1:		0	standard
;			1	unformatted
;			2-159	$1800 Sensible Software
;				$0000 = $4489 sync
;				$0002 $180c mfm data even
;				$180e $180c mfm data odd
;				decoded mfm data:
;					0 'SOS6'
;					4 chksum
;					8 ???.w tracknumber.w (sides are swapped)
;					c ... data
;
;---------------------------------------------------------------------------*

DEBUG
MAXDIR	= $1200
MAXFILE	= 196729

;============================================================================

	INCDIR	Includes:
	INCLUDE	RawDic.i
	IFD DEBUG
	INCLUDE	lvo/exec.i
	INCLUDE	lvo/dos.i
	ENDC

	IFD BARFLY
	OUTPUT	"Develop:Installs/Cannonfodder Install/Cannonfodder.ISlave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODd-			;disable mul optimizing
	BOPT	ODe-			;disable mul optimizing
	ENDC

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	5		; Slave version
		dc.b	0		; Slave flags
		dc.l	_disk1v1	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Cannonfodder Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_skipfiles	;dc.b	"fload",0
		;dc.b	"FODDERF",0
		;dc.b	"FODDERS",0
		dc.b	0
	IFD DEBUG
_dosname	dc.b	"dos.library",0
_dbgtxt		dc.b	"%3ld %2ld %6ld %s",10,0
_endtxt		dc.b	"highest track %ld",10,0
	ENDC
	EVEN

;============================================================================

_disk1v1	dc.l	_disk2v1	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
	IFND DEBUG
		dc.l	FL_NULL		; List of files to be saved
	ELSE
		dc.l	FL_DISKIMAGE	; List of files to be saved
	ENDC
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.tl	;	TLENTRY	1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,146,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$8cf8
		CRCEND

_disk2v1	dc.l	_disk3v1	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
	IFND DEBUG
		dc.l	FL_NULL		; List of files to be saved
	ELSE
		dc.l	FL_DISKIMAGE	; List of files to be saved
	ENDC
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.tl		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,152,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$9e34
		CRCEND

_disk3v1	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	.tl		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
	IFND DEBUG
		dc.l	FL_NULL		; List of files to be saved
	ELSE
		dc.l	FL_DISKIMAGE	; List of files to be saved
	ENDC
		dc.l	.crc		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.tl		TLENTRY 2,159,$1800,$4489,_decode
	;	TLENTRY 82,159,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$2368
		CRCEND

;============================================================================

	;d0=tracknum a0=mfm a1=buffer a5=rawdic
_decode		move.l	d0,d6			;D6 = track number
		move.l	#$55555555,d2		;D2 = 55555555
		lea	($180c,a0),a2		;odd data

		bsr	.getlw
		cmp.l	#"SOS6",d0
		bne	.error
		neg.l	d0
		move.l	d0,d5			;D5 = chksum
		
		bsr	.getlw
		add.l	d0,d5
		bsr	.getlw
		sub.l	d0,d5

		move.w	#$1800/4-1,d7
.loop		bsr	.getlw
		sub.l	d0,d5
		move.l	d0,(a1)+
		dbf	d7,.loop

		tst.l	d5
		bne	.error

		moveq	#IERR_OK,d0
		rts

.error		moveq	#IERR_CHECKSUM,d0
		rts

.getlw		move.l	(a0)+,d0
		move.l	(a2)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d1,d1
		add.l	d1,d0
		rts

;============================================================================
; D0 = disk number
; A0 = pointer to disk structure
; A1 = pointer to disk image (requires RawDIC/ISlave v5)

_files		moveq	#2,d0			;track
		jsr	(rawdic_ReadTrack,a5)
		move.l	($18,a1),d0		;amount entries
		mulu	#32,d0
		cmp.l	#MAXDIR,d0
		bhs	_outofmem
		lea	_directory,a0
		move.l	a0,a2			;A2 = directory
		add.w	#32,a1			;first entry
		lsr.l	#2,d0
		subq.w	#1,d0
.cpydir		move.l	(a1)+,(a0)+
		dbf	d0,.cpydir
		
	IFD DEBUG
		moveq	#36,d0
		lea	_dosname,a1
		move.l	4,a6
		jsr	(_LVOOpenLibrary,a6)
		move.l	d0,a6
		moveq	#0,d6
	ENDC

.nextfile	move.l	($1c,a2),d2		;D2 = length
		cmp.l	#MAXFILE,d2
		bhi	_outofmem

	IFD DEBUG
		lea	_dbgtxt,a0
		move.l	a0,d1
		pea	(a2)			;name
		move.l	d2,-(a7)		;length
		moveq	#0,d0
		move.b	($1b,a2),d0		;block
		move.l	d0,-(a7)
		move.b	($1a,a2),d0		;track
		move.l	d0,-(a7)
		move.l	a7,d2
		jsr	(_LVOVPrintf,a6)
		add.w	#16,a7
		move.l	($1c,a2),d2
	ENDC
		
		lea	_file,a3		;A3 = file

		lea	(_skipfiles),a0
.next		move.l	a2,a1
.chk		cmp.b	(a0)+,(a1)+
		bne	.nextchk
		tst.b	(-1,a0)
		bne	.chk
		beq	.skipfile
.nextchk	tst.b	(a0)+
		bne	.nextchk
		tst.b	(a0)
		bne	.next
	
		moveq	#0,d0
		move.b	($1a,a2),d0		;track

		moveq	#0,d3
		move.b	($1b,a2),d3		;D3 = block
.nextblock
	IFD DEBUG
		cmp.b	d0,d6
		bhi	.nothigher
		move.b	d0,d6
.nothigher
	ENDC
		jsr	(rawdic_ReadTrack,a5)

		mulu	#512,d3
		add.l	d3,a1
		moveq	#$1fe/4-1,d0
.cpyfile	move.l	(a1)+,(a3)+
		dbf	d0,.cpyfile
		move.w	(a1)+,(a3)+

		moveq	#0,d0
		move.b	(a1)+,d0		;next track
		moveq	#0,d3
		move.b	(a1)+,d3		;next block

		sub.l	#$1fe,d2
		bhi	.nextblock
		
		move.l	($1c,a2),d0		;length
		move.l	a2,a0			;name
		lea	_file,a1		;data
		jsr	(rawdic_SaveFile,a5)
.skipfile
		add.w	#32,a2
		tst.b	(a2)
		bne	.nextfile
		
	IFD DEBUG
		lea	_endtxt,a0
		move.l	a0,d1
		move.l	d6,-(a7)
		move.l	a7,d2
		jsr	(_LVOVPrintf,a6)
		add.w	#4,a7
	ENDC

		moveq	#IERR_OK,d0
		rts

_outofmem	moveq	#IERR_OUTOFMEM,d0
		rts

;============================================================================

	SECTION b,BSS

_directory	ds.b	MAXDIR
_file		ds.b	MAXFILE+512

;============================================================================

	END
