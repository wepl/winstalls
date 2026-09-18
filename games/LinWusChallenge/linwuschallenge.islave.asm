;*---------------------------------------------------------------------------
;  :Program.	linwuschallenge.islave.asm
;  :Contents.	Imager for Lin Wu's Challenge
;  :Author.	Wepl
;  :History.	2026-09-13 started
;		2026-09-14 'loader' no longer saved, 'CP' skipped (both done by the slave)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	vasm
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	Disk 1:		0	standard, bootblock loads tracks 78-79 to $70000
;			1	directory, custom format
;			2-63	data, custom format
;			78-79	standard, loader (contains encrypted file system
;				library which is decrypted to $c0), not needed
;			64-77	unformatted
;			80-81	standard, small OFS filesystem (not used by the game)
;			82-159	unformatted
;		the directory contains the broken file "GANE" whose block chain
;		leads into unformatted track 64, it is skipped
;		the file "CP" (disk protection) is not saved, the slave provides it
;
;	custom format (file system library at $c0):
;		sync $2245, then $5fc longs, each long as odd/even mfm longs
;		decoded data track 2-63: 23 sectors of $10a bytes
;			$000 word sector number (0-22)
;			$002 word next block
;			$004 long checksum = sum of the 64 data longs
;			$008 word unused
;			$00a 256 bytes data
;		decoded data track 1 (directory):
;			$004 long checksum = sum of $3f7 longs starting at $008
;			$008 word number of files
;			$00a entries of 20 bytes each:
;				$00 name, 10 bytes, not always 0-terminated
;				$0a long file length
;				$0e word first block
;				$10 word unused
;			$1200 block allocation bitmap
;		block number = track * 23 + sector
;
;---------------------------------------------------------------------------*

;DEBUG = 1

SYNC		= $2245
SECLEN		= $10a			;length of a sector
SECDATA		= $a			;offset of data inside a sector
SECCNT		= 23			;sectors per track
TRKLEN		= $5fc*4		;decoded track length
DIRCNT		= $dc			;max amount of directory entries
FIRSTTRK	= 2			;first data track
LASTTRK		= 63			;last data track
MAXFILE		= (LASTTRK-FIRSTTRK+1)*SECCNT*256

;============================================================================

	INCLUDE	RawDIC.i

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	5		; Slave version
		dc.b	0		; Slave flags
		dc.l	_disk1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Lin Wu's Challenge Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	INCBIN	".date"
		dc.b	".",0
_brokentxt	dc.b	"file '%s' skipped, invalid block %ld",10,0
	IFD DEBUG
_dbgtxt		dc.b	"%-10s length=%6ld block=%4ld",10,0
	ENDC
	EVEN

;============================================================================

_disk1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	0		; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	FL_NULL		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

_tl1		TLENTRY	1,1,TRKLEN,SYNC,_decodedir
		TLENTRY	FIRSTTRK,LASTTRK,TRKLEN,SYNC,_decode
		TLEND

;============================================================================
; decode the mfm data of a track
; each long is stored as odd bits long followed by even bits long
; IN:	a0 = mfm data after sync
;	a1 = track buffer
; OUT:	a0/a1 destroyed

_decodemfm	movem.l	d0-d3,-(a7)
		move.l	#$55555555,d2
		move.w	#TRKLEN/4-1,d3
.loop		move.l	(a0)+,d0
		move.l	(a0)+,d1
		and.l	d2,d0
		and.l	d2,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d3,.loop
		movem.l	(a7)+,d0-d3
		rts

;============================================================================
; directory track
; D0.w = track, A0 = mfm, A1 = buffer, A5 = rawdic

_decodedir	move.l	a1,-(a7)
		bsr	_decodemfm
		move.l	(a7)+,a1

		lea	(8,a1),a0
		move.w	#$3f7-1,d1
		moveq	#0,d0
.sum		add.l	(a0)+,d0
		dbf	d1,.sum
		cmp.l	(4,a1),d0
		bne	_checksum

		cmp.w	#DIRCNT,(8,a1)
		bhi	_checksum

		moveq	#IERR_OK,d0
		rts

;============================================================================
; data track
; D0.w = track, A0 = mfm, A1 = buffer, A5 = rawdic

