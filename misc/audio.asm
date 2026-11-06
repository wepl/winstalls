;*---------------------------------------------------------------------------
;  :Program.	audio.asm
;  :Contents.	Slave to check resload_Audio
;  :Author.	Wepl
;  :History.	2026-10-25 created
;  :Requires.	WHDLoad 21+, option Audio/K set to a directory containing track01.<ext> .. track09.<ext>
;		whdload audio.slave audio=cdda nowritecache trace
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Vasm
;  :To Do.
;---------------------------------------------------------------------------*
; keys:
;	1-9		play track 1-9 (with actual loop mode)
;	n		play track 99 (normally not existing)
;	l		toggle loop mode
;	space		stop
;	cursor up/down	volume, changed every frame while pressed, step increases
;	s		get status via normal call
;	o		resload_SaveFile to force a switch to the OS (suspend/resume)
;	h		disable ports interrupt for 2 seconds (fifo underrun)
;	q		quit
; displayed:
;	status from the main loop and from the VBI (fast path of WHDLAUDC_STATUS)
;	ports interrupts per VBI, maximum and per second
;	last 18 commands with result and duration (measured via ciab tod/hsyncs),
;	oldest first, scrolls up if more than 18 commands

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"ram:audio.slave"
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	ENDC

;======================================================================
; entry of the command history

HISTSIZE	= 18			;commands shown, y=60..166, help starts at y=170

	STRUCTURE	HistEntry,0
		APTR	he_name		;command name
		ULONG	he_d1		;command arguments
		ULONG	he_d2
		ULONG	he_res		;command result
		ULONG	he_lines	;command duration in hsyncs
		LABEL	he_SIZEOF

;======================================================================
; variables, accessed via base register because the 68000 has no pc-relative
; destination addressing and the Slave must not contain relocations

	STRUCTURE	Vars,0
		APTR	v_kbdint	;level 2 interrupt of keyboard.s
		ULONG	v_loop		;flags for play
		ULONG	v_volume	;actual volume
		ULONG	v_portscnt	;ports interrupts counter
		ULONG	v_portsvbi	;ports interrupts during last vbi
		ULONG	v_portsmax	;maximum ports interrupts per vbi
		ULONG	v_portssum	;ports interrupts sum for actual second
		ULONG	v_portssec	;ports interrupts during last second
		ULONG	v_seccnt	;vbi counter for one second
		ULONG	v_vbistatus	;status got from vbi
		ULONG	v_playframes	;frames playing
		ULONG	v_holdcnt	;frames ports interrupt remains disabled
		ULONG	v_starttime	;tod at start of command
		APTR	v_lastname	;last command name
		ULONG	v_lastd1	;last command arguments
		ULONG	v_lastd2
		ULONG	v_lastres	;last command result
		ULONG	v_lastlines	;last command duration in hsyncs
		ULONG	v_volheld	;frames volume key is pressed
		ULONG	v_histcnt	;entries in v_hist
		STRUCT	v_hist,HISTSIZE*he_SIZEOF	;command history, oldest first
		BYTE	v_volkey	;volume key pressed: 1 = up, -1 = down, 0 = none
		UBYTE	v_newkey	;last pressed rawkey, 0 = none
		BYTE	v_histnew	;history changed, must be redrawn
		ALIGNLONG
		LABEL	v_SIZEOF

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	21			;ws_Version
		dc.w	0			;ws_flags
		dc.l	$70000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config
		dc.w	0			;ws_MemConfig

_name		dc.b	"Test Audio Slave",0
_copy		dc.b	"2026 Wepl",0
_info		dc.b	"done by Wepl "
	INCBIN	".date"
_config		dc.b	0
	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a5			;A5 = resload
		lea	(_vars,pc),a4		;A4 = variables
		lea	(_custom),a6		;A6 = custom
		sub	#16,a7			;hrtmon
		bsr	_SetupKeyboard
	;count ports interrupts, then continue in the keyboard handler
		move.l	($68),(v_kbdint,a4)
		lea	(_int68,pc),a0
		move.l	a0,($68)

