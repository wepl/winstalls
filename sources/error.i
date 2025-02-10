 IFND ERROR_I
ERROR_I=1
;*---------------------------------------------------------------------------
;  :Author.	Bert Jahn
;  :Contens.	macros for error handling
;  :History.	30.12.95 separated from WRip.asm
;		18.01.96 IFD Label replaced by IFD Symbol
;			 because Barfly optimize problems
;		17.01.99 _PrintError* optimized
;		26.12.99 fault string initialisation added in _PrintErrorDOS
;		27.04.08 _PrintErrorDOSFH/Name added
;		17.01.20 _PrintError print "unspecified error" if error is missing
;		12.02.20 _PrintError print "unspecified error" also on "0"
;  :Requires.	-
;  :Copyright.	All rights reserved.
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16
;---------------------------------------------------------------------------*
*##
*##	error.i
*##
*##	_PrintError		subsystem(d0) error(a0) operation(a1)
*##	_PrintErrorDOS		operation(a0)
*##	_PrintErrorDOSFH	operation(a0) fh(d0)
*##	_PrintErrorDOSName	operation(a0) name(a1)
*##	_PrintErrorTD		error(d0.b) operation(a0)

		IFND	DOSIO_I
			INCLUDE	dosio.i
		ENDC
		IFND	STRINGS_I
			INCLUDE	strings.i
		ENDC
		IFND	DEVICES_I
			INCLUDE	devices.i
		ENDC

;----------------------------------------
; Ausgabe eines Fehlers
; In:	D0 = CPTR Subsystem | NIL
;	A0 = CPTR Art des Fehlers | NIL
;	A1 = CPTR bei Operation | NIL
; Out:	-

PrintError	MACRO
	IFND	PRINTERROR
PRINTERROR = 1
		IFND	PRINTARGS
			PrintArgs
		ENDC

_PrintError	movem.l	d0/a1,-(a7)
		move.l	a0,d0
		beq	.def
		tst.b	(a0)
		beq	.def
		cmp.b	#"0",(a0)
		bne	.set
		tst.b	(1,a0)
		bne	.set
.def		lea	(.unspecified),a0
.set		move.l	a0,-(a7)
		lea	(.txt),a0
		move.l	a7,a1
		bsr	_PrintArgs
		add.w	#12,a7
		rts
		
.txt		dc.b	155,"1m%s",155,"22m (%s/%s)",10,0
.unspecified	dc.b	"unspecified error",0
		EVEN
	ENDC
		ENDM

;----------------------------------------
; print dos.library error message
; In:	A0 = CPTR operation which has caused the error | NIL
; Out:	-

PrintErrorDOS	MACRO
	IFND	PRINTERRORDOS
PRINTERRORDOS = 1
		IFND	PRINTERROR
			PrintError
		ENDC

_PrintErrorDOS	movem.l	d2-d4/a0/a6,-(a7)
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOIoErr,a6)
		move.l	d0,d1			;code
		moveq	#0,d2			;header
		moveq	#64,d4			;buffer length
		sub.l	d4,a7
		clr.b	(a7)
		move.l	a7,d3			;buffer
		jsr	(_LVOFault,a6)
		lea	(_dosname),a0
		move.l	a0,d0			;subsystem
		move.l	a7,a0			;error
		move.l	(12,a7,d4.l),a1		;operation
		bsr	_PrintError
		add.l	d4,a7
		movem.l	(a7)+,d2-d4/a0/a6
		rts
	ENDC
		ENDM

;----------------------------------------
; print dos.library error message
; In:	D0 = BPTR file handle
;	A0 = CPTR operation which has caused the error | NIL
; Out:	-

PrintErrorDOSFH	MACRO
	IFND	PRINTERRORDOSFH
PRINTERRORDOSFH	= 1
		IFND	PRINTERROR
			PrintError
		ENDC

BUFLEN_FNAME = 128

_PrintErrorDOSFH
		movem.l	d0/d2-d4/a0/a6,-(a7)
		sub.w	#BUFLEN_FNAME,a7
		move.l	(gl_dosbase,GL),a6
	;get ioerr
		jsr	(_LVOIoErr,a6)
		move.l	d0,d4			;d4 = ioerr
	;get filename
		move.l	(BUFLEN_FNAME,a7),d1
		move.l	a7,d2			;buffer
		move.l	#BUFLEN_FNAME,d3	;buflen
		jsr	(_LVONameFromFH,a6)
		tst.l	d0
		beq	.noname
	;print header
		lea	(.head,pc),a0
		pea	(a7)
		move.l	a7,a1
		bsr	_PrintArgs
		addq.l	#4,a7
.noname
	;get dos error text
		move.l	d4,d1			;code
		moveq	#0,d2			;header
		move.l	#BUFLEN_FNAME,d4	;buffer length
		clr.b	(a7)
		move.l	a7,d3			;buffer
		jsr	(_LVOFault,a6)
	;print error
		lea	(_dosname),a0
		move.l	a0,d0			;subsystem
		move.l	a7,a0			;error
		move.l	(BUFLEN_FNAME+4*4,a7),a1   ;operation
		bsr	_PrintError
		add.w	#BUFLEN_FNAME,a7
		movem.l	(a7)+,d0/d2-d4/a0/a6
		rts
.head		dc.b	"%s: ",0
	EVEN
	ENDC
		ENDM

;----------------------------------------
; print dos.library error message
; In:	A0 = CPTR operation which has caused the error | NIL
;	A1 = CPTR file name
; Out:	-

PrintErrorDOSName MACRO
	IFND	PRINTERRORDOSNAME
PRINTERRORDOSNAME = 1
		IFND	PRINTERROR
			PrintError
		ENDC

_PrintErrorDOSName
		movem.l	d2-d4/a0-a1/a6,-(a7)
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOIoErr,a6)
		move.l	d0,d1			;code
		moveq	#0,d2			;header
		moveq	#64,d4			;buffer length
		sub.l	d4,a7
		clr.b	(a7)
		move.l	a7,d3			;buffer
		jsr	(_LVOFault,a6)
		lea	(.head,pc),a0
		lea	(64+4*4,a7),a1
		bsr	_PrintArgs
		lea	(_dosname),a0
		move.l	a0,d0			;subsystem
		move.l	a7,a0			;error
		move.l	(12,a7,d4.l),a1		;operation
		bsr	_PrintError
		add.l	d4,a7
		movem.l	(a7)+,d2-d4/a0-a1/a6
		rts
.head		dc.b	"%s: ",0
	EVEN
	ENDC
		ENDM

;----------------------------------------
; Ausgabe eines Trackdisk Errors
; In:	D0 = BYTE errcode
;	A0 = CPTR Operation | NIL
; Out:	-

PrintErrorTD	MACRO
	IFND	PRINTERRORTD
PRINTERRORTD=1
		IFND	DOSTRING
			DoString
		ENDC
		IFND	PRINTERROR
			PrintError
		ENDC

_PrintErrorTD	move.l	a0,-(a7)
		ext.w	d0
		lea	(_trackdiskerrors),a0
		bsr	_DoString
		move.l	d0,a0			;error
		lea	(.devaccess),a1
		move.l	a1,d0			;subsystem
		move.l	(a7)+,a1		;operation
		bra	_PrintError

.devaccess	dc.b	'device access',0
		EVEN
		IFND	TRACKDISKERRORS
			trackdiskerrors
		ENDC
	ENDC
		ENDM
 ENDC