_decode		move.l	a1,-(a7)
		bsr	_decodemfm
		move.l	(a7)+,a1

		moveq	#0,d2			;D2 = sector
.sector		lea	(SECDATA,a1),a0
		moveq	#64-1,d1
		moveq	#0,d0
.sum		add.l	(a0)+,d0
		dbf	d1,.sum
		cmp.l	(4,a1),d0
		bne	_checksum
		cmp.w	(a1),d2
		bne	.nosector
		add.w	#SECLEN,a1
		addq.w	#1,d2
		cmp.w	#SECCNT,d2
		bne	.sector

		moveq	#IERR_OK,d0
		rts

.nosector	moveq	#IERR_NOSECTOR,d0
		rts

_checksum	moveq	#IERR_CHECKSUM,d0
		rts

;============================================================================
; save all files of the directory except 'CP'
; D0 = disk number
; A0 = pointer to disk structure
; A1 = pointer to disk image
; A5 = RawDIC

_files		moveq	#1,d0
		jsr	(rawdic_ReadTrack,a5)
		lea	(_dir),a2
		move.w	#(10+DIRCNT*20)/2-1,d0
.cpydir		move.w	(a1)+,(a2)+
		dbf	d0,.cpydir

		lea	(_dir),a2
		move.w	(8,a2),d7		;D7 = amount of files
		beq	.done
		add.w	#10,a2			;A2 = directory entry

.nextfile	lea	(_name),a0
		move.l	a2,a1
		moveq	#10-1,d0
.cpyname	move.b	(a1)+,(a0)+
		dbf	d0,.cpyname
		clr.b	(a0)

	;'CP' is the disk protection, replaced by the slave
		cmp.w	#"CP",(_name)
		bne	.nocp
		tst.b	(_name+2)
		beq	.skipfile
.nocp

		move.l	(10,a2),d4		;D4 = length
		cmp.l	#MAXFILE,d4
		bhi	.diskrange
		move.w	(14,a2),d3		;D3 = block

	IFD DEBUG
		moveq	#0,d0
		move.w	d3,d0
		move.l	d0,-(a7)
		move.l	d4,-(a7)
		pea	(_name)
		lea	(_dbgtxt),a0
		move.l	a7,a1
		jsr	(rawdic_Print,a5)
		add.w	#12,a7
	ENDC

		lea	(_file),a3		;A3 = file data
		move.l	d4,d5			;D5 = bytes left
		beq	.save

.nextblock	moveq	#0,d0
		move.w	d3,d0
		divu	#SECCNT,d0
		cmp.w	#FIRSTTRK,d0
		blo	.broken
		cmp.w	#LASTTRK,d0
		bhi	.broken
		move.l	d0,d1
		swap	d1
		mulu	#SECLEN,d1		;D1 = sector offset
		jsr	(rawdic_ReadTrack,a5)
		tst.l	d0
		bne	.error
		add.l	d1,a1
		move.w	(2,a1),d3		;next block
		add.w	#SECDATA,a1

		move.l	#256,d0
		cmp.l	d0,d5
		bhs	.full
		move.l	d5,d0
.full		sub.l	d0,d5
		subq.w	#1,d0
.cpyblock	move.b	(a1)+,(a3)+
		dbf	d0,.cpyblock
		tst.l	d5
		bne	.nextblock

.save		lea	(_name),a0
		lea	(_file),a1
		move.l	d4,d0
		jsr	(rawdic_SaveFile,a5)
		tst.l	d0
		bne	.error

.skipfile	add.w	#20,a2
		subq.w	#1,d7
		bne	.nextfile

.done		moveq	#IERR_OK,d0
.error		rts

.diskrange	moveq	#IERR_DISKRANGE,d0
		rts

	;the block chain leaves the formatted tracks, e.g. "GANE" on the
	;original disk points into the unformatted track 64
.broken		moveq	#0,d0
		move.w	d3,d0
		move.l	d0,-(a7)
		pea	(_name)
		lea	(_brokentxt),a0
		move.l	a7,a1
		jsr	(rawdic_Print,a5)
		addq.w	#8,a7
		bra	.skipfile

;============================================================================

	SECTION b,BSS

_dir		ds.b	10+DIRCNT*20
_name		ds.b	11
	CNOP 0,4
_file		ds.b	MAXFILE

;============================================================================

	END
