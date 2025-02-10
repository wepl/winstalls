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
		IFND	_LVORawDoFmt
			INCLUDE lvo/exec.i
		ENDC
_FormatString	movem.l	a2-a3/a6,-(a7)
		lea	(.bufend),a3
		add.l	a2,d0
		move.l	d0,(a3)
		move.l	a2,a3
		lea	(.PutChar),a2
		move.l	(gl_execbase,GL),a6
		jsr	(_LVORawDoFmt,a6)
		movem.l	(a7)+,a2-a3/a6
		rts

.PutChar	move.b	d0,(a3)+
		cmp.l	(.bufend),a3
		bne	.PC_ok
		subq.l	#1,a3
.PC_ok		rts	

.bufend		dc.l	0
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
; D3	= flags 0=minus 1=null 2=long
; D4	= argument value
; D5.lw	= precision length (post dot)
; D5.hw	= field length (pre dot)
; D6	= counts chars of created string
; D7	= remaining buffer length
; A0	= buffer to fill
; A1	= format string
; A2	= argument array
; A3	= trash
; A4	= temporary buffer for converted numbers
; (a7)	= 16 byte temporary string buffer

_VSNPrintF	movem.l	d2-d7/a2-a4,-(sp)
		move.l	d0,d7			;remaining buffer length
		moveq	#0,d6			;count chars
		sub.w	#16,a7			;temporary buffer for converted numbers
		bra	.mainloop

.putcharlast	bsr	.putc
		add.w	#16,a7
		move.l	d6,d0
		movem.l	(sp)+,_MOVEMREGS
		rts

.putc_term	clr.b	(a0)
.putc_count	tst.b	d0
		beq	.putc_rts
.putc_inc	addq.l	#1,d6
.putc_rts	rts

.putc		subq.l	#1,d7
		bmi	.putc_count
		beq	.putc_term
		move.b	d0,(a0)+
		bne	.putc_inc
		subq.l	#1,a0
		rts

.mainloop_putc	bsr	.putc
.mainloop	move.b	(a1)+,d0
		beq	.putcharlast
		cmpi.b	#'%',d0
		bne.b	.mainloop_putc
		move.l	a7,a4			;a4 = buffer 10 bytes for numbers
		moveq	#0,d3			;d3 = flags
		cmpi.b	#'-',(a1)
		bne.b	.no_minus
		bset	#0,d3			;bit0=minus
		addq.l	#1,a1
.no_minus	cmpi.b	#'0',(a1)
		bne.b	.no_null
		bset	#1,d3			;bit1=null
.no_null	bsr.w	.getnumber
		move.l	d0,d5
		swap	d5			;d5.hw=field width (pre dot)
		cmpi.b	#'.',(a1)
		bne.b	.no_dot
		addq.l	#1,a1
		bsr.w	.getnumber
		move.w	d0,d5			;d5.lw=precision (post dot)
.no_dot		cmpi.b	#'l',(a1)
		bne.b	.no_l
		bset	#2,d3			;bit2=l
		addq.l	#1,a1

.no_l		move.b	(a1)+,d0
		cmpi.b	#'d',d0
		beq.b	.d
		cmpi.b	#'D',d0
		bne.b	.notd
.d		bsr.b	.getarg_d4
		bsr.w	.putints
		bra.w	.putbuffer

.notd		cmpi.b	#'x',d0
		beq.b	.x
		cmpi.b	#'X',d0
		bne.b	.notx
.x		bsr.b	.getarg_d4
.xput		bsr.w	.putintx
		bra.b	.putbuffer

.getarg_d4	btst	#2,d3			;long?
		bne.b	.getargl_d4
		move.w	(a2)+,d4
		ext.l	d4
		rts

.getargl_d4	move.l	(a2)+,d4
		rts

.notx		cmpi.b	#'s',d0
		bne.b	.nots
		bsr.b	.getargl_d4
		beq	.mainloop
		movea.l	d4,a4
		bra.b	.putbuffera4

.nots		cmpi.b	#'B',d0			;BPTR
		bne.b	.notbptr
		bsr.b	.getargl_d4
		lsl.l	#2,d4			;BPTR -> APTR
		bset	#2,d3			;flag l
		bra	.xput

.notbptr	cmpi.b	#'b',d0			;BSTR
		bne.b	.notbstr
		bsr.b	.getargl_d4
		beq	.mainloop
		lsl.l	#2,d4			;BSTR -> APTR
		movea.l	d4,a4
		moveq	#0,d2
		move.b	(a4)+,d2
		beq	.mainloop
		tst.b	(-1,a4,d2.w)
		bne.b	.putbufferd2
		subq.w	#1,d2
		bra.b	.putbufferd2

