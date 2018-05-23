;*---------------------------------------------------------------------------
;  :Program.	cannonfodder.islave.asm
;  :Contents.	Imager for Cannonfodder
;  :Author.	Wepl
;  :Version.	$Id: cannonfodder.islave.asm 1.3 2018/05/23 01:08:59 wepl Exp wepl $
;  :History.	19.06.2017 created
;		22.03.2018 updated to v5 RawDIC
;		23.05.2018 finished
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

;DEBUG
MAXFILE	= 196729

;============================================================================

	INCDIR	Includes:
	INCLUDE	RawDic.i
	IFD DEBUG
	INCLUDE	lvo/exec.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i
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
		dc.l	_disk1v1de	; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Cannonfodder Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	".",0
_skipfiles	dc.b	"fload",0
		dc.b	"FODDERF",0
		dc.b	"FODDERS",0
		dc.b	"disk1",0
		dc.b	"disk2",0
		dc.b	"disk2.raw",0
		dc.b	"DISK2.RAW",0
		dc.b	"disk3",0
		dc.b	0
	IFD DEBUG
_dosname	dc.b	"dos.library",0
_dbgtxt		dc.b	"%3ld %2ld %6ld %s",10,0
_dbgexists	dc.b	"%s exists already",10,0
_endtxt		dc.b	"used tracks ",0
_ld1		dc.b	"%ld-",0
_ld2		dc.b	"%ld,",0
_lf		dc.b	10,0
_dir		dc.b	"disk.x.dir",0
_used		dsb	160
	ENDC
	EVEN

;============================================================================

_disk1v1de	dc.l	_disk2v1de	; Pointer to next disk structure
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
		dc.l	_disk1v1en	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.crc	;	CRCENTRY 1,$8cf8
		CRCENTRY 2,$28dd
		CRCEND

.tl	;	TLENTRY	1,1,$1600,SYNC_STD,DMFM_STD
		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,82,$1800,$4489,_decode
		TLENTRY 108,123,$1800,$4489,_decode
		TLENTRY 141,146,$1800,$4489,_decode
		TLEND

_disk2v1de	dc.l	_disk3v1de	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl2		; List of tracks which contain data
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

.crc		CRCENTRY 2,$9e34
		CRCEND

_tl2		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,152,$1800,$4489,_decode
		TLEND

_disk3v1de	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl3		; List of tracks which contain data
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

.crc		CRCENTRY 2,$2368
		CRCEND

_tl3		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,151,$1800,$4489,_decode
		TLEND

; english sps-860

_disk1v1en	dc.l	_disk2v1en	; Pointer to next disk structure
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
		dc.l	_disk1v2en	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.tl		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,93,$1800,$4489,_decode
		TLENTRY 108,109,$1800,$4489,_decode
		TLENTRY 122,123,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$6979
		CRCEND

_disk2v1en	dc.l	_disk3v1en	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl2		; List of tracks which contain data
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

.crc		CRCENTRY 2,$408d
		CRCEND

_disk3v1en	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl3		; List of tracks which contain data
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

.crc		CRCENTRY 2,$7889
		CRCEND

; english unknown

_disk1v2en	dc.l	_disk2v1en	; Pointer to next disk structure
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
		dc.l	_disk1v1fr	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	_files		; Called after a disk has been read

.tl		TLENTRY 2,80,$1800,$4489,_decode
		TLENTRY 82,107,$1800,$4489,_decode
		TLENTRY 108,140,$1800,$4489,_decode
		TLENTRY 141,146,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$c6e2
		CRCEND

; french

_disk1v1fr	dc.l	_disk2v1fr	; Pointer to next disk structure
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
		TLENTRY 82,93,$1800,$4489,_decode
		TLENTRY 108,109,$1800,$4489,_decode
		TLENTRY 122,129,$1800,$4489,_decode
		TLEND

.crc		CRCENTRY 2,$716b
		CRCEND

_disk2v1fr	dc.l	_disk3v1fr	; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl2		; List of tracks which contain data
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

.crc		CRCENTRY 2,$0145
		CRCEND

_disk3v1fr	dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_SWAPSIDES	; Disk flags
		dc.l	_tl3		; List of tracks which contain data
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

.crc		CRCENTRY 2,$6baa
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
; A5 = RawDIC

_files		move.l	($18,a1),d7		;D7 = amount entries
		lea	(32,a1),a2		;A2 = directory

	IFD DEBUG
		movem.l	d0/a1,-(a7)
	;open dos
		moveq	#36,d0
		lea	_dosname,a1
		move.l	4,a6
		jsr	(_LVOOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	;save disk directory
		movem.l	(a7)+,d0/a1
		lea	_dir,a0			;name
		add.b	#"0",d0
		move.b	d0,(5,a0)
		move.l	#$1800,d0		;length
		jsr	(rawdic_SaveFile,a5)
	;remember used tracks
		lea	_used,a4
		move.l	a4,a0
		moveq	#160/4-1,d0
.clr		clr.l	(a0)+
		dbf	d0,.clr
	ENDC

.nextfile	move.l	($1c,a2),d2		;D2 = length
		cmp.l	#MAXFILE,d2
		bhi	_outofmem

	IFD DEBUG
	;print message
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
	;check if file already exists
		move.l	a2,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq	.notexists
		jsr	(_LVOUnLock,a6)
		lea	_dbgexists,a0
		move.l	a0,d1
		pea	(a2)			;name
		move.l	a7,d2
		jsr	(_LVOVPrintf,a6)
		add.w	#4,a7
	;append ".2"
		move.l	a2,a0
.lp		tst.b	(a0)+
		bne	.lp
		subq.l	#1,a0
		move.b	#".",(a0)+
		move.b	#"2",(a0)+
		clr.b	(a0)+
.notexists
		move.l	($1c,a2),d2
	ENDC
		
		lea	_file,a3		;A3 = file

		lea	(_skipfiles),a0
.next		move.l	a2,a1
.chk		move.b	(a1)+,d0
		cmp.b	(a0),d0
		bne	.nextchk
		tst.b	(a0)+
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
		st	(a4,d0.w)
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
		subq.l	#1,d7
		bne	.nextfile
		
	IFD DEBUG
		moveq	#0,d5			;used mode
		moveq	#0,d6			;actual track
		move	#160-1,d7		;loop counter
		lea	_endtxt,a0
		move.l	a0,d1
		moveq	#0,d2
		jsr	(_LVOVPrintf,a6)

.loop		tst.b	(a4)+
		beq	.no
.yes		tst.b	d5
		bne	.nxt
		lea	_ld1,a0
		move.l	a0,d1
		move.l	d6,-(a7)
		move.l	a7,d2
		jsr	(_LVOVPrintf,a6)
		add.w	#4,a7
		st	d5
		bra	.nxt
.no		tst.b	d5
		beq	.nxt
		lea	_ld2,a0
		move.l	a0,d1
		move.l	d6,-(a7)
		subq.l	#1,(a7)
		move.l	a7,d2
		jsr	(_LVOVPrintf,a6)
		add.w	#4,a7
		sf	d5
.nxt		add.l	#1,d6
		dbf	d7,.loop
		lea	_lf,a0
		move.l	a0,d1
		moveq	#0,d2
		jsr	(_LVOVPrintf,a6)
	ENDC

		moveq	#IERR_OK,d0
		rts

_outofmem	moveq	#IERR_OUTOFMEM,d0
		rts

;============================================================================

	SECTION b,BSS

_file		ds.b	MAXFILE+512

;============================================================================

	END
