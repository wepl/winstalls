;*---------------------------------------------------------------------------
;  :Program.	tech.islave.asm
;  :Contents.	Imager for Tech
;  :Author.	Wepl
;  :History.	28.10.01 started
;		31.10.01 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*
;
;	Disk format:
;	original release:
;	Disk 1:		0	standard
;			1	mfmlen=$1f82 sync=4489 declen=$fa4
;			6-144	mfmlen=$2efa sync=4891 declen=$1770
;			(several gaps of unformatted tracks!)
;
;---------------------------------------------------------------------------*

	INCLUDE	RawDic.i

;============================================================================

	SECTION a,CODE

		SLAVE_HEADER
		dc.b	1		; Slave version
		dc.b	0		; Slave flags
	;	dc.b	SFLG_DEBUG	; Slave flags
		dc.l	_disk1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Tech Imager",10
		dc.b	"Done by Wepl, Version 1.0 "
	INCBIN	.date
		dc.b	".",0
_0a		dc.b	"Tech.0a",0
_03		dc.b	"Tech.03",0
_0d		dc.b	"Tech.0d",0
_2a		dc.b	"Tech.2a",0
_48		dc.b	"Tech.48",0
	EVEN

;============================================================================

	;original release
_disk1		dc.l	0		; Pointer to next disk structure
		dc.w	1		; Disk structure version
		dc.w	DFLG_DOUBLEINC	; Disk flags
		dc.l	_tl1		; List of tracks which contain data
		dc.l	0		; UNUSED, ALWAYS SET TO 0!
		dc.l	_fl1		; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
		dc.l	0		; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
		dc.l	0		; Called after a disk has been read

_tl1		TLENTRY	$03*2+0,$03*2+0+(2*8),$1770,$4891,_decode1
		TLENTRY	$0d*2+0,$0d*2+0+(2*24),$1770,$4891,_decode1
		TLENTRY	$2a*2+0,$2a*2+0+(2*28),$1770,$4891,_decode1
		TLENTRY	$48*2+0,$48*2+0+(2*0),$1770,$4891,_decode1
		TLENTRY	$0a*2+1,$0a*2+1+(2*6),$1770,$4891,_decode1
		TLEND

_fl1		FLENTRY	_03,(0)*$1770,$c800
		FLENTRY	_0d,(9)*$1770,$24450
		FLENTRY	_2a,(9+25)*$1770,$29198
		FLENTRY	_48,(9+25+29)*$1770,$64
		FLENTRY	_0a,(9+25+29+1)*$1770,$9520
		FLEND

_decode1
		move.l	#$55555555,d3
		move.w	#$1770/4-1,d2
.1		movem.l	(a0)+,d0-d1
		and.l	d3,d0
		and.l	d3,d1
		add.l	d0,d0
		or.l	d1,d0
		move.l	d0,(a1)+
		dbf	d2,.1

		moveq	#IERR_OK,d0
		rts

;============================================================================

	END