SCREENWIDTH	= 320
SCREENHEIGHT	= 200
CHARHEIGHT	= 5
CHARWIDTH	= 5
LINE		= CHARHEIGHT+1

MEMCOPPER	= $e000
MEMSCREEN	= $10000

VOLSTEPMAX	= $200
HOLDFRAMES	= 100

	;clear screen
		lea	(MEMSCREEN),a0
		move	#SCREENHEIGHT*SCREENWIDTH/8/4-1,d0
.cl		clr.l	(a0)+
		dbf	d0,.cl
	;init gfx
		lea	(_copper),a0
		lea	(MEMCOPPER),a1
		move.l	a1,(cop1lc,a6)
.n		move.l	(a0)+,(a1)+
		bpl	.n
		waitvb a6
		move	#DMAF_SETCLR|DMAF_MASTER|DMAF_COPPER|DMAF_RASTER,(dmacon,a6)
	;get whdload
		lea	(_tags),a0
		jsr	(resload_Control,a5)
	;init variables
		move.l	#$7fff,(v_volume,a4)
		move.l	#50,(v_seccnt,a4)
	;init vbi
		lea	(_vbi,pc),a0
		move.l	a0,($6c)
		move	#INTF_VERTB,(intreq,a6)
		move	#INTF_SETCLR|INTF_INTEN|INTF_VERTB,(intena,a6)
		waitvb	a6

	;print static text
		moveq	#0,d0
		moveq	#1,d1
		lea	_top1,a0
		bsr	_ps
		moveq	#0,d0
		moveq	#1+LINE,d1
		lea	_top2,a0
		move.l	_build,-(a7)
		move.l	_rev,-(a7)
		move.l	_ver,-(a7)
		move.l	a7,a1
		bsr	_ps
		add	#3*4,a7
		lea	_help,a2
		move.l	#SCREENHEIGHT-5*LINE,d1
.help		moveq	#0,d0
		move.l	a2,a0
		bsr	_ps
		addq.l	#LINE,d1
.helpskip	tst.b	(a2)+
		bne	.helpskip
		tst.b	(a2)
		bne	.help

	;main loop
.loop		waitvb	a6
		bsr	_keys
		bsr	_volume
		bsr	_display
		bra	.loop

;--------------------------------
; handle pressed keys

_keys		moveq	#0,d0
		move.b	(v_newkey,a4),d0
		beq	.rts
		sf	(v_newkey,a4)
		cmp.b	#$10,d0			;q
		beq	.quit
		cmp.b	#$40,d0			;space
		beq	.stop
		cmp.b	#$28,d0			;l
		beq	.loopmode
		cmp.b	#$21,d0			;s
		beq	.status
		cmp.b	#$18,d0			;o
		beq	.save
		cmp.b	#$25,d0			;h
		beq	.hold
		cmp.b	#$36,d0			;n
		beq	.play99
		subq.b	#1,d0			;1..9 = $01..$09
		cmp.b	#8,d0
		bhi	.rts
		addq.b	#1,d0
		move.l	d0,d1			;track
.play		clr.l	(v_playframes,a4)
		moveq	#WHDLAUDC_PLAY,d0
		move.l	(v_loop,a4),d2
		lea	_cmd_play,a0
		bra	_cmd
.play99		moveq	#99,d1
		bra	.play

.stop		moveq	#WHDLAUDC_STOP,d0
		moveq	#0,d1
		moveq	#0,d2
		lea	_cmd_stop,a0
		bra	_cmd

.status		moveq	#WHDLAUDC_STATUS,d0
		moveq	#0,d1
		moveq	#0,d2
		lea	_cmd_status,a0
		bra	_cmd

.loopmode	bchg	#WHDLAUDB_LOOP,(v_loop+3,a4)
.rts		rts

