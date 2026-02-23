 IFND	STRINGS_I
STRINGS_I = 1
;*---------------------------------------------------------------------------
;  :Author.	Bert Jahn
;  :Contens.	macros for processing strings
;  :History.	29.12.95 separated from WRip.asm
;		18.01.96 IFD Label replaced by IFD Symbol
;			 because Barfly optimize problems
;		02.03.96 _RemoveExtension,_AppendString added
;		25.08.96 _atoi,_etoi added
;		21.07.97 _StrLen added
;		22.07.97 Macro UPPER separated from whdl_cache.s
;		22.07.97 _StrNCaseCmp added
;		16.11.97 buffer length check fixed in _FormatString,
;			 now works, but it is no longer reentrant !
;		21.12.97 _DoStringNull added
;		27.06.98 cleanup for use with "HrtMon"
;		17.10.98 parameters for _AppendString corrected
;		19.01.14 _VSNPrintF added
;		28.01.14 _VSNPrintF removed A5 usage for WHDLoad
;		29.01.14 _VSNPrintF added specifier %B to print a BPTR
;			 converted to an APTR
;		03.08.21 optimized _StrLen
;		13.11.23 _StrCaseCmp added
;		11.02.26 _VSNPrintF add specifier %ll for 64-bit ints
;		12.02.26 _VSNPrintF add thousands grouping flag '
;		13.02.26 _FormatString using _VSNPrintF
;		23.02.26 _VSNPrintF flags moved to upper bits of D3
;			 _VSNPrintF optimized .putc subroutine
;  :Copyright.	All rights reserved.
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;---------------------------------------------------------------------------*
*##
*##	strings.i
*##
*##	_FormatString	fmt(a0),argarray(a1),buffer(a2),bufsize(d0)
*##	_DoStringNull	list(a0),number(d0.w) --> stringptr(d0)
*##	_DoString	list(a0),number(d0.w) --> stringptr(d0)
*##	_CopyString	source(a0),dest(a1),destbufsize(d0) --> success(d0)
*##	_RemoveExtension source(a0) --> success(d0)
*##	_AppendString	source(a0),dest(a1),destbufsize(d0) --> success(d0)
*##	_atoi		source(a0) --> integer(d0),stringleft(a0)
*##	_etoi		source(a0) --> integer(d0),stringleft(a0)
*##	UPPER		char(dx) --> char(dx)
*##	_StrLen		source(a0) --> length(d0)
*##	_StrCaseCmp	string(a0),string(a1) --> relation(d0)
*##	_StrNCaseCmp	string(a0),string(a1),len(d0) --> relation(d0)
*##	_VSNPrintF	buffer(a0),fmt(a1),argarray(a2),bufsize(d0) --> numchars(d0),bufferleft(a0)

;----------------------------------------
; format string (printf)
; IN:	D0 = ULONG length of buffer
;	A0 = APTR format
;	A1 = APTR arguments
;	A2 = APTR buffer to fill
; OUT:	-

FormatString	MACRO
	IFND	FORMATSTRING
FORMATSTRING=1
	IFND	VSNPRINTF
		VSNPrintF
	ENDC
_FormatString	move.l	a2,-(a7)
		exg.l	a0,a1
		exg.l	a0,a2
		bsr	_VSNPrintF
		move.l	(a7)+,a2
		rts
	ENDC
		ENDM

;----------------------------------------
; get string from table
; IN:	D0 = WORD   value
;	A0 = STRUCT table
; OUT:	D0 = CPTR   string or NULL

DoStringNull	MACRO
	IFND	DOSTRINGNULL
DOSTRINGNULL=1
_DoStringNull
.start		cmp.w	(a0),d0			;lower bound
		blt	.nextlist
		cmp.w	(2,a0),d0		;upper bound
		bgt	.nextlist
		move.w	d0,d1
		sub.w	(a0),d1			;index
		add.w	d1,d1			;because words
		move.w	(8,a0,d1.w),d1		;rptr
		beq	.nextlist
		add.w	d1,a0
		move.l	a0,d0
		rts

.nextlist	move.l	(4,a0),a0		;next list
		move.l	a0,d1
		bne	.start
		
		moveq	#0,d0
		rts

		ENDC
		ENDM

