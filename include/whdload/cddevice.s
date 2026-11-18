;*---------------------------------------------------------------------------
;  :Modul.	cddevice.s
;  :Contents.	minimal cdtv.device/cd.device for kick emulation under WHDLoad
;		CD audio (CD-DA) commands are forwarded to resload_Audio, all
;		other commands do nothing and are completed immediately
;		all commands are written to the WHDLoad log (option FileLog)
;		will be constructed directly in memory
;  :Author.	Wepl
;  :History.	10.11.26 created for game Sim City CDTV
;		15.11.26 PLAYTRACK plays multiple tracks (WHDLAUDF_COUNT)
;			 semantics adapted to the autodocs
;			 PLAYTRACK is replied at the end of playing via
;			 WHDLAUDC_CALLBACK
;			 CDTV_SUBQLSN/MSF and CDTV_QUICKSTATUS added
;  :Requires.	ws_Version >= 21 (resload_Audio)
;		CDDEVICE_CDTV defined: creates "cdtv.device" (default kick13.s)
;		CDDEVICE_CD defined: creates "cd.device" (default kick31.s)
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38, vasm
;  :To Do.
;---------------------------------------------------------------------------*
; supported commands, both devices:
;   PLAYTRACK	plays the tracks via resload_Audio with WHDLAUDF_COUNT, the
;		request is replied with io_Error = 0 at the end of playing
;		(WHDLAUDC_CALLBACK), or with io_Error = CDERR_ABORTED if it is
;		aborted via AbortIO, CDTV_STOPPLAY or a following PLAYTRACK
;		if playing could not be started (no audio available, track
;		missing, not enough memory) the request stays pending until it
;		is aborted (like an endless silent track), replying it with an
;		error would cause an endless loop in programs which restart
;		the music after each reply, the failure is written to the log
;		CDTV_PLAYTRACK: io_Offset = start track, io_Length = stop track
;		  (not played, 0 = next track), upper words (index) ignored
;		CD_PLAYTRACK: io_Offset = start track, io_Length = number of
;		  tracks (0 is invalid and plays one track)
;   PAUSE	io_Length = 1 pause (stops playing), 0 resume (restarts the
;		tracks from the beginning), io_Actual = previous pause state
;		cdtv.device: a following PLAYTRACK clears the pause state
;		cd.device: a following PLAYTRACK stays paused until resumed
; cdtv.device only:
;   CDTV_STOPPLAY	stops playing
;   CDTV_MUTE		io_Length = 0 only query, otherwise (mode 1/2) sets the
;			volume io_Offset immediately, io_Actual = previous volume
;   CDTV_FADE		sets the volume io_Offset immediately (no fade)
;   CDTV_SUBQLSN/MSF	fills Status (SQSTAT_PLAYING while a PLAYTRACK is
;			pending, SQSTAT_PAUSED, otherwise SQSTAT_DONE),
;			AddrCtrl, Track and Index of the CDSubQ structure,
;			the positions are always 0
;   CDTV_QUICKSTATUS	io_Actual = QSF_READY|QSF_DONE|QSF_SPIN|QSF_DISK and
;			QSF_AUDIO while a PLAYTRACK is pending
; cd.device only:
;   CD_ATTENUATE	sets the volume io_Offset immediately (no fade), -1
;			only query, io_Actual = current volume
;
; command values from devices/cd.i and devices/cdtv.i, semantics from the
; autodocs cdtv.doc and cd.doc

	IFD slv_Version
	IFLT slv_Version-21
	FAIL	cddevice.s requires slv_Version 21+ (resload_Audio)
	ENDC
	ENDC

	IFND CDDEVICE_CDTV
	IFND CDDEVICE_CD
	FAIL	cddevice.s requires CDDEVICE_CDTV or CDDEVICE_CD
	ENDC
	ENDC

	INCLUDE	exec/io.i
	INCLUDE	exec/initializers.i

	;cd.i and cdtv.i define CDERR_* with different values, include only one
	IFD CDDEVICE_CDTV
	INCLUDE	devices/cdtv.i
	ELSE
	INCLUDE	devices/cd.i
	ENDC

	STRUCTURE CDDevice,LIB_SIZE
		APTR	cdd_playreq	;pending PLAYTRACK request or 0
		ULONG	cdd_track	;start track of pending request
		ULONG	cdd_count	;number of tracks of pending request
		ULONG	cdd_volume	;actual volume 0..$7fff
		ULONG	cdd_paused	;0 = playing, 1 = paused
		ULONG	cdd_active	;-1 = playing started, callback replies
		LABEL	cdd_SIZEOF

;============================================================================
; this creates the device, must be called once at startup