.save		lea	_cmd_save,a0
		clr.l	(v_lastd1,a4)
		clr.l	(v_lastd2,a4)
		bsr	_timestart
		move.l	#_stuffend-_base,d0	;size
		lea	_savename,a0
		lea	_base,a1
		jsr	(resload_SaveFile,a5)
		bra	_timestop

.hold		move.l	#HOLDFRAMES,(v_holdcnt,a4)
		move	#INTF_PORTS,(intena,a6)
		rts

.quit		pea	TDREASON_OK
		jmp	(resload_Abort,a5)

;--------------------------------
; change volume while a cursor key is pressed

_volume		move.b	(v_volkey,a4),d0
		bne	.held
		clr.l	(v_volheld,a4)
		rts

.held		addq.l	#1,(v_volheld,a4)
		move.l	(v_volheld,a4),d2
		lsl.l	#4,d2			;step = frames pressed * $10
		cmp.l	#VOLSTEPMAX,d2
		bls	.step
		move.l	#VOLSTEPMAX,d2
.step		move.l	(v_volume,a4),d1
		tst.b	d0
		bmi	.down
		add.l	d2,d1
		cmp.l	#$7fff,d1
		bls	.set
		move.l	#$7fff,d1
		bra	.set
.down		sub.l	d2,d1
		bpl	.set
		moveq	#0,d1
.set		cmp.l	(v_volume,a4),d1
		beq	.rts
		move.l	d1,(v_volume,a4)
		moveq	#WHDLAUDC_VOLUME,d0
		moveq	#0,d2
		lea	_cmd_volume,a0
		bra	_cmd
.rts		rts

;--------------------------------
; call resload_Audio and measure the duration
; IN:	d0/d1/d2 = arguments
;	a0 = CPTR name of the command
; OUT:	-

_cmd		move.l	d1,(v_lastd1,a4)
		move.l	d2,(v_lastd2,a4)
		bsr	_timestart
		jsr	(resload_Audio,a5)
	;fall through

;--------------------------------
; stop time measurement
; IN:	d0 = ULONG result
; OUT:	-

_timestop	move.l	d0,(v_lastres,a4)
		move.l	d5,-(a7)
		bsr	_getec
		sub.l	(v_starttime,a4),d5
		and.l	#$ffffff,d5		;tod is 24 bit
		move.l	d5,(v_lastlines,a4)
		move.l	(a7)+,d5
	;fall through

;--------------------------------
; append last command to the history, if full remove the oldest entry
; IN:	-
; OUT:	-
;	all registers preserved

_histadd	movem.l	d0/a0-a1,-(a7)
		lea	(v_hist,a4),a1
		move.l	(v_histcnt,a4),d0
		cmp.l	#HISTSIZE,d0
		blo	.free
	;full, scroll, afterwards a1 points to the last entry
		lea	(he_SIZEOF,a1),a0
		move	#(HISTSIZE-1)*he_SIZEOF/4-1,d0
.scroll		move.l	(a0)+,(a1)+
		dbf	d0,.scroll
		bra	.set
.free		addq.l	#1,(v_histcnt,a4)
		mulu	#he_SIZEOF,d0
		add.l	d0,a1
.set		move.l	(v_lastname,a4),(he_name,a1)
		move.l	(v_lastd1,a4),(he_d1,a1)
		move.l	(v_lastd2,a4),(he_d2,a1)
		move.l	(v_lastres,a4),(he_res,a1)
		move.l	(v_lastlines,a4),(he_lines,a1)
		st	(v_histnew,a4)
		movem.l	(a7)+,_MOVEMREGS
		rts

;--------------------------------
; start time measurement
; IN:	a0 = CPTR name of the command
; OUT:	-
;	all registers preserved

_timestart	move.l	a0,(v_lastname,a4)
		move.l	d5,-(a7)
		bsr	_getec
		move.l	d5,(v_starttime,a4)
		move.l	(a7)+,d5
		rts