;----------------------------------------
; get string from table
; return generated string if no string is available
; not reetrant in case generated is returned
; IN :	D0 = WORD   value
;	A0 = STRUCT table
; OUT :	D0 = CPTR   string

DoString	MACRO
	IFND	DOSTRING
DOSTRING=1
		IFND	DOSTRINGNULL
			DoStringNull
		ENDC
		IFND	FORMATSTRING
			FormatString
		ENDC

_DoString	ext.l	d0
		movem.l	d0/a2,-(a7)
		bsr	_DoStringNull
		tst.l	d0
		beq	.maketxt
		addq.l	#8,a7
		rts

.maketxt	move.l	a7,a1			;args
		moveq	#8,d0			;buflen
		lea	(.fmt),a0		;format string
		lea	(.buf),a2		;buffer
		bsr	_FormatString
		move.l	a2,d0
		addq.l	#4,a7
		move.l	(a7)+,a2
		rts

.fmt		dc.b	"%ld",0
.buf		ds.w	4,0

		ENDC
		ENDM

;----------------------------------------
; copy string
; IN:	D0 = LONG dest buffer size
;	A0 = CPTR source string
;	A1 = APTR dest buffer
; OUT:	D0 = LONG success (fails if buffer to small)

CopyString	MACRO
	IFND	COPYSTRING
COPYSTRING=1
_CopyString	tst.l	d0
		ble	.err
.lp		move.b	(a0)+,(a1)+
		beq	.ok
		subq.l	#1,d0
		bne	.lp
		clr.b	-(a1)
.err		moveq	#0,d0
		rts

.ok		moveq	#-1,d0
		rts
	ENDC
		ENDM

;----------------------------------------
; remove name extension after .
; IN:	A0 = CPTR source string
; OUT:	D0 = LONG success (true if a extension is removed)

RemoveExtension	MACRO
	IFND	REMOVEEXTENSION
REMOVEEXTENSION=1
_RemoveExtension
		move.l	a0,d0
		beq	.err
.l1		tst.b	(a0)+
		bne	.l1
.l2		cmp.l	a0,d0
		beq	.err
		cmp.b	#".",-(a0)
		bne	.l2
		clr.b	(a0)
		moveq	#-1,d0
		rts
		
.err		moveq	#0,d0
		rts
	ENDC
		ENDM

;----------------------------------------
; append string at the end of existing string
; IN:	D0 = LONG  destination buffer size
;	A0 = CPTR  source string (to append)
;	A1 = CPTR  destination string (to append on)
; OUT:	D0 = LONG  success (fail if buffer to small)

AppendString	MACRO
	IFND	APPENDSTRING
APPENDSTRING=1
_AppendString	tst.l	d0
		ble	.err
.l1		subq.l	#1,d0
		tst.b	(a1)+
		bne	.l1
		subq.l	#1,a1
		addq.l	#1,d0
		ble	.err
		
.lp		move.b	(a0)+,(a1)+
		beq	.ok
		subq.l	#1,d0
		bne	.lp
		clr.b	-(a1)

.err		moveq	#0,d0
		rts

.ok		moveq	#-1,d0
		rts
	ENDC
		ENDM

;----------------------------------------
; converts ASCII to Integer
; asciiint ::= [+|-] { {<digit>} | ${<hexdigit>} }¹
; hexdigit ::= {012456789abcdefABCDEF}¹
; digit    ::= {0123456789}¹
; IN:	A0 = CPTR ascii | NULL
; OUT:	D0 = LONG integer (on error=0)
;	A0 = CPTR first char after translated ASCII

atoi		MACRO
	IFND	ATOI
ATOI=1
_atoi		movem.l	d6-d7,-(a7)
		moveq	#0,d0		;default
		move.l	a0,d1		;a0 = NIL ?
		beq	.eend
		moveq	#0,d1
		move.b	(a0)+,d1
		cmp.b	#"-",d1
		seq	d7		;D7 = negative
		beq	.1p
		cmp.b	#"+",d1
		bne	.base
.1p		move.b	(a0)+,d1
.base		cmp.b	#"$",d1
		beq	.hexs

