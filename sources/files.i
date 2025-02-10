 IFND FILES_I
FILES_I=1
;*---------------------------------------------------------------------------
;  :Author.	Bert Jahn
;  :Contens.	macros for input/output via dos.library
;  :History.	13.01.96 separated from WRip.asm
;		18.01.96 IFD Label replaced by IFD Symbol
;			 because Barfly optimize problems
;		20.01.96 error string in _LoadFile changed
;			 _LoadFile return register swapped
;		03.02.96 _AppendToFile added
;		18.05.96 returncode for _SaveFile & _SaveFileMsg
;		12.06.96 _SaveFileMsg uses now the name from _GetFileName
;			 (otherwise difference between output and real file
;			  if multiple assignments are used ie "C:LIST")
;		25.01.98 _CheckFileExist added
;		17.02.05 _SaveFileMsgPreserve added
;		26.05.05 return code of dos.Seek properly checked
;			 _LoadFile(Msg) now supports files of length=0
;		01.04.10 return code on _AppendOnFile added
;  :Requires.	-
;  :Copyright.	All rights reserved.
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.130
;---------------------------------------------------------------------------*
*##
*##	files.i
*##
*##	_GetFileName	filename(a0) -> fullname
*##	_LoadFile	filename(a0) -> buffer(d0) buffersize(d1)
*##	_LoadFileMsg	filename(a0) -> buffer(d0) buffersize(d1)
*##	_SaveFile	buflen(d0) buffer(a0) filename(a1) -> success
*##	_SaveFileMsg	buflen(d0) buffer(a0) filename(a1) -> success
*##	_SaveFileMsgPreserve	buflen(d0) buffer(a0) filename(a1) -> success
*##	_AppendOnFile	buflen(d0) buffer(a0) filename(a1) -> success
*##	_CheckFileExist	filename(a0) -> bool

		IFND	EXEC_MEMORY_I
			INCLUDE	exec/memory.i
		ENDC
		IFND	ERROR_I
			INCLUDE	error.i
		ENDC

;----------------------------------------
; get full path+name from a file/dir
; Übergabe :	A0 = CPTR name of file
; Rückgabe :	D0 = CPTR full name / NIL
;		     must freed via exec._FreeVec

GetFileName	MACRO
	IFND	GETFILENAME
GETFILENAME=1
_GetFileName	movem.l	d2-d3/d6-d7/a6,-(a7)
		moveq	#0,d6
		
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOLock,a6)
		move.l	d0,d7			;D7 = lock
		beq	.nolock
		
		move.l	#256,d0
		moveq	#MEMF_ANY,d1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOAllocVec,a6)
		move.l	d0,d6			;D6 = buffer
		beq	.nobuf
		
		move.l	d7,d1
		move.l	d6,d2
		move.l	#256,d3
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVONameFromLock,a6)
		tst.l	d0
		bne	.ok
		move.l	d6,a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
		moveq	#0,d6
.ok
.nobuf
		move.l	d7,d1
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOUnLock,a6)
.nolock
		move.l	d6,d0
		movem.l	(a7)+,d2-d3/d6-d7/a6
		rts
	ENDC
	ENDM

;----------------------------------------
; Operation File
; Übergabe :	A0 = CPTR name of file
; Rückgabe :	D0 = APTR  loaded file (must freed via _FreeVec) OR NIL=ERROR
;		D1 = ULONG size of loaded file 

LoadFile	MACRO
	IFND	LOADFILE
LOADFILE=1
	IFND	PRINTERRORDOS
		PrintErrorDOS
	ENDC
_LoadFile	movem.l	d2-d7/a6,-(a7)
		moveq	#0,d4				;D4 = BOOL returncode
		move.l	a0,d1				;name
		move.l	#MODE_OLDFILE,d2		;mode
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOOpen,a6)
		move.l	d0,d7				;D7 = fh
		bne	.openok
		lea	(.readfile),a0
		bsr	_PrintErrorDOS
		bra	.erropen
