        ; North 1 South imager

        ; A track contains $1600 bytes of data.

        ; track format description:

        ; sync ($8915)
        ; 1 unused byte
        ; $1600-11*4 bytes data
  
                include RawDIC.i

                SLAVE_HEADER
                dc.b    1       ; Slave version
                dc.b    0       ; Slave flags
                dc.l    DSK_1   ; Pointer to the first disk structure
                dc.l    Text    ; Pointer to the text displayed in the imager window

		dc.b	"$VER:"
Text		dc.b	"North & South (Les Tuniques Bleues) "
	IFD	_Files
		dc.b    "files extractor"
	else
		db	"disk imager"
	ENDC
		db	" V1.3 by",10,"CFou!/Wepl on "
	INCBIN	.date
		db	0
	EVEN

DSK_1:          dc.l    0				; Pointer to next disk structure
                dc.w    1              			; Disk structure version
                dc.w    0				; Disk flags
                dc.l    TL_1            		; List of tracks which contain data
                dc.l    0               		; UNUSED, ALWAYS SET TO 0!
	IFD _Files
                dc.l    FL_DISK1			; List of files to be saved
	ELSE
                dc.l    FL_DISKIMAGE    		; List of files to be saved
	ENDC
                dc.l    0               		; Table of certain tracks with CRC values
                dc.l    0               		; Alternative disk structure, if CRC failed
                dc.l    0               		; Called before a disk is read
	IFD _Files
                dc.l     _ExtractFiles			; Called after a disk has been read
	else
                dc.l    0               		; Called after a disk has been read
	ENDC

	IFD _Files
FL_DISK1	FLENTRY	_BootName,$000,$800
	;	FLENTRY	_Dir1Name,$400,$400
	;	FLENTRY	_ProtectName,$DAA00,$600
		FLENTRY	_Boot2Name,$DBC00,$400
		FLEND

_BootName	dc.b	'disk.1',0
;_Dir1Name	dc.b	'DIR1',0
;_ProtectName	dc.b	'PROTECT.BIN',0
_Boot2Name	dc.b	'BOOT2.bin',0
	even
	ENDC


LG_TRACK	=$1600
TL_1:
                TLENTRY 0,1,LG_TRACK,SYNC_STD,DMFM_STD
                TLENTRY 2,3,LG_TRACK,SYNC_STD,DMFM_NULL
                TLENTRY 4,159,LG_TRACK,SYNC_STD,DMFM_STD
                TLEND

;*******************************************
;================================
;================================
                                 
	IFD	_Files
;================================

_ExtractFiles

	bsr	_ReadDir
	cmp.l	#IERR_OK,d0
	bne	.error

	lea	_DirBuffer,a3
.NextFile
	tst.w	(a3)	; test if file?
	beq .LastFile

	clr.l	d0
	clr.l	d1
	clr.l	d2
	move.l	$C(a3),d0	; Offset of file 
	move.l	$10(a3),d1	; LG of file
	bsr	_LoadFileBuffer

	move.l	a3,a0			; name
	lea	_FileBuffer,a1		; source
	move.l	$10(a3),d0		; LG file
	bsr	_SaveFile

.forceNextFile
	add.l	#$14,a3			; next file
	BRA	.NextFile
.LastFile
	move.l	#IERR_OK,d0
	RTS
.error	cmp.l	#IERR_NOTRACK,d0
	rts
;================================

LG_DIR		=$400

;================================

_ReadTrack
	;moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)	; read track containing directory
	cmp.l	#IERR_OK,d0
	bne	.error
	lea	_TrackBuffer,a0
	move.l	#LG_TRACK-1,d7
.enc
	move.b	(a1)+,(a0)+
	dbf	d7,.enc
.error	rts
;================================

_ReadDir
	moveq	#0,d0
	jsr	rawdic_ReadTrack(a5)	; read track containing directory
	cmp.l	#IERR_OK,d0
	bne	.error
	lea	_DirBuffer,a0
	lea	$400(a1),a1
	move.l	#LG_DIR-1,d7
.enc
	move.b	(a1)+,(a0)+
	dbf	d7,.enc
.error	rts


;================================
_LoadFileBuffer
	movem.l d0-a6,-(a7)
	lea	TrackNum(pc),A1
	move.l	D1,d3		; lg
	divu	#$1600,d0
	move.w  D0,(A1)		; track
	swap.w	d0
        move.w  D0,2(A1)	; sector*$200

		lea	_FileBuffer,a3

		lea	TrackNum(pc),A1
		clr.l	d0
		move.w	(A1),d0		 
		bsr	_ReadTrack
		clr.l	d1
		lea	TrackNum(pc),A1
		move.w	2(A1),d1	; sector
		;mulu	#$200,d1	
		lea	_TrackBuffer,a2
		add.l	d1,a2
		
		move.l	#$1600,D2
		sub.l	D1,D2
		move.l	d2,d1		; data to load
		bsr	_LoadData
;------------------------------------------
		cmp.l	D2,D3
		bLe	.end		; end of file
		sub.l	d2,d3
;------------------------------------------
.again		lea	TrackNum(pc),A1
		add.w	#1,(a1)
		clr.w	2(a1)
		clr.l	d0
		move.w	(a1),d0
		bsr	_ReadTrack

		move.l	#$1600,d1		; lg
		lea	_TrackBuffer,a2
		bsr	_LoadData
		cmp.l	#$1600,d3
		ble	.end
		sub.l	#$1600,d3
                bra.b   .again
.end

	movem.l (a7)+,d0-a6
	clr.l	d0
	rts

_LoadData
.skip2
		sub.l	#1,D1
.copy		move.b	(a2)+,(a3)+	; copy first data
		dbf	d1,.copy
		rts

;================================
_SaveFile	movem.l	d0-d1/a0-a2,-(sp)
		jsr	rawdic_SaveFile(a5)
		movem.l	(sp)+,d0-d1/a0-a2
		rts
;================================

TrackNum        dx.w    2		;  track.w,sector.w
_TrackBuffer	dx.b	LG_TRACK
_DirBuffer	dx.b	LG_DIR
_FileBuffer	dx.b	$20000

	ENDC

	END