.dec		cmp.b	#"0",d1
		blo	.end
		cmp.b	#"9",d1
		bhi	.end
		sub.b	#"0",d1
		move.l	d0,d6		;D0 * 10
		lsl.l	#3,d0		;
		add.l	d6,d0		;
		add.l	d6,d0		;
		add.l	d1,d0
		move.b	(a0)+,d1
		bra	.dec

.hexs		move.b	(a0)+,d1
.hex		cmp.b	#"0",d1
		blo	.hexl
		cmp.b	#"9",d1
		bhi	.hexl
		sub.b	#"0",d1
		bra	.hexgo
.hexl		cmp.b	#"a",d1
		blo	.hexh
		cmp.b	#"f",d1
		bhi	.hexh
		sub.b	#"a"-10,d1
		bra	.hexgo
.hexh		cmp.b	#"A",d1
		blo	.end
		cmp.b	#"F",d1
		bhi	.end
		sub.b	#"A"-10,d1
.hexgo		lsl.l	#4,d0		;D0 * 16
		add.l	d1,d0
		move.b	(a0)+,d1
		bra	.hex

.end		subq.l	#1,a0
		tst.b	d7
		beq	.eend
		neg.l	d0
.eend		movem.l	(a7)+,d6-d7
		rts
	ENDC
		ENDM

;----------------------------------------
; converts Expression to Integer
; asiiexp ::= {<space>} <asciiint> { {<space>} {+|-}¹ {<space>} <asciiint> }
; space   ::= {SPACE|TAB}
; IN:	A0 = CPTR ascii | NIL
; OUT:	D0 = LONG integer (on error=0)
;	A0 = CPTR first char after translated ASCII

etoi		MACRO
	IFND	ETOI
	IFND	ATOI
		atoi
	ENDC
ETOI=1
_etoi		movem.l	d2-d3,-(a7)
		moveq	#0,d2		;D2 = result
		move.l	a0,d1		;a0 = NIL ?
		beq	.eend
		moveq	#0,d3		;D3 = operation

.sp		move.b	(a0)+,d1
		cmp.b	#" ",d1		;space
		beq	.sp
		cmp.b	#"	",d1	;tab
		beq	.sp
		subq.l	#1,a0
		bsr	_atoi
		cmp.b	#"-",d3
		beq	.minus
.plus		add.l	d0,d2
		bra	.newop
.minus		sub.l	d0,d2
.newop		move.b	(a0)+,d1
		cmp.b	#" ",d1		;space
		beq	.newop
		cmp.b	#"	",d1	;tab
		beq	.newop
		cmp.b	#"+",d1
		beq	.opok
		cmp.b	#"-",d1
		bne	.end
.opok		move.b	d1,d3		;D3 = operation
		bra	.sp

.end		subq.l	#1,a0
.eend		move.l	d2,d0
		movem.l	(a7)+,d2-d3
		rts
	ENDC
		ENDM

;----------------------------------------
; calculate length of a string
; (confirming BSD 4.3)
; IN :	A0 = CPTR  source string
; OUT :	D0 = ULONG length

StrLen	MACRO
	IFND	STRLEN
STRLEN=1
_StrLen		move.l	a0,d0
		beq	.end
.loop		tst.b	(a0)+
		bne	.loop
		sub.l	a0,d0
		not.l	d0		;neg.l d0 & sub.l #1,d0
.end		rts
	ENDC
		ENDM

;----------------------------------------
; makes character in Dx upper case
; only 7-bit ASCII !

UPPER	MACRO
		cmp.b	#"a",\1
		blo	.l\@
		cmp.b	#"z",\1
		bhi	.l\@
		sub.b	#$20,\1
.l\@
	ENDM

;----------------------------------------
; compare two strings case insensitiv (only 7-bit ASCII !!!)
; (confirming BSD 4.3)
; IN :	A0 = CPTR  string 1
;	A1 = CPTR  string 2
; OUT :	D0 = ULONG <0 if a0 less than a1
;		    0 if a0 equal a1
;		   >0 if a0 greater than a1
;	Z = f(d0)

StrCaseCmp	MACRO
	IFND	STRCASECMP