_cddevice_init	movem.l	d0-d2/a0-a2/a6,-(a7)
		lea	(.structure,pc),a1
		lea	(_cdd_name,pc),a0
		move.l	a0,(2,a1)		;LN_NAME
		move.l	#cdd_SIZEOF,d0		;data size
		moveq	#0,d1			;segment list
		lea	(.vectors,pc),a0
		sub.l	a2,a2
		move.l	(4),a6
		jsr	(_LVOMakeLibrary,a6)
		move.l	d0,a1
		lea	(_cdd_base,pc),a0
		move.l	a1,(a0)
		jsr	(_LVOAddDevice,a6)
	;set callback for the end of playing
		moveq	#WHDLAUDC_CALLBACK,d0
		lea	(_cdd_callback,pc),a0
		move.l	a0,d1
		moveq	#0,d2
		bsr	_cdd_audio
		movem.l	(a7)+,d0-d2/a0-a2/a6
		rts

.structure	INITLONG LN_NAME,0		;must be first, set at runtime
		INITBYTE LN_TYPE,NT_DEVICE
		INITBYTE LIB_FLAGS,LIBF_CHANGED|LIBF_SUMUSED
		INITWORD LIB_VERSION,40
		INITLONG cdd_volume,$7fff
		dc.w	0

.vectors	dc.w	-1
		dc.w	_cdd_Open-.vectors
		dc.w	_cdd_Close-.vectors
		dc.w	_cdd_Null-.vectors	;Expunge
		dc.w	_cdd_Null-.vectors	;ExtFunc
		dc.w	_cdd_BeginIO-.vectors
		dc.w	_cdd_AbortIO-.vectors
		dc.w	-1

	IFD CDDEVICE_CDTV
_cdd_name	dc.b	"cdtv.device",0
	ELSE
_cdd_name	dc.b	"cd.device",0
	ENDC
_cdd_fmtopen	dc.b	"%s: OpenDevice unit=%ld flags=$%lx",0
_cdd_fmtcmd	dc.b	"%s: cmd=%ld length=%ld offset=$%lx data=$%lx",0
_cdd_fmtabort	dc.b	"%s: AbortIO pending=%ld",0
_cdd_fmtplayerr	dc.b	"%s: playing track %ld count %ld failed, request stays pending",0
	EVEN

_cdd_base	dc.l	0			;device base for _cdd_callback

;============================================================================
; IN:	D0 = command, D1/D2/D3 = arguments (unused D1/D2 must be 0)
; OUT:	D0 = result
; D1/A0/A1 destroyed

_cdd_audio	move.l	(_resload,pc),a0
		jmp	(resload_Audio,a0)

;============================================================================
; start playing the tracks of the pending request, if WHDLoad cannot start
; playing the request stays pending and the failure is logged
; IN:	A6 = device
; OUT:	-
; D0-D3/A0/A1 destroyed

_cdd_play	move.l	(cdd_track,a6),d1
		move.l	(cdd_count,a6),d3
		moveq	#WHDLAUDC_PLAY,d0
		moveq	#WHDLAUDF_COUNT,d2
		bsr	_cdd_audio
		move.l	d0,(cdd_active,a6)	;-1 = started, callback replies
		bne	.rts
		move.l	(cdd_count,a6),-(a7)
		move.l	(cdd_track,a6),-(a7)
		pea	(_cdd_name,pc)
		lea	(_cdd_fmtplayerr,pc),a0
		move.l	(_resload,pc),a1
		jsr	(resload_Log,a1)
		add.w	#3*4,a7
.rts		rts

;============================================================================
; stop playing, the pending request is not replied
; IN:	A6 = device
; OUT:	-
; D0-D2/A0/A1 destroyed

_cdd_stop	clr.l	(cdd_active,a6)		;first, avoid reply by callback
		moveq	#WHDLAUDC_STOP,d0
		moveq	#0,d1
		moveq	#0,d2
		bra	_cdd_audio

;============================================================================
; called by WHDLoad at the natural end of playing (WHDLAUDC_CALLBACK)
; from the level 2 interrupt in supervisor mode
; replies the pending PLAYTRACK request with io_Error = 0
; IN:	D0 = number of the last played track
; OUT:	-
; D0/D1/A0/A1 destroyed

_cdd_callback	move.l	a6,-(a7)
		move.l	(_cdd_base,pc),a6
		tst.l	(cdd_active,a6)
		beq	.end
		clr.l	(cdd_active,a6)
		move.l	(cdd_playreq,a6),d0
		beq	.end
		clr.l	(cdd_playreq,a6)
		move.l	d0,a1
		move.l	(4),a6
		jsr	(_LVOReplyMsg,a6)
