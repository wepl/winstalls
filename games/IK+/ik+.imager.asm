;*---------------------------------------------------------------------------
;  :Program.	ik+.imager.asm
;  :Contents.	Imager for IK+
;  :Author.	WEPL
;  :Version.	$Id: ik+.imager.asm 1.3 1998/11/24 23:32:43 jah Exp $
;  :History.	18.09.97 first try
;		24.11.98 insert disk fixed, index flag removed
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	devices/trackdisk.i
	INCLUDE	utility/tagitem.i
	INCLUDE	lvo/exec.i
	INCLUDE	patcher.i

	IFD BARFLY
	OUTPUT	"C:Parameter/IK+.Imager"
	BOPT	O+ OG+			;enable optimizing
	BOPT	ODd- ODe-		;disable mul optimizing
	ENDC

;======================================================================

		moveq	#-1,d0
		rts
		dc.l	_Table
		dc.l	"PTCH"

;======================================================================

_Table		dc.l	PCH_ADAPTOR,.adname		;name adaptor
		dc.l	PCH_NAME,.name			;description of parameter
		dc.l	PCH_FILECOUNT,1			;number of cycles
		dc.l	PCH_FILENAME,.filenamearray	;file names
		dc.l	PCH_DATALENGTH,_lengtharray	;file lengths
		dc.l	PCH_DISKNAME,.disknamearray	;disk names
		dc.l	PCH_SPECIAL,.specialarray	;functions
		dc.l	PCH_STATE,.statearray		;state texts
		dc.l	PCH_MINVERSION,.patcherver	;minimum patcher version required
		dc.l	PCH_INIT,_Init			;init routine
		dc.l	PCH_FINISH,_Finish		;finish routine
		dc.l	TAG_DONE

.filenamearray	dc.l	.f1
.disknamearray	dc.l	.d1
.specialarray	dc.l	_Special
.statearray	dc.l	.insertdisk

.f1		dc.b	"IK+.Image",0
.d1		dc.b	"IK+",0

.adname		dc.b	"Done by Wepl.",0
.name		dc.b	"IK+, Diskimager for HD-Install",0
.patcherver	dc.b	"V1.04"
.insertdisk	dc.b	'Please insert your original writepro-',10
		dc.b	'tected disk in the source drive.',0
	IFD BARFLY
		dc.b	"$VER: "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	0
	ENDC
	EVEN

;======================================================================

_Init		bsr	_InitTable

		moveq	#0,d0				;source drive
		move.l	PTB_INHIBITDRIVE(a5),a0		;inhibit drive
		jsr	(a0)
		tst.l	d0
		bne	.error
		
		moveq	#0,d0				;source drive
		move.l	PTB_OPENDEVICE(a5),a0		;open source device
		jsr	(a0)
		tst.l	d0
		bne	.error
		rts

.error		bsr	_Finish
		moveq	#-1,d0
		rts

;======================================================================

_Finish		moveq	#0,d0				;source drive
		move.l	PTB_ENABLEDRIVE(a5),a0		;deinhibit drive
		jmp	(a0)

;======================================================================

_lengtharray	dc.l	BYTESPERTRACK*TRACKS

;======================================================================

RAWREADLEN	= $6c00
BYTESPERTRACK	= $1800
SYNC		= $8944
TRACKS		= $3b

_Special	moveq	#-1,d7				;D7 = return code (default=error)

.idisk		bsr	_InsertOriginal
		tst.l	d0
		bne	.error
		
	;check for disk in drive
		move.l	(PTB_DEVICESOURCEPTR,a5),a1
		move.w	#TD_CHANGESTATE,(IO_COMMAND,a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)
		tst.l	(IO_ACTUAL,a1)
		bne	.idisk

		moveq	#2,d2				;D2 = start/actual track
		moveq	#TRACKS,d3			;D3 = amount of tracks
		move.l	(PTB_ADDRESSOFFILE,a5),a2	;A2 = file address

.next		moveq	#5-1,d6				;D6 = retries decoding
.decretry	moveq	#5-1,d5				;D5 = retries rawread
.tdretry	move.l	(PTB_DEVICESOURCEPTR,a5),a1
		move.l	(PTB_SPACE,a5),(IO_DATA,a1)	;track is to load in ptb_space
		move.l	#RAWREADLEN,(IO_LENGTH,a1)	;double length of track to decode the index-sync-read data
		move.l	d2,(IO_OFFSET,a1)
		move.w	#TD_RAWREAD,(IO_COMMAND,a1)
		move.b	#0,(IO_FLAGS,a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)
		tst.l	d0
		beq	.tdok
		dbf	d5,.tdretry
		bra	.error