STRCASECMP=1
_StrCaseCmp	cmp.l	a0,a1		;string equal ?
		beq	.equal
		move.l	a0,d0
		beq	.less
		move.l	a1,d0
		beq	.greater

.next		move.b	(a0)+,d0
		UPPER	d0
		move.b	(a1)+,d1
		UPPER	d1
		cmp.b	d0,d1
		bhi	.less
		blo	.greater
		tst.b	d0
		bne	.next

.equal		moveq	#0,d0
		rts
.less		moveq	#-1,d0
		rts
.greater	moveq	#1,d0
		rts
	ENDC
		ENDM

;----------------------------------------
; compare two strings with given length case insensitiv (only 7-bit ASCII !!!)
; (confirming BSD 4.3)
; IN :	D0 = ULONG amount of chars to compare
;	A0 = CPTR  string 1
;	A1 = CPTR  string 2
; OUT :	D0 = ULONG <0 if a0 less than a1
;		    0 if a0 equal a1
;		   >0 if a0 greater than a1
;	Z = f(d0)

StrNCaseCmp	MACRO
	IFND	STRNCASECMP
STRNCASECMP=1
_StrNCaseCmp	move.l	d2,-(a7)

		tst.l	d0		;len = 0 ?
		beq	.equal
		cmp.l	a0,a1		;string equal ?
		beq	.equal
		move.l	a0,d1
		beq	.less
		move.l	a1,d1
		beq	.greater

.next		move.b	(a0)+,d1
		UPPER	d1
		move.b	(a1)+,d2
		UPPER	d2
		cmp.b	d1,d2
		bhi	.less
		blo	.greater
		subq.l	#1,d0
		bne	.next

.equal		moveq	#0,d0
		bra	.end
.less		moveq	#-1,d0
		bra	.end
.greater	moveq	#1,d0
.end		move.l	(a7)+,d2
		rts
	ENDC
		ENDM

;----------------------------------------
; format string like vsnprintf (similar exec.RawDoFmt)
; must not change A5/A6 at any time because used in WHDLoad's Resload part
; IN:	D0 = ULONG length of provided buffer
;	A0 = APTR  buffer
;	A1 = APTR  format string
;	A2 = APTR  arguments
; OUT:	D0 = ULONG length of created string if buffer length would be unlimited,
;		   not including the final '\0'
;	A0 = APTR  points to the terminating null byte of the created string if
;		   buffer had length > 0

VSNPrintF	MACRO
	IFND	VSNPRINTF
VSNPRINTF=1

; D0-D2 = trash
; D3.hw	= flags 31=longlong(64-bit) 30=long(32-bit) 29=minus 28=null 27=group
; D4	= argument value (high long on 64-bit)
; D5.lw	= precision length (post dot)
; D5.hw	= field length (pre dot)
; D6	= counts chars of created string
; D7	= remaining buffer length
; A0	= buffer to fill
; A1	= format string
; A2	= argument array
; A3	= trash
; A4	= temporary buffer for converted numbers
; (a7)	= 32 byte temporary string buffer

_VSNPrintF	movem.l	d2-d7/a2-a4,-(sp)
		move.l	d0,d7			;remaining buffer length
		moveq	#0,d6			;count chars
		sub.w	#32,a7			;temporary buffer for converted numbers
		bra	.mainloop

.putcharlast	bsr	.putc
		subq.l	#1,d6			;undo count for null terminator
		add.w	#32,a7
		move.l	d6,d0
		movem.l	(sp)+,_MOVEMREGS
		rts

.putc		addq.l	#1,d6			;count chars
		subq.l	#1,d7			;remaining buffer length
		ble.b	.putc_bufend
		move.b	d0,(a0)+
		beq.b	.putc_nul
		rts
.putc_bufend	bne.b	.putc_rts		;buffer already full
		clr.b	(a0)+			;write null terminator
.putc_nul	subq.l	#1,a0
.putc_rts	rts

.mainloop_putc	bsr	.putc
.mainloop	move.b	(a1)+,d0
		beq	.putcharlast
		cmpi.b	#'%',d0
		bne.b	.mainloop_putc
	; check for flags
		move.l	a7,a4			;a4 = temporary string buffer
		moveq	#0,d3			;d3 = flags
		cmpi.b	#'-',(a1)
		bne.b	.no_minus
		bset	#29,d3			;bit29 = minus
		addq.l	#1,a1