.end		move.l	(a7)+,a6
		rts

;============================================================================
; A1 = ioreq, D0 = unit, D1 = flags, A6 = device

_cdd_Open	addq.w	#1,(LIB_OPENCNT,a6)
		move.l	a6,(IO_DEVICE,a1)
		clr.l	(IO_UNIT,a1)
		clr.b	(IO_ERROR,a1)
		move.b	#NT_REPLYMSG,(LN_TYPE,a1)
	;log
		move.l	d1,-(a7)		;flags
		move.l	d0,-(a7)		;unit
		pea	(_cdd_name,pc)
		lea	(_cdd_fmtopen,pc),a0
		move.l	(_resload,pc),a1
		jsr	(resload_Log,a1)
		add.w	#3*4,a7
		rts

;============================================================================
; A1 = ioreq, A6 = device

_cdd_Close	subq.w	#1,(LIB_OPENCNT,a6)
		moveq	#-1,d0
		move.l	d0,(IO_DEVICE,a1)
		move.l	d0,(IO_UNIT,a1)
_cdd_Null	moveq	#0,d0
		rts

;============================================================================
; A1 = ioreq, A6 = device

_cdd_BeginIO	movem.l	d0-d3/a0-a3/a6,-(a7)
		move.l	a1,a3			;A3 = ioreq
		move.b	#NT_MESSAGE,(LN_TYPE,a3)
		clr.b	(IO_ERROR,a3)
	;log
		move.l	(IO_DATA,a3),-(a7)
		move.l	(IO_OFFSET,a3),-(a7)
		move.l	(IO_LENGTH,a3),-(a7)
		moveq	#0,d0
		move.w	(IO_COMMAND,a3),d0
		move.l	d0,-(a7)
		pea	(_cdd_name,pc)
		lea	(_cdd_fmtcmd,pc),a0
		move.l	(_resload,pc),a1
		jsr	(resload_Log,a1)
		add.w	#5*4,a7
		clr.l	(IO_ACTUAL,a3)
	;dispatch
		move.w	(IO_COMMAND,a3),d0
	IFD CDDEVICE_CDTV
		cmp.w	#CDTV_PLAYTRACK,d0
		beq	.play
		cmp.w	#CDTV_PAUSE,d0
		beq	.pause
		cmp.w	#CDTV_STOPPLAY,d0
		beq	.stop
		cmp.w	#CDTV_MUTE,d0
		beq	.mute
		cmp.w	#CDTV_FADE,d0
		beq	.fade
		cmp.w	#CDTV_SUBQLSN,d0
		beq	.subq
		cmp.w	#CDTV_SUBQMSF,d0
		beq	.subq
		cmp.w	#CDTV_QUICKSTATUS,d0
		beq	.quickstatus
	ELSE
		cmp.w	#CD_PLAYTRACK,d0
		beq	.play
		cmp.w	#CD_PAUSE,d0
		beq	.pause
		cmp.w	#CD_ATTENUATE,d0
		beq	.attenuate
	ENDC
	;reply if not quick
.done		btst	#IOB_QUICK,(IO_FLAGS,a3)
		bne	.end
		move.l	a3,a1
		move.l	(4),a6
		jsr	(_LVOReplyMsg,a6)
.end		movem.l	(a7)+,d0-d3/a0-a3/a6
		rts

.play		moveq	#CDERR_ABORTED,d1
		bsr	_cdd_replyplay		;finish a still pending play
		moveq	#0,d1
		move.w	(IO_OFFSET+2,a3),d1	;start track, upper word is index
		move.l	d1,(cdd_track,a6)
	IFD CDDEVICE_CDTV
		moveq	#0,d0
		move.w	(IO_LENGTH+2,a3),d0	;stop track, 0 = next track
		sub.l	d1,d0			;number of tracks
		bgt	.count
		moveq	#1,d0
.count		clr.l	(cdd_paused,a6)		;pause state is not latched
	ELSE
		move.l	(IO_LENGTH,a3),d0	;number of tracks, 0 is invalid
		bgt	.count
		moveq	#1,d0
.count
	ENDC
		move.l	d0,(cdd_count,a6)
		move.l	a3,(cdd_playreq,a6)
		bclr	#IOB_QUICK,(IO_FLAGS,a3)	;request stays pending
		tst.l	(cdd_paused,a6)		;cd.device: suspended until resumed
		bne	.end
		bsr	_cdd_play
		bra	.end

.pause		move.l	(cdd_paused,a6),(IO_ACTUAL,a3)	;previous pause state
		tst.l	(IO_LENGTH,a3)
		beq	.resume
		tst.l	(cdd_paused,a6)
		bne	.done
		moveq	#1,d0
		move.l	d0,(cdd_paused,a6)
		tst.l	(cdd_playreq,a6)
		beq	.done
		bsr	_cdd_stop
		bra	.done