.notbstr	cmpi.b	#'u',d0
		beq.b	.u
		cmpi.b	#'U',d0
		bne.b	.notu
.u		bsr.b	.getarg_d4
		bsr.w	.putintu
		bra.b	.putbuffer

.notu		cmpi.b	#'c',d0
		bne	.mainloop_putc
		bsr.b	.getarg_d4
		move.b	d4,(a4)+
.putbuffer	clr.b	(a4)		;terminate string
		move.l	a7,a4		;rewind
.putbuffera4	movea.l	a4,a3
		moveq	#-1,d2
.lenbufloop	tst.b	(a3)+
		dbeq	d2,.lenbufloop
		not.l	d2		;d2 = buffer length
.putbufferd2	tst.w	d5		;precision (post dot)
		beq.b	.noprec
		cmp.w	d5,d2
		bhi.b	.setprelen
.noprec		move.w	d2,d5		;precision = buffer length
.setprelen	move.l	d5,d0
		swap	d5		;field width
		sub.w	d0,d5		;d5 = field width - precision = align length
		bpl.b	.prelenok
		clr.w	d5
.prelenok	swap	d5
		btst	#0,d3		;flag minus? (left align)
		bne.b	.putbuffer_cin
		bsr.b	.align
		bra.b	.putbuffer_cin

.putbuffer_copy	move.b	(a4)+,d0
		bsr	.putc
.putbuffer_cin	dbra	d5,.putbuffer_copy
		btst	#0,d3		;flag minus? (left align)
		beq	.mainloop
		bsr.b	.align
		bra	.mainloop

.align		move.l	d5,d1
		swap	d1
		moveq	#' ',d2
		btst	#1,d3		;flag 0?
		beq.b	.align_copyin
		cmpi.b	#'-',(a4)
		bne.b	.align_not_neg
		move.b	(a4)+,d0	;'-'
		subq.w	#1,d5
		bsr	.putc
.align_not_neg	moveq	#'0',d2
		bra.b	.align_copyin

.align_copy	move.b	d2,d0
		bsr	.putc
.align_copyin	dbra	d1,.align_copy
		rts

.getnumber	moveq	#0,d0
		moveq	#0,d2
.getnumber_loop	move.b	(a1)+,d2
		cmpi.b	#'0',d2
		bcs.b	.getnumber_end
		cmpi.b	#'9',d2
		bhi.b	.getnumber_end
		add.l	d0,d0
		move.l	d0,d1
		add.l	d0,d0
		add.l	d0,d0
		add.l	d1,d0
		sub.b	#'0',d2
		add.l	d2,d0
		bra.b	.getnumber_loop

.getnumber_end	subq.l	#1,a1
		rts

.putints	tst.l	d4
		bpl.b	.putintu
		move.b	#'-',(a4)+
		neg.l	d4
.putintu	moveq	#'0',d0
		lea	(.dectab,pc),a3
.putint_loop	move.l	(a3)+,d1
		beq.b	.putint_end
		moveq	#'/',d2
.putint_lp	addq.l	#1,d2
		sub.l	d1,d4
		bcc.b	.putint_lp
		add.l	d1,d4
		cmp.l	d0,d2
		beq.b	.putint_loop
		moveq	#0,d0
		move.b	d2,(a4)+
		bra.b	.putint_loop

.putint_end	moveq	#'0',d0
		add.b	d0,d4
		move.b	d4,(a4)+
		rts

.putintx	tst.l	d4
		beq.b	.putint_end
		clr.w	d1			;d1 flag already char written
		btst	#2,d3			;flag l
		bne.b	.putintx_l
		moveq	#3,d2
		swap	d4
		bra.b	.putintx_loop

.putintx_l	moveq	#7,d2
.putintx_loop	rol.l	#4,d4
		move.b	d4,d0
		and.b	#15,d0
		bne.b	.putintx_write
		tst.w	d1
		beq.b	.putintx_skip
.putintx_write	moveq	#-1,d1
		cmp.b	#9,d0
		bhi.b	.putintx_alpha
		add.b	#'0',d0
		bra.b	.putintx_set

.putintx_alpha	add.b	#'7',d0
.putintx_set	move.b	d0,(a4)+
.putintx_skip	dbra	d2,.putintx_loop
		rts

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
 