.no_minus	cmpi.b	#"'",(a1)
		bne.b	.no_group
		bset	#27,d3			;bit27 = thousands grouping
		addq.l	#1,a1
.no_group	cmpi.b	#'0',(a1)
		bne.b	.no_null
		bset	#28,d3			;bit28 = null
.no_null	bsr	.getnumber
		move.l	d0,d5
		swap	d5			;d5.hw = field width (pre dot)
		cmpi.b	#'.',(a1)
		bne.b	.no_dot
		addq.l	#1,a1
		bsr	.getnumber
		move.w	d0,d5			;d5.lw = precision (post dot)
.no_dot		cmpi.b	#'l',(a1)
		bne.b	.no_l
		bset	#30,d3			;bit30 = l (32-bit)
		addq.l	#1,a1
		cmpi.b	#'l',(a1)
		bne.b	.no_l
		bset	#31,d3			;bit31 = ll (64-bit)
		addq.l	#1,a1
	; check for type
.no_l		move.b	(a1)+,d0
		cmpi.b	#'d',d0			; signed decimal
		beq	.putints
		cmpi.b	#'x',d0			; hexadecimal
		beq	.putintx
		cmpi.b	#'s',d0			; string
		beq	.puts
		cmpi.b	#'B',d0			; BPTR, BCPL pointer
		beq	.putbptr
		cmpi.b	#'b',d0			; BSTR, BCPL string
		beq	.putbstr
		cmpi.b	#'u',d0			; unsigned decimal
		beq	.putintu
		cmpi.b	#'c',d0			; character
		bne	.mainloop_putc
		bsr	.getarg_d4		;word or long
		move.b	d4,(a4)+
	; terminate & copy temporary buffer to output
.putbuffer	clr.b	(a4)			;terminate string
		move.l	a7,a4			;rewind
	; copy a4 buffer to output
.putbuffera4	movea.l	a4,a3
		moveq	#-1,d2
.lenbufloop	tst.b	(a3)+
		dbeq	d2,.lenbufloop
		not.l	d2			;d2 = buffer length
.putbufferd2	tst.w	d5			;precision (post dot)
		beq.b	.noprec
		cmp.w	d5,d2
		bhi.b	.setprelen
.noprec		move.w	d2,d5			;precision = buffer length
.setprelen	move.l	d5,d0
		swap	d5			;field width
		sub.w	d0,d5			;d5 = field width - precision = align length
		bpl.b	.prelenok
		clr.w	d5
.prelenok	swap	d5
		btst	#29,d3			;flag minus? (left align)
		bne.b	.putbuffer_cin
		bsr.b	.align
		bra.b	.putbuffer_cin

.putbuffer_copy	move.b	(a4)+,d0
		bsr	.putc
.putbuffer_cin	dbf	d5,.putbuffer_copy
		btst	#29,d3			;flag minus? (left align)
		beq	.mainloop
		bsr.b	.align
		bra	.mainloop

.align		move.l	d5,d1
		swap	d1
		moveq	#' ',d2
		btst	#28,d3			;flag 0?
		beq.b	.align_copyin
		cmpi.b	#'-',(a4)
		bne.b	.align_not_neg
		move.b	(a4)+,d0		;'-'
		subq.w	#1,d5
		bsr	.putc
.align_not_neg	moveq	#'0',d2
		bra.b	.align_copyin

.align_copy	move.b	d2,d0
		bsr	.putc
.align_copyin	dbf	d1,.align_copy
		rts

	; get number from format string to d0
.getnumber	moveq	#0,d0
		moveq	#0,d2
.getnumber_loop	move.b	(a1)+,d2
		cmpi.b	#'0',d2
		bcs.b	.getnumber_end
		cmpi.b	#'9',d2
		bhi.b	.getnumber_end
		add.l	d0,d0			;d0 = d0 * 10
		move.l	d0,d1
		add.l	d0,d0
		add.l	d0,d0
		add.l	d1,d0
		sub.b	#'0',d2
		add.l	d2,d0			;add
		bra.b	.getnumber_loop