.resume		tst.l	(cdd_paused,a6)
		beq	.done
		clr.l	(cdd_paused,a6)
		tst.l	(cdd_playreq,a6)
		beq	.done
		bsr	_cdd_play
		bra	.done

	IFD CDDEVICE_CDTV

.stop		moveq	#CDERR_ABORTED,d1
		bsr	_cdd_replyplay
		clr.l	(cdd_paused,a6)
		bsr	_cdd_stop
		bra	.done

.mute		move.l	(cdd_volume,a6),(IO_ACTUAL,a3)	;previous volume
		tst.l	(IO_LENGTH,a3)
		beq	.done			;mode 0 = query only
.fade		bsr	.setvol
		bra	.done

	;fill CDSubQ structure
.subq		move.l	(IO_DATA,a3),d0
		beq	.done
		move.l	d0,a2			;A2 = CDSubQ
		moveq	#SQSTAT_DONE,d0
		tst.l	(cdd_playreq,a6)
		beq	.subqstat
		moveq	#SQSTAT_PAUSED,d0
		tst.l	(cdd_paused,a6)
		bne	.subqstat
		moveq	#SQSTAT_PLAYING,d0
.subqstat	move.b	d0,(a2)+		;Status
		move.b	#ADRCTL_POSITION,(a2)+	;AddrCtrl
		moveq	#WHDLAUDC_STATUS,d0
		moveq	#0,d1
		moveq	#0,d2
		bsr	_cdd_audio		;D0 = playing track or 0
		tst.l	d0
		bne	.subqtrack
		move.l	(cdd_track,a6),d0	;pending but silent
.subqtrack	move.b	d0,(a2)+		;Track
		move.b	#1,(a2)+		;Index
		clr.l	(a2)+			;DiskPosition
		clr.l	(a2)+			;TrackPosition
		clr.b	(a2)			;ValidUPC
		bra	.done

.quickstatus	moveq	#QSF_READY|QSF_DONE|QSF_SPIN|QSF_DISK,d0
		tst.l	(cdd_playreq,a6)
		beq	.qsset
		tst.l	(cdd_paused,a6)
		bne	.qsset
		or.b	#QSF_AUDIO,d0
.qsset		move.l	d0,(IO_ACTUAL,a3)
		bra	.done

	ELSE

.attenuate	tst.l	(IO_OFFSET,a3)
		bmi	.actual			;-1 = query only
		bsr	.setvol
.actual		move.l	(cdd_volume,a6),(IO_ACTUAL,a3)	;current volume
		bra	.done

	ENDC

.setvol		move.l	(IO_OFFSET,a3),d1
		and.l	#$7fff,d1
		move.l	d1,(cdd_volume,a6)
		moveq	#WHDLAUDC_VOLUME,d0
		moveq	#0,d2
		bra	_cdd_audio

;============================================================================
; A1 = ioreq, A6 = device
; only a pending PLAYTRACK can be aborted

_cdd_AbortIO	movem.l	d1-d2/a0-a3,-(a7)
		move.l	a1,a3			;A3 = ioreq
		moveq	#0,d0
		cmp.l	(cdd_playreq,a6),a3
		seq	d0
		neg.b	d0			;D0 = 1 if pending play
		move.l	d0,-(a7)
		pea	(_cdd_name,pc)
		lea	(_cdd_fmtabort,pc),a0
		move.l	(_resload,pc),a1
		jsr	(resload_Log,a1)
		addq.l	#2*4,a7
		cmp.l	(cdd_playreq,a6),a3
		bne	.end
		clr.l	(cdd_paused,a6)
		bsr	_cdd_stop
		moveq	#CDERR_ABORTED,d1
		bsr	_cdd_replyplay
.end		moveq	#0,d0
		movem.l	(a7)+,d1-d2/a0-a3
		rts

;============================================================================
; reply a pending PLAYTRACK request
; IN:	D1 = io_Error
;	A6 = device
; OUT:	-
; D0/D1/A0/A1 destroyed

_cdd_replyplay	clr.l	(cdd_active,a6)		;first, avoid reply by callback
		move.l	(cdd_playreq,a6),d0
		beq	.rts
		clr.l	(cdd_playreq,a6)
		move.l	d0,a1
		move.b	d1,(IO_ERROR,a1)
		move.l	a6,-(a7)
		move.l	(4),a6
		jsr	(_LVOReplyMsg,a6)
		move.l	(a7)+,a6
.rts		rts

