;*---------------------------------------------------------------------------
;  :Modul.	keyboard.s
;  :Contents.	routine to setup an keyboard handler
;  :History.	30.08.97 extracted from some slave sources
;		17.11.97 _keyexit2 added
;		23.12.98 _key_help added
;		07.10.99 some cosmetic changes, documentation improved
;		24.10.99 _keycode added
;		15.05.03 better interrupt acknowledge
;		04.03.04 clearing sdr removed, seems not required/causing
;			 problems
;		19.08.06 _key_check added (DJ Mike)
;		15.02.10 restructured and made _KeyboardHandle a global
;			 routine which doesn't affect interrupt acknowledge
;			 to be able to call it from an existing PORTS
;			 interrupt handler (PygmyProjects_Extension)
;		21.03.12 pc-relative for _resload access removed, because W.O.C. uses absolut
;		26.09.19 using cia-timer-a for acknowledge delay
;		08.11.19 resload_Abort args for debug key fixed for 68000
;  :Requires.	_keydebug	byte variable containing rawkey code
;		_keyexit	byte variable containing rawkey code
;  :Optional.	_keyexit2	byte variable containing rawkey code
;		_key_help	function to execute on help pressed
;		_debug		function to quit with debug
;		_exit		function to quit
;		_keycode	variable/memory filled with rawkey
;		_key_check	routine will be called with rawkey in d0
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*
; this routine setups a keyboard handler, realizing quit and quit-with-debug
; feature by pressing the appropriate key. the following variables must be
; defined:
;	_keyexit
;	_keydebug
; the labels should refer to the Slave structure, so user definable quit- and
; debug-key will be supported
;
; the optional variable:
;	_keyexit2
; can be used to specify a second quit-key, if a quit by two different keys
; should be supported
;
; the optional function:
;	_key_help
; will be called when the 'help' key is pressed, the function must return via
; 'rts' and must not change any registers
;
; the optional function:
;	_key_check
; will be called after ANY key is pressed. The keycode will be in d0.
; The function must return using 'rts' and must not modify any registers
;
; the optional variable:
;	 _keycode
; will be filled with the last rawkeycode
;
; IN:	-
; OUT:	-

_SetupKeyboard	move.l	a0,-(a7)
	;set the interrupt vector
		lea	(.int,pc),a0
		move.l	a0,($68)
	;init timer-a (~200 µs)
		lea	(_ciaa),a0
		move.b	#142,(ciatalo,a0)
		sf	(ciatahi,a0)
	;allow interrupts from the keyboard & timer-a
		move.b	#$7f,(ciaicr,a0)
		move.b	#CIAICRF_SETCLR|CIAICRF_SP|CIAICRF_TA,(ciaicr,a0)
	;clear all ciaa-interrupt requests
		tst.b	(ciaicr,a0)
	;set input mode
		and.b	#~(CIACRAF_SPMODE),(ciacra,a0)
	;clear ports interrupt
		move	#INTF_PORTS,(_custom+intreq)
	;allow ports interrupt
		move	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,(_custom+intena)
		move.l	(a7)+,a0
		rts

.int		movem.l	d0/a0-a1,-(a7)
		lea	(_custom),a0
		lea	(_ciaa),a1

	;check if keyboard has caused interrupt
		btst	#INTB_PORTS,(intreqr+1,a0)
		beq	.end
	;timer-a
		move.b	(ciaicr,a1),d0
		btst	#CIAICRB_TA,d0
		beq	.sp
	;set input mode (handshake end)
		sf	(ciacra,a1)
		bra	.end
	;sp	
.sp		btst	#CIAICRB_SP,d0
		beq	.end
	;read keycode
		move.b	(ciasdr,a1),d0
	;set output mode (handshake start)
		move.b	#CIACRAF_SPMODE|CIACRAF_LOAD|CIACRAF_RUNMODE|CIACRAF_START,(ciacra,a1)
	;calculate rawkeycode
		not.b	d0
		ror.b	#1,d0
	;check for debug key
		cmp.b	(_keydebug,pc),d0
		bne	.nodebug
		movem.l	(a7)+,d0/a0-a1			;restore
	;transform stackframe to resload_Abort arguments
		movem.l	d0-d1/a0-a1,-(a7)
		clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_ATTNFLAGS_GET
		move.l	a7,a0
		move.l	(_resload),a1			;no ',pc' because used absolut sometimes
		jsr	(resload_Control,a1)
		btst	#AFB_68010,(7,a7)
		lea	(12,a7),a7
		movem.l	(a7)+,d0-d1/a0-a1
		bne	.68010
	;68000 6-byte stackframe
		move.l	(4,a7),-(a7)			;pc
		move.w	(4,a7),(8,a7)			;sr
		clr.w	(6,a7)				;ext.l sr
		move.l	(a7),(4,a7)			;pc
		addq.l	#2,a7
	IFD _debug
		bra	_debug
	ELSE
		bra	.debug
	ENDC
	;68010+ 8-byte stackframe
.68010		move.w	(a7),(6,a7)			;sr
		move.l	(2,a7),(a7)			;pc
		clr.w	(4,a7)				;ext.l sr
	IFD _debug
		bra	_debug
	ELSE
		bra	.debug
	ENDC
	;check for quit key
.nodebug	cmp.b	(_keyexit,pc),d0
	IFD _exit
		beq	_exit
	ELSE
		beq	.exit
	ENDC
	IFD _keyexit2
		cmp.b	(_keyexit2,pc),d0
	IFD _exit
		beq	_exit
	ELSE
		beq	.exit
	ENDC
	ENDC
	;check for help key
	IFD _key_help
		cmp.b	#$5f,d0
		bne	.nohelp
		bsr	_key_help
.nohelp
	ENDC
	;call custom routine
	IFD _key_check
		bsr	_key_check
	ENDC
	;save keycode
	IFD _keycode
		lea	(_keycode),a1			;no ',pc' because used absolut sometimes
		move.b	d0,(a1)
	ENDC

.end		move	#INTF_PORTS,(intreq,a0)
	;to avoid timing problems on very fast machines we do another
	;custom register access
		tst	(intreqr,a0)
		movem.l	(a7)+,d0/a0-a1
		rte

	IFND _exit
.debug		pea	TDREASON_DEBUG.w
.quit		move.l	(_resload),-(a7)		;no ',pc' because used absolut sometimes
		addq.l	#resload_Abort,(a7)
		rts
.exit		pea	TDREASON_OK.w
		bra	.quit
	ENDC