.getnumber_end	subq.l	#1,a1
		rts

	; get argument to d4 (16/32/64-bit)
.getarg_d4	tst.l	d3			;64-bit?
		bmi.b	.getargll_d4
		btst	#30,d3			;long?
		bne.b	.getargl_d4
		move.w	(a2)+,d4
		ext.l	d4
		rts
	; get 32-bit argument to d4
.getargl_d4	move.l	(a2)+,d4
		rts
	; get 64-bit argument to d4:d0
.getargll_d4	move.l	(a2)+,d4		;high 32 bits
		move.l	(a2)+,d0		;low 32 bits
		rts

	; string
.puts		bsr.b	.getargl_d4
		beq	.mainloop
		movea.l	d4,a4
		bra.b	.putbuffera4

	; BPTR, BCPL pointer
.putbptr	bsr.b	.getargl_d4
		lsl.l	#2,d4			;BPTR -> APTR
		bset	#30,d3			;flag l
		bra	.putintx_d4		;print as hexadecimal value

	; BSTR, BCPL string
.putbstr	bsr.b	.getargl_d4
		beq	.mainloop
		lsl.l	#2,d4			;BSTR -> APTR
		movea.l	d4,a4
		moveq	#0,d2
		move.b	(a4)+,d2		;length
		beq	.mainloop
		tst.b	(-1,a4,d2.w)		;check if last char is 0
		bne.b	.putbufferd2
		subq.w	#1,d2			;skip last char
		bra.b	.putbufferd2

	; signed decimal
.putints	bsr.b	.getarg_d4
		tst.l	d3			;64-bit?
		bmi.b	.putints64
		tst.l	d4
		bpl.b	.putintu_d4
		move.b	#'-',(a4)+
		neg.l	d4
		bra.b	.putintu_d4

	; unsigned decimal
.putintu	bsr.b	.getarg_d4
		tst.l	d3			;64-bit?
		bmi.b	.putintu64
	; d4 unsigned decimal
.putintu_d4	moveq	#'0',d0
		lea	(.dectab,pc),a3
.putint_loop	move.l	(a3)+,d1
		beq.b	.putint_end
		moveq	#'0'-1,d2
.putint_lp	addq.l	#1,d2
		sub.l	d1,d4			;subtract
		bcc.b	.putint_lp
		add.l	d1,d4			;add back
		cmp.l	d0,d2
		beq.b	.putint_loop
		moveq	#0,d0
		move.b	d2,(a4)+
		bra.b	.putint_loop

.putint_end	add.b	#'0',d4
		move.b	d4,(a4)+
		btst	#27,d3			;thousands grouping?
		beq	.putbuffer
	; insert thousands separators (commas) into temp buffer
		move.l	a4,d1
		sub.l	a7,d1			;d1 = digit count
		cmpi.b	#'-',(a7)
		bne.b	.t_count
		subq.l	#1,d1			;skip sign
.t_count	subq.l	#1,d1
		divu	#3,d1			;d1.w = (count-1)/3 = num separators
		beq	.putbuffer		;no grouping needed
		movea.l	a4,a3			;a3 = old end (source)
		add.w	d1,a4			;a4 = new end
		move.l	a4,d2			;save new end
.t_loop		move.b	-(a3),-(a4)
		move.b	-(a3),-(a4)
		move.b	-(a3),-(a4)
		move.b	#',',-(a4)
		subq.w	#1,d1
		bne.b	.t_loop
		movea.l	d2,a4			;restore a4 to new end
		bra	.putbuffer

	; signed decimal 64-bit d4:d0
.putints64	tst.l	d4			;negative?
		bpl.b	.putintu64
		move.b	#'-',(a4)+
		neg.l	d0
		negx.l	d4
	; unsigned decimal 64-bit d4:d0
.putintu64	move.l	d5,-(sp)		;save d5 (field width/precision)
		move.l	d0,d5			;d5 = low 32 bits
		lea	(.dectab64,pc),a3
.putint64_loop	move.l	(a3)+,d0		;d0 = high power
		move.l	(a3)+,d1		;d1 = low power
		beq.b	.putint64_to32		;end of table
		moveq	#'0'-1,d2		;digit counter