;--------------------------------
; print actual state

_display	moveq	#4*LINE,d1

	;track, loop, volume
		move.l	(v_volume,a4),-(a7)
		lea	_off,a0
		tst.l	(v_loop,a4)
		beq	.loopoff
		lea	_on,a0
.loopoff	move.l	a0,-(a7)
		moveq	#0,d0
		lea	_fmt_mode,a0
		move.l	a7,a1
		bsr	_ps
		addq.l	#2*4,a7

	;status
		add.l	#2*LINE,d1
		move.l	(v_playframes,a4),d0
		divu	#50,d0			;frames:seconds
		swap	d0
		moveq	#0,d2
		move	d0,d2
		add.l	d2,d2			;1/100 seconds
		move.l	d2,-(a7)
		clr	d0
		swap	d0
		divu	#60,d0
		move.l	d0,d2
		clr	d2
		swap	d2
		move.l	d2,-(a7)		;seconds
		and.l	#$ffff,d0
		move.l	d0,-(a7)		;minutes
		move.l	(v_vbistatus,a4),-(a7)
		move.l	d1,d2			;resload destroys d1
		moveq	#WHDLAUDC_STATUS,d0
		jsr	(resload_Audio,a5)
		move.l	d2,d1
		move.l	d0,-(a7)
		moveq	#0,d0
		lea	_fmt_status,a0
		move.l	a7,a1
		bsr	_ps
		add	#5*4,a7

	;ports interrupts
		add.l	#2*LINE,d1
		move.l	(v_portssec,a4),-(a7)
		move.l	(v_portsmax,a4),-(a7)
		move.l	(v_portsvbi,a4),-(a7)
		moveq	#0,d0
		lea	_fmt_ports,a0
		move.l	a7,a1
		bsr	_ps
		add	#3*4,a7

	;hold ports
		addq.l	#LINE,d1
		lea	_fmt_nohold,a0
		move.l	(v_holdcnt,a4),-(a7)
		beq	.nohold
		lea	_fmt_hold,a0
.nohold		moveq	#0,d0
		move.l	a7,a1
		bsr	_ps
		addq.l	#4,a7

	;command history
		addq.l	#LINE,d1
	;fall through

;--------------------------------
; print the command history, oldest first, only if it has changed
; IN:	d1 = y of the first line
; OUT:	-

_disphist	tst.b	(v_histnew,a4)
		beq	.rts
		sf	(v_histnew,a4)
		movem.l	d0-d3/a0-a2,-(a7)
		lea	(v_hist,a4),a2
		move.l	(v_histcnt,a4),d3
		bra	.in

.loop		move.l	(he_lines,a2),d0
		lsl.l	#3,d0			;ms = lines * 64 / 1000
		cmp.l	#125*$10000,d0
		blo	.ms
		move.l	#125*$ffff,d0
.ms		divu	#125,d0
		and.l	#$ffff,d0
		move.l	d0,-(a7)
		move.l	(he_lines,a2),-(a7)
		move.l	(he_res,a2),-(a7)
		move.l	(he_d2,a2),-(a7)
		move.l	(he_d1,a2),-(a7)
		move.l	(he_name,a2),-(a7)
		moveq	#0,d0
		lea	_fmt_hist,a0
		move.l	a7,a1
		bsr	_ps
		add	#6*4,a7
		add	#he_SIZEOF,a2
		addq.l	#LINE,d1
.in		dbf	d3,.loop

		movem.l	(a7)+,_MOVEMREGS
.rts		rts

;--------------------------------
; level 2 interrupt, count and continue in keyboard handler

_int68		subq.l	#4,a7			;space for the jump address
		move.l	a0,-(a7)
		lea	(_vars,pc),a0
		addq.l	#1,(v_portscnt,a0)
		move.l	(v_kbdint,a0),(4,a7)
		move.l	(a7)+,a0
		rts