.openok
		move.l	d7,d1				;fh
		moveq	#0,d2				;offset
		move.l	#OFFSET_END,d3			;mode
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOSeek,a6)
		jsr	(_LVOIoErr,a6)			;v36/37 doesn't set rc correctly
		tst.l	d0
		bne	.seekerr
		move.l	d7,d1				;fh
		moveq	#0,d2				;offset
		move.l	#OFFSET_BEGINNING,d3		;mode
		jsr	(_LVOSeek,a6)
		move.l	d0,d5				;D5 = ULONG bufsize
		jsr	(_LVOIoErr,a6)			;v36/37 doesn't set rc correctly
		tst.l	d0
		beq	.sizeok
.seekerr	lea	(.readfile),a0
		bsr	_PrintErrorDOS
		bra	.errexamine
.sizeok
		move.l	d5,d0
		bne	.1
		moveq	#1,d0				;dummy allocation because 0 byte cannot allocated
.1		move.l	#MEMF_ANY,d1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOAllocVec,a6)
		move.l	d0,d6				;D6 = APTR buffer
		bne	.memok
		moveq	#0,d0
		lea	(.notmem),a0
		lea	(.readfile),a1
		bsr	_PrintError
		bra	.nomem
.memok
		move.l	d7,d1				;fh
		move.l	d6,d2				;buffer
		move.l	d5,d3				;length
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVORead,a6)
		cmp.l	d5,d0
		beq	.readok
		lea	(.readfile),a0
		bsr	_PrintErrorDOS
		move.l	d6,a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
		bra	.readerr

.readok		move.l	d6,d4			;returncode = size
.readerr
.nomem
.errexamine		
		move.l	d7,d1			;fh
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOClose,a6)
.erropen
		move.l	d4,d0			;returncode = bufptr
		move.l	d5,d1			;size
		movem.l	(a7)+,d2-d7/a6
		rts

.readfile	dc.b	"read file",0
.notmem		dc.b	"not enough memory",0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; gives message out and load file
; Übergabe :	A0 = CPTR name of file
; Rückgabe :	D0 = APTR  loaded file (must freed via _FreeVec) OR NIL=ERROR
;		D1 = ULONG size of loaded file 

LoadFileMsg	MACRO
	IFND	LOADFILEMSG
LOADFILEMSG=1
	IFND	GETFILENAME
		GetFileName
	ENDC
	IFND	LOADFILE
		LoadFile
	ENDC
_LoadFileMsg	movem.l	d2-d3/a6,-(a7)
		move.l	a0,d2

		bsr	_GetFileName
		move.l	d0,d3
		bne	.fine
		move.l	d2,d0
.fine
		lea	(.loadfile),a0
		move.l	d0,-(a7)
		move.l	a7,a1
		bsr	_PrintArgs
		addq.l	#4,a7
		
		tst.l	d3
		beq	.nofull
		move.l	d3,a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
.nofull
		move.l	d2,a0
		bsr	_LoadFile
		
		movem.l	(a7)+,d2-d3/a6
		rts

.loadfile	dc.b	"loading file ",155,"1m%s",155,"22m",10,0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; Übergabe :	D0 = ULONG size of buffer
;		A0 = APTR  buffer
;		A1 = CPTR  name of file
; Rückgabe :	D0 = BOOL  success

SaveFile	MACRO
	IFND	SAVEFILE
SAVEFILE=1
	IFND	PRINTERRORDOS
		PrintErrorDOS
	ENDC
_SaveFile	movem.l	d2-d7/a6,-(a7)
		move.l	a0,d7			;D7 = buffer
		move.l	d0,d6			;D6 = size
		moveq	#0,d4			;D4 = return

		move.l	a1,d1	
		move.l	#MODE_NEWFILE,d2
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOOpen,a6)
		move.l	d0,d5			;D5 = fh
		bne	.openok
		lea	(.writefile),a0
		bsr	_PrintErrorDOS
		bra	.erropen
.openok
		move.l	d5,d1
		move.l	d7,d2
		move.l	d6,d3
		jsr	(_LVOWrite,a6)
		moveq	#-1,d4
		cmp.l	d6,d0
		beq	.writeok
		lea	(.writefile),a0
		bsr	_PrintErrorDOS
		moveq	#0,d4
