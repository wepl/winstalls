;*---------------------------------------------------------------------------
;  :Program.	Millenium.asm
;  :Contents.	Slave for "Millenium" from 
;  :Author.	Mr.Larmer of Wanted Team, Wepl
;  :Version.	$Id: FullMetalPlanete.asm 1.1 1999/12/22 12:18:07 jah Exp jah $
;  :History.	31.08.98
;		22.12.99 adapted for kickstart interface
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:m/millennium2·2/Millennium.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ELSE
	OUTPUT	dh1:demos/millennium/Millennium.slave
	OPT	O+ OG+			;enable optimizing
	ENDC

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
NOFPU

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
HRTMON

; amount of memory available for the system
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= 0

;============================================================================

KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Millennium 2·2",0
_copy		dc.b	"1989 Ian Bird",0
_info		dc.b	"adapted by MrLarmer & Wepl",10
		dc.b	"Version 1.2 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	;initialize kickstart and environment
		bra	_boot

	;a1 = ioreq ($2c+a5)
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock
	;check version
		move.l	#$400,d0
		move.l	a4,a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)
		cmp.w	#$c367,D0
		beq	.verok
		pea	TDREASON_WRONGVER.w
		jmp	(resload_Abort,a2)
.verok
	;set caches
		move.l	#0,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
	;setup hook
;		move.w	#$4E71,$338(A4)		; insert RTS (skip intro)
		move.w	#$4E75,$368(A4)		; insert RTS (go to patch)
		pea	_1
	;call bootblock
		lea	($2c,a5),a1
		jmp	(12,a4)

_1
;		move.l	#$A8D398FB,D6		; skip protection

;		move.w	#$6002,$686B2		; skip DoIO input.device AddHandler

;		move.w	#$6002,$6FC14		; skip ReadPixel
;		move.w	#$6002,$6FC30		; skip WritePixel
;		move.w	#$6002,$6E9F8		; skip BltTemplate

;		move.l	$4.w,$68E7C		; skip ptr to $FCD300
;		move.l	$4.w,$790F2		; skip ptr to $FCD300

;.m	move.w	$DFF006,$DFF180
;	bra.b	.m

		jmp	(a3)

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