;--------------------------------
; keyboard callback, called from the level 2 interrupt
; IN:	d0 = rawkey
; OUT:	all registers preserved

_key_check	move.l	a0,-(a7)
		lea	(_vars,pc),a0
		cmp.b	#$4c,d0			;cursor up pressed
		beq	.up
		cmp.b	#$4d,d0			;cursor down pressed
		beq	.down
		cmp.b	#$4c|$80,d0		;cursor up released
		beq	.release
		cmp.b	#$4d|$80,d0		;cursor down released
		beq	.release
		tst.b	d0
		bmi	.end			;other key released
		move.b	d0,(v_newkey,a0)
		bra	.end
.up		move.b	#1,(v_volkey,a0)
		bra	.end
.down		st	(v_volkey,a0)
		bra	.end
.release	sf	(v_volkey,a0)
.end		move.l	(a7)+,a0
		rts

;--------------------------------
; level 3 interrupt

_vbi		movem.l	d0-d1/a0-a1/a4,-(a7)
		lea	(_vars,pc),a4
		move	#INTF_VERTB,(_custom+intreq)
	;ports interrupts per vbi
		move.l	(v_portscnt,a4),d0
		clr.l	(v_portscnt,a4)
		move.l	d0,(v_portsvbi,a4)
		cmp.l	(v_portsmax,a4),d0
		bls	.nomax
		move.l	d0,(v_portsmax,a4)
.nomax		add.l	d0,(v_portssum,a4)
		subq.l	#1,(v_seccnt,a4)
		bne	.nosec
		move.l	#50,(v_seccnt,a4)
		move.l	(v_portssum,a4),(v_portssec,a4)
		clr.l	(v_portssum,a4)
.nosec
	;status from interrupt (fast path)
		moveq	#WHDLAUDC_STATUS,d0
		move.l	(_resload),a1
		jsr	(resload_Audio,a1)
		move.l	d0,(v_vbistatus,a4)
		beq	.noplay
		addq.l	#1,(v_playframes,a4)
.noplay
	;reenable ports interrupt after hold
		tst.l	(v_holdcnt,a4)
		beq	.nohold
		subq.l	#1,(v_holdcnt,a4)
		bne	.nohold
		move	#INTF_SETCLR|INTF_PORTS,(_custom+intena)
.nohold
		tst	(_custom+intreqr)
		movem.l	(a7)+,_MOVEMREGS
		rte

	CNOP 0,4
_tags		dc.l	WHDLTAG_VERSION_GET
_ver		dc.l	0
		dc.l	WHDLTAG_REVISION_GET
_rev		dc.l	0
		dc.l	WHDLTAG_BUILD_GET
_build		dc.l	0
		dc.l	TAG_DONE

;--------------------------------
; get event counter ciab (hsyncs)
; OUT:	d5 = ULONG counter

_getec		moveq	#0,d5
		move.b	_ciab+ciatodhi,d5
		lsl	#8,d5
		move.b	_ciab+ciatodmid,d5
		lsl.l	#8,d5
		move.b	_ciab+ciatodlow,d5
		rts

;--------------------------------
; print formatted string (printf)
; IN:	d0 = word x
;	d1 = word y
;	a0 = cptr string
;	a1 = aptr args
; OUT:	d0 = word new x

_ps		movem.l	d0-d2/a2,-(a7)
		moveq	#100,d0		;buflen
		sub.l	d0,a7
		move.l	a1,a2		;args
		move.l	a0,a1		;fmt
		move.l	a7,a0		;buffer
		jsr	(resload_VSNPrintF,a5)
		movem.l	(100,a7),d0-d1
		move.l	a7,a0
		moveq	#0,d2
		bra	.in
.next		bsr	_pc
		add	#CHARWIDTH,d0
.in		move.b	(a0)+,d2
		bne	.next
		add	#104,a7
		movem.l	(a7)+,d1-d2/a2
		rts