.writeok
		move.l	d5,d1
		jsr	(_LVOClose,a6)
		
.erropen	move.l	d4,d0
		movem.l	(a7)+,d2-d7/a6
		rts
.writefile	dc.b	"write file",0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; gives message out and save file
; Übergabe :	D0 = ULONG size of buffer
;		A0 = APTR  buffer
;		A1 = CPTR  name of file
; Rückgabe :	D0 = BOOL  success

SaveFileMsg	MACRO
	IFND	SAVEFILEMSG
SAVEFILEMSG=1
	IFND	GETFILENAME
		GetFileName
	ENDC
	IFND	SAVEFILE
		SaveFile
	ENDC
_SaveFileMsg	movem.l	d2-d5/a6,-(a7)
		move.l	d0,d4			;D4 = bufsize	(d0)
		move.l	a0,d3			;D3 = buffer	(a0)
		move.l	a1,d2			;D2 = name	(a1)
		
		move.l	d2,a0
		bsr	_GetFileName
		move.l	d0,d5
		beq	.sorry
		move.l	d0,d2
.sorry
		lea	(.savefile),a0
		move.l	d2,-(a7)
		move.l	a7,a1
		bsr	_PrintArgs
		addq.l	#4,a7
		
		move.l	d4,d0
		move.l	d3,a0
		move.l	d2,a1
		bsr	_SaveFile
		move.l	d0,d2			;returncode in D2 !!

		tst.l	d5
		beq	.nofull
		move.l	d5,a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOFreeVec,a6)
.nofull
		move.l	d2,d0
		movem.l	(a7)+,d2-d5/a6
		rts

.savefile	dc.b	"save file ",155,"1m%s",155,"22m",10,0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; output message, save file, preseve datestamp & filecomment
; IN:	D0 = ULONG size of buffer
;	A0 = APTR  buffer
;	A1 = CPTR  name of file
; OUT:	D0 = BOOL  success

SaveFileMsgPreserve	MACRO
	IFND	SAVEFILEMSGPRESERVE
SAVEFILEMSGPRESERVE=1
	IFND	SAVEFILE
		SaveFile
	ENDC
_SaveFileMsgPreserve
		movem.l	d2-d7/a2-a3/a6,-(a7)
		move.l	d0,d4			;D4 = bufsize	(d0)
		move.l	a0,d5			;D5 = buffer	(a0)
		move.l	a1,d6			;D6 = name	(a1)
		sub.l	#fib_SIZEOF+4,a7
		move.l	a7,d0
		addq.l	#2,d0
		bclr	#1,d0
		move.l	d0,a2			;A2 = fib
		sub.l	#128,a7
		move.l	a7,a3			;A3 = name

		move.l	d6,d1
		move.l	#ACCESS_READ,d2
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOLock,a6)
		move.l	d0,d7			;D7 = lock
		beq	.nolock
		
		move.l	d7,d1
		move.l	a3,d2
		move.l	#128,d3
		jsr	(_LVONameFromLock,a6)
		tst.l	d0
		beq	.noname
		move.l	a3,d6
.noname
.nolock
		lea	(.savefile),a0
		move.l	d6,-(a7)
		move.l	a7,a1
		bsr	_PrintArgs
		addq.l	#4,a7

		tst.l	d7
		bne	.preserve

	;create new file
		move.l	d4,d0
		move.l	d5,a0
		move.l	d6,a1
		bsr	_SaveFile
		bra	.end

	;preserve existing file
.preserve	move.l	d7,d1			;lock
		move.l	a2,d2			;fib
		jsr	(_LVOExamine,a6)
		tst.l	d0
		bne	.examineok
		lea	(.examine),a0
.errorlock	bsr	_PrintErrorDOS
		move.l	d7,d1
		jsr	(_LVOUnLock,a6)
		moveq	#0,d0
		bra	.end
.examineok
		move.l	d7,d1			;lock
		jsr	(_LVOOpenFromLock,a6)
		tst.l	d0
		bne	.openok
		lea	(.open),a0
		bra	.errorlock
