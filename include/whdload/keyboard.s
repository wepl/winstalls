;*---------------------------------------------------------------------------
;  :Program.	keyboard.s
;  :Contents.	routine to setup an keyboard handler
;  :Version.	$Id: interphase.asm 1.6 1998/05/25 15:45:29 jah Exp jah $
;  :History.	30.08.97 extracted from some slave sources
;		17.11.97 _keyexit2 added
;  :Requires.	_keydebug	byte variable containing rawkey code
;		_keyexit	byte variable containing rawkey code
;		_debug		function to quit with debug
;		_exit		function to quit
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

; IN:	-
; OUT:	d0-d1/a0-a1 destroyed

_SetupKeyboard	lea	(.int2),a0
		move.l	a0,($68)			;set interrupt vector
		lea	(_ciaa),a1
		move.b	#CIAICRF_SETCLR|CIAICRF_SP,(ciaicr,a1)	;allow ints from keyboard
		tst.b	(ciaicr,a1)			;clear all intreq
		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)	;input mode
		move.w	#INTF_PORTS,(intreq+_custom)
		move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(intena+_custom)
		rts

.int2		movem.l	d0-d1/a1,-(a7)
		lea	(_ciaa),a1
		btst	#CIAICRB_SP,(ciaicr,a1)		;check int reason
		beq	.int2_exit
		move.b	(ciasdr,a1),d0			;read code
		clr.b	(ciasdr,a1)			;output LOW (handshake)
		or.b	#CIACRAF_SPMODE,(ciacra,a1)	;to output
		not.b	d0
		ror.b	#1,d0

		cmp.b	(_keydebug),d0
		bne	.int2_1
		movem.l	(a7)+,d0-d1/a1
		move.w	(a7),(6,a7)			;sr
		move.l	(2,a7),(a7)			;pc
		clr.w	(4,a7)				;ext.l sr
		bra	_debug

.int2_1		cmp.b	(_keyexit),d0
		beq	_exit
	IFD _keyexit2
		cmp.b	(_keyexit2),d0
		beq	_exit
	ENDC

		moveq	#3-1,d1				;wait because handshake min 75 탎
.int2_w1	move.b	(_custom+vhposr),d0
.int2_w2	cmp.b	(_custom+vhposr),d0		;one line is 63.5 탎
		beq	.int2_w2
		dbf	d1,.int2_w1			;(min=127탎 max=190.5탎)

		and.b	#~(CIACRAF_SPMODE),(ciacra,a1)	;to input
.int2_exit	move.w	#INTF_PORTS,(intreq+_custom)
		movem.l	(a7)+,d0-d1/a1
		rte