;--------------------------------
; print char
; IN:	d0 = word x
;	d1 = word y
;	d2 = ascii char

_pc		movem.l	d0-d5/a0-a1,-(a7)
		lea	(MEMSCREEN),a0
		mulu	#SCREENWIDTH/8,d1
		add.l	d1,a0
		sub	#32,d2				;starts at $20
		mulu	#CHARWIDTH,d2
		lea	(_font),a1
		moveq	#CHARHEIGHT-1,d3
.cp
	IFD _68020_
		bfextu	(a1){d2:CHARWIDTH},d1
		bfins	d1,(a0){d0:CHARWIDTH}
	ELSE
		move.l	d2,d1
		lsr.l	#4,d1				;words
		add.l	d1,d1				;bytes down rounded to word
		move.l	(a1,d1.l),d1
		move.l	d2,d4
		and	#%1111,d4
		lsl.l	d4,d1

		moveq	#-1,d5
		lsr.l	#CHARWIDTH,d5
		not.l	d5
		and.l	d5,d1
		not.l	d5

		move.l	d0,d4
		and	#%1111,d4
		lsr.l	d4,d1
		ror.l	d4,d5
		move.l	d0,d4
		lsr.l	#4,d4				;words
		add.l	d4,d4				;bytes down rounded to word
		and.l	d5,(a0,d4.l)
		or.l	d1,(a0,d4.l)
	ENDC
		add.l	#(_font_-_font)*8/CHARHEIGHT,d2
		add.l	#SCREENWIDTH,d0
		dbf	d3,.cp
		movem.l	(a7)+,d0-d5/a0-a1
		rts

_font		INCBIN	pic_font_5x6_br.bin
_font_
_stuffend

;============================================================================

	INCLUDE	whdload/keyboard.s

;============================================================================

_copper		dc.w	diwstrt,$1a81
		dc.w	diwstop,$1ac1+((SCREENHEIGHT-256)*$100)
		dc.w	bplcon0,$1200
		dc.w	bplpt+0,MEMSCREEN>>16
		dc.w	bplpt+2,MEMSCREEN&$ffff
		dc.w	bpl1mod,0
		dc.w	color+0,0
		dc.w	color+2,$ddd
		dc.l	-2

_top1		dc.b	"resload_Audio Testslave "
	INCBIN	.date
		dc.b	0
_top2		dc.b	"whdload %ld.%ld.%ld",0
_fmt_mode	dc.b	"loop=%s  volume=$%04lx",0
_fmt_status	dc.b	"status main=%2ld  vbi=%2ld  playtime=%2ld:%02ld.%02ld  ",0
_fmt_ports	dc.b	"ports ints  last-vbi=%2ld  max-vbi=%2ld  last-sec=%3ld",0
_fmt_hold	dc.b	"ports interrupt disabled for %3ld frames",0
_fmt_nohold	dc.b	"                                        ",0
_fmt_hist	dc.b	"%-6s d1=%-5ld d2=%ld result=%-2ld %6ld lines %5ld ms",0
_on		dc.b	"on ",0
_off		dc.b	"off",0
_cmd_play	dc.b	"play",0
_cmd_stop	dc.b	"stop",0
_cmd_status	dc.b	"status",0
_cmd_volume	dc.b	"volume",0
_cmd_save	dc.b	"save",0
_savename	dc.b	"audio.tst",0
_help		dc.b	"1-9 play track 1-9            n play track 99",0
		dc.b	"l loop                        space stop",0
		dc.b	"cursor up/down (hold) volume  s status",0
		dc.b	"o savefile (os switch)        h disable ports int for 2s",0
		dc.b	"q quit",0
		dc.b	0
	EVEN

;============================================================================

	CNOP 0,4
_resload	dx.l	1	;address of resident loader
_vars		dx.b	v_SIZEOF

;============================================================================

	END
