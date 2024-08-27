;*---------------------------------------------------------------------------
;  :Program.	tech.islave.asm
;  :Contents.	Imager for Tech
;  :Author.	Wepl
;  :History.	28.10.01 started
;		31.10.01 finished
;		27.08.24 add crc table to support weak disks
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
		dc.l	_disk1		; Pointer to the first disk structure
		dc.l	_text		; Pointer to the text displayed in the imager window

		dc.b	"$VER: "
_text		dc.b	"Tech Imager",10
		dc.b	"Done by Wepl, Version 1.1 "
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
		dc.l	_crc1		; Table of certain tracks with CRC values
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

; because missing mfm checksums we use crc for all except highscores at $48
; RawDIC Tech.ISlave Debug >log
; tr = ' ' <log | awk '{print "\t\tCRCENTRY " $4 ",$" $10}'

_crc1
		CRCENTRY 6,$B464
		CRCENTRY 8,$9D87
		CRCENTRY 10,$05C7
		CRCENTRY 12,$9E58
		CRCENTRY 14,$D154
		CRCENTRY 16,$A930
		CRCENTRY 18,$E134
		CRCENTRY 20,$4BB4
		CRCENTRY 22,$E64A
		CRCENTRY 26,$3993
		CRCENTRY 28,$5D4C
		CRCENTRY 30,$E912
		CRCENTRY 32,$1EF2
		CRCENTRY 34,$4EFB
		CRCENTRY 36,$3DA5
		CRCENTRY 38,$2BBC
		CRCENTRY 40,$0B56
		CRCENTRY 42,$6751
		CRCENTRY 44,$F57C
		CRCENTRY 46,$5037
		CRCENTRY 48,$CFC5
		CRCENTRY 50,$C4CD
		CRCENTRY 52,$9D06
		CRCENTRY 54,$EFC4
		CRCENTRY 56,$612F
		CRCENTRY 58,$6B82
		CRCENTRY 60,$7303
		CRCENTRY 62,$BA43
		CRCENTRY 64,$8124
		CRCENTRY 66,$FE8C
		CRCENTRY 68,$4EA7
		CRCENTRY 70,$FEBC
		CRCENTRY 72,$AAC6
		CRCENTRY 74,$2889
		CRCENTRY 84,$4B72
		CRCENTRY 86,$3E7A
		CRCENTRY 88,$C922
		CRCENTRY 90,$B9DE
		CRCENTRY 92,$EF2D
		CRCENTRY 94,$8BB2
		CRCENTRY 96,$7DBD
		CRCENTRY 98,$6834
		CRCENTRY 100,$141B
		CRCENTRY 102,$4DAC
		CRCENTRY 104,$2F7F
		CRCENTRY 106,$F451
		CRCENTRY 108,$9E4E
		CRCENTRY 110,$4629
		CRCENTRY 112,$FE4C
		CRCENTRY 114,$312B
		CRCENTRY 116,$ED6F
		CRCENTRY 118,$0C1D
		CRCENTRY 120,$4492
		CRCENTRY 122,$EA63
		CRCENTRY 124,$23EB
		CRCENTRY 126,$2432
		CRCENTRY 128,$E3C8
		CRCENTRY 130,$09EE
		CRCENTRY 132,$4291
		CRCENTRY 134,$AF9B
		CRCENTRY 136,$2B60
		CRCENTRY 138,$EB9C
		CRCENTRY 140,$1F57
		;CRCENTRY 144,$EF09	highscores
		CRCENTRY 21,$FB94
		CRCENTRY 23,$CCFB
		CRCENTRY 25,$DC15
		CRCENTRY 27,$13C3
		CRCENTRY 29,$D474
		CRCENTRY 31,$AE8B
		CRCENTRY 33,$4A29
		CRCEND

;============================================================================

	END