.tdok
		move.l	(PTB_SPACE,a5),a0		;source
		move.l	a2,a1				;destination
		bsr	_Decode
		tst.l	d0
		beq	.decok
		dbf	d6,.decretry
		bra	.error
.decok
		add.l	#BYTESPERTRACK,a2
		addq.w	#2,d2				;only one side used !
		subq.w	#1,d3
		bne	.next
		
		moveq	#0,d7				;return code

.end
	;switch motor off
		move.l	PTB_DEVICESOURCEPTR(a5),a1
		clr.l	IO_LENGTH(a1)
		move.w	#TD_MOTOR,IO_COMMAND(a1)
		move.l	(4).w,a6
		jsr	(_LVODoIO,a6)

		move.l	d7,d0
		rts

.error		bsr	_Finish
		bra	.end

;======================================================================
; IN:	A0 = raw
;	A1 = dest
; OUT:	D0 = error

GetW	MACRO
		cmp.l	a0,a5
		bls	.error
		move.l	(a0),d0
		lsr.l	d5,d0
	ENDM

_Decode		movem.l	d1-a6,-(a7)
		move.l	a7,a6			;A6 = return stack
		lea	(RAWREADLEN,a0),a5	;A5 = end of raw data

		addq.l	#8,a0			;because strange subq

	;find sync
.sync1		moveq	#16-1,d5		;D5 = shift count
.sync2		GetW
		cmp.w	#SYNC,d0
		beq	.sync3
.sync_retry	dbf	d5,.sync2
		addq.l	#2,a0
		bra	.sync1

.sync3		move.l	a0,-(a7)		;save this point for new try

.sync4		addq.l	#2,a0
		GetW
		cmp.w	#SYNC,d0
		beq	.sync4
		
	;now strange stuff from original
		subq.l	#6,a0
		move.l	(a0),d0
		ror.l	d5,d0
		move.w	#SYNC,d0
		rol.l	d5,d0
		move.l	d0,(a0)

		MOVEQ	#-1,D6
		MOVE.B	D6,D7

		MOVEQ	#2,D1
		lea	(_buf_3),a4
		BSR.W	.26A

		MOVE.W	#$17FF,D1
		MOVEA.L	A1,A4
		BSR.W	.26A

		MOVEQ	#1,D1
		lea	(_buf_3),a4
		BSR.W	.26A

		OR.B	D6,D7
		beq	.success

		move.l	(a7)+,a0
		bra	.sync_retry		;try again

.success	moveq	#0,d0
.quit		move.l	a6,a7
		movem.l	(a7)+,d1-a6
		rts
.error		moveq	#-1,d0
		bra	.quit

.26A		LEA	.35C(PC),A2
		LEA	(_buf_200),A3
		MOVE.L	A3,D4
		MOVEQ	#$007F,D3
		MOVEQ	#0,D0

.27A		GetW
		addq.l	#2,a0
		ror.l	#8,d0
		AND.W	D3,D0
		MOVEQ	#0,D2
		MOVE.B	(A2,D0.W),D2
		rol.l	#8,d0
		AND.W	D3,D0
		LSL.B	#4,D2
		OR.B	(A2,D0.W),D2
		MOVE.B	D2,(A4)+
		MOVEA.L	D4,A3
		EOR.B	D6,D2
		ADDA.W	D2,A3
		MOVE.B	(A3),D6
		EOR.B	D7,D6
		MOVE.B	$0100(A3),D7
		DBRA	D1,.27A

		RTS	

.35C		DC.L	$10001
		DC.L	$2030203
		DC.L	$10001
		DC.L	$2030203
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$10001
		DC.L	$2030203
		DC.L	$10001
		DC.L	$2030203
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$4050405
		DC.L	$6070607
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$8090809
		DC.L	$A0B0A0B
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F
		DC.L	$C0D0C0D
		DC.L	$E0F0E0F

_InitTable	LEA	(_buf_200),A0
		MOVEQ	#0,D7
.B4		MOVEQ	#0,D6
		MOVE.B	D7,D6
		LSL.W	#8,D6
		MOVEQ	#7,D0
.BC		LSL.W	#1,D6
		BCC.B	.C4
		EORI.W	#$1021,D6
.C4		DBRA	D0,.BC
		MOVE.B	D6,$0100(A0)
		LSR.W	#8,D6
		MOVE.B	D6,(A0)+
		ADDQ.B	#1,D7
		BNE.B	.B4
		rts

_buf_3		ds.b	4

;======================================================================

_InsertOriginal	lea	(.line1),a0
		lea	(.line2),a1
		move.l	PTB_REQUEST(a5),-(a7)
		rts

.line1		dc.b	'Please insert your original disk',0
.line2		dc.b	'in the source drive.',0

;======================================================================

	SECTION	"b",BSS

_buf_200	ds.b	$200

;======================================================================

	END