.openok
		move.l	d0,d7			;D7 = fh

		move.l	d7,d1			;fh
		move.l	d5,d2			;buffer
		move.l	d4,d3			;bufsize
		jsr	(_LVOWrite,a6)
		cmp.l	d4,d0
		beq	.writeok
		lea	(.write),a0
.errorfh	bsr	_PrintErrorDOS
		move.l	d7,d1
		jsr	(_LVOClose,a6)
		moveq	#0,d0
		bra	.end
.writeok
		move.l	d7,d1			;fh
		move.l	#0,d2			;offset
		move.l	#OFFSET_CURRENT,d3	;mode
		jsr	(_LVOSetFileSize,a6)
		cmp.l	d4,d0
		beq	.setfilesizeok
		lea	(.setfilesize),a0
		bra	.errorfh
.setfilesizeok
		move.l	d7,d1
		jsr	(_LVOClose,a6)
		
		move.l	d6,d1			;name
		lea	(fib_DateStamp,a2),a0
		move.l	a0,d2			;date
		jsr	(_LVOSetFileDate,a6)
		tst.l	d0
		bne	.setfiledateok
		lea	(.setfiledate),a0
		bsr	_PrintErrorDOS
.setfiledateok
		moveq	#-1,d0

.end		add.l	#128+fib_SIZEOF+4,a7
		movem.l	(a7)+,_MOVEMREGS
		rts

.savefile	dc.b	"save file ",155,"1m%s",155,"22m",10,0
.examine	dc.b	"examine",0
.open		dc.b	"open",0
.write		dc.b	"write",0
.setfilesize	dc.b	"set file size",0
.setfiledate	dc.b	"set file date",0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; IN :	D0 = ULONG size of buffer
;	A0 = APTR  buffer
;	A1 = CPTR  name of file
; OUT:	D0 = BOOL  success

AppendOnFile	MACRO
	IFND	APPENDONFILE
APPENDONFILE=1
	IFND	PRINTERRORDOS
		PrintErrorDOS
	ENDC
_AppendOnFile	movem.l	d2-d7/a6,-(a7)
		move.l	a0,d7			;D7 = buffer
		move.l	d0,d6			;D6 = size
		moveq	#0,d4			;D4 = success

		move.l	a1,d1	
		move.l	#MODE_READWRITE,d2
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOOpen,a6)
		move.l	d0,d5			;D5 = fh
		bne	.openok
		lea	(.writefile),a0
		bsr	_PrintErrorDOS
		bra	.erropen
.openok
		move.l	d5,d1			;fh
		moveq	#0,d2			;offset
		move.l	#OFFSET_END,d3		;mode
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOSeek,a6)
		jsr	(_LVOIoErr,a6)		;v36/37 doesn't set rc correctly
		tst.l	d0
		bne	.seekfail

		move.l	d5,d1
		move.l	d7,d2
		move.l	d6,d3
		jsr	(_LVOWrite,a6)
		cmp.l	d6,d0
		bne	.writefail
		moveq	#-1,d4
		bra	.close

.seekfail
.writefail	lea	(.writefile),a0
		bsr	_PrintErrorDOS
.close
		move.l	d5,d1
		jsr	(_LVOClose,a6)
.erropen
		move.l	d4,d0
		movem.l	(a7)+,d2-d7/a6
		rts

.writefile	dc.b	"write file",0
	EVEN
	ENDC
	ENDM

;----------------------------------------
; Übergabe :	A0 = CPTR filename
; Rückgabe :	D0 = BOOL exist

CheckFileExist	MACRO
	IFND	CHECKFILEEXIST
CHECKFILEEXIST=1
_CheckFileExist	movem.l	d2/a6,-(a7)
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		move.l	(gl_dosbase,GL),a6
		jsr	(_LVOLock,a6)
		move.l	d0,d1
		beq	.end
		jsr	(_LVOUnLock,a6)
		moveq	#-1,d0
.end		movem.l	(a7)+,_MOVEMREGS
		rts
	ENDC
	ENDM

;----------------------------------------

 ENDC