.putint64_lp	addq.l	#1,d2
		sub.l	d1,d5			;subtract low
		subx.l	d0,d4			;subtract high with borrow
		bcc.b	.putint64_lp
		add.l	d1,d5			;add back low
		addx.l	d0,d4			;add back high
		cmpi.b	#'0',d2			;leading zero?
		bne.b	.putint64_nz
		btst	#26,d3			;any digit written?
		beq.b	.putint64_loop		;no -> skip
.putint64_nz	bset	#26,d3			;mark digit written
		move.b	d2,(a4)+
		bra.b	.putint64_loop
	;64-bit table end reached
.putint64_to32	move.l	d5,d4			;remaining value (< 10^9)
		bclr	#26,d3			;test+clear "digit written"
		seq	d0			;d0=$FF if no digits, 0 if digits
		and.b	#'0',d0			;d0='0' suppress, 0 no suppress
		move.l	(sp)+,d5		;restore d5
		lea	(.dectab+4,pc),a3	;start at 10^8 (skip 10^9)
		bra	.putint_loop

	; hexadecimal
.putintx	bsr.b	.getarg_d4
		tst.l	d3			;64-bit?
		bmi.b	.putintx64
	; d4 hexadecimal
.putintx_d4	tst.l	d4
		beq.b	.putint_end		;only write "0"
		sf	d1			;d1 = flag already one char written
		btst	#30,d3			;flag l
		bne.b	.putintx_l
		moveq	#3,d2			;4 nibbles
		swap	d4
		bra.b	.putintx_loop
.putintx_l	moveq	#7,d2			;8 nibbles
.putintx_loop	rol.l	#4,d4
		move.b	d4,d0
		and.w	#15,d0
		bne.b	.putintx_write
		tst.b	d1			;don't write leading zeros
		beq.b	.putintx_skip
.putintx_write	st	d1			;char written
		move.b	(.hextab,pc,d0.w),(a4)+
.putintx_skip	dbf	d2,.putintx_loop
		bra	.putbuffer

.putintx64_32	move.l	d0,d4
		bra	.putintx_d4
	; hexadecimal 64-bit d4:d0
.putintx64	tst.l	d4
		beq	.putintx64_32
		move.l	d0,-(sp)		;save low 32 bits
	; output high 32 bits, suppress leading zeros
		sf	d1			;d1 = flag already one char written
		moveq	#7,d2			;8 nibbles
.putintxh_loop	rol.l	#4,d4
		move.b	d4,d0
		and.w	#15,d0
		bne.b	.putintxh_write
		tst.b	d1			;don't write leading zeros
		beq.b	.putintxh_skip
.putintxh_write	st	d1			;char written
		move.b	(.hextab,pc,d0.w),(a4)+
.putintxh_skip	dbf	d2,.putintxh_loop
	; output low 32 bits via 32-bit loop (d1=$FF, no zero suppression)
		move.l	(sp)+,d4
		bra	.putintx_l

	CNOP 0,4
.hextab		dc.b	'0123456789ABCDEF'

.dectab64	dc.l	$8AC72304,$89E80000	;10^19
		dc.l	$0DE0B6B3,$A7640000	;10^18
		dc.l	$01634578,$5D8A0000	;10^17
		dc.l	$002386F2,$6FC10000	;10^16
		dc.l	$00038D7E,$A4C68000	;10^15
		dc.l	$00005AF3,$107A4000	;10^14
		dc.l	$00000918,$4E72A000	;10^13
		dc.l	$000000E8,$D4A51000	;10^12
		dc.l	$00000017,$4876E800	;10^11
		dc.l	$00000002,$540BE400	;10^10
		dc.l	$00000000,$3B9ACA00	;10^9
		dc.l	0,0			;end of table

.dectab		dc.l	1000000000
		dc.l	100000000
		dc.l	10000000
		dc.l	1000000
		dc.l	100000
		dc.l	10000
		dc.l	1000
		dc.l	100
		dc.l	10
		dc.l	0

	ENDC
		ENDM

;---------------------------------------------------------------------------

	ENDC
 
