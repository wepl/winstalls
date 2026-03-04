
        ; Circus Attractions imager

        ; A track contains $1600 bytes of data.

        ; track format description:

        ; sync ($5122,$2245,$1224,$5a49,$7fff,$9844,$4489)
        ; 1 unused byte
        ; $1600 bytes data
        ; 2 word checksum

        ; The checksum test is quite strange, a CRC16 calculation is done
        ; which always leads to 0 when everything went ok.
        ; Part of the CRC16 calculation are also 3 sync signal words and
        ; the unused byte following the sync, and ofcourse the checksum.

        ; The MFM decoding is done by skipping all odd bits in the bitstream.

        ; Similar formats: Vroom, et autre lankhor game

                incdir  Includes:
                include RawDIC.i

                SLAVE_HEADER
                dc.b    1       ; Slave version
                dc.b    0       ; Slave flags
                dc.l    DSK_1   ; Pointer to the first disk structure
                dc.l    Text    ; Pointer to the text displayed in the imager window

                dc.b    "$VER:"
Text		dc.b	"Circus Attractions V1.1",10,"by CFou! & Wepl on "
		INCBIN	.date
		dc.b	0
		EVEN

; one disk rerelease

DSK_1		dc.l    0               ; Pointer to next disk structure
                dc.w    1               ; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISKIMAGE    ; List of files to be saved
		dc.l	CRC_1		; Table of certain tracks with CRC values
		dc.l	DSK_1_2D	; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
                dc.l    0               ; Called after a disk has been read

CRC_1		CRCENTRY 000,$6a6a
		CRCEND

; two disk original release

DSK_1_2D	dc.l	DSK_2		; Pointer to next disk structure
                dc.w    1               ; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_1		; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISKIMAGE    ; List of files to be saved
		dc.l	0		; Table of certain tracks with CRC values
                dc.l    0               ; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
                dc.l    0               ; Called after a disk has been read

DSK_2:          dc.l    0		; Pointer to next disk structure
                dc.w    1               ; Disk structure version
		dc.w	0		; Disk flags
		dc.l	TL_2		; List of tracks which contain data
                dc.l    0               ; UNUSED, ALWAYS SET TO 0!
                dc.l    FL_DISKIMAGE    ; List of files to be saved
                dc.l    0               ; Table of certain tracks with CRC values
                dc.l    0               ; Alternative disk structure, if CRC failed
		dc.l	0		; Called before a disk is read
                dc.l    0

TL_1		TLENTRY 0,0,$1600,SYNC_STD,DMFM_STD
                TLENTRY 1,159,$1600,SYNC_STD,DMFM_Circus
                TLEND

TL_2		TLENTRY 0,0,$1600,SYNC_STD,DMFM_NULL
                TLENTRY 1,159,$1600,SYNC_STD,DMFM_Circus
                TLEND

DMFM_Circus:

        bsr _decode
        lea _checksum_l(pc),a1
        bsr _decode_W
        bsr _decode_W

        move.l a3,a1
        MOVE.W  #$AFF,D0
        MOVEQ   #0,D1
        MOVEQ   #0,D2
.bouc
        MOVE.W  (A1)+,D2
        ADD.L   D2,D1
        DBRA    D0,.bouc
        lea _checksum_l(pc),a1
        ADD.L   (A1),D1
        BEQ.B   .ok
.error

        move.l #-1,d0
        rts

.ok
        clr.l d0
        rts
_checksum_l
       dc.l 0

_decode
          move.l a0,a2
          move.l a1,a3
          move.l #$1600/2-1,d0
          move.l #$5555,d3
          clr.l d1
          clr.l d2
.loop
          cmp.w #$2aaa,(a0)+
          bne .loop
          move.l a0,a2
          lea $1604(a0),a4
.enc
          bsr _decode_W
          dbf d0,.enc
   rts

_decode_W
          move.w (a0)+,d2
          move.w (a4)+,d1
          and.w d3,d1
          and.w d3,d2
          add.w d1,d1
          or.w d1,d2
          move.w d2,(a1)+
       rts

