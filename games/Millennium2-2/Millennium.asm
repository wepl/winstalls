;*---------------------------------------------------------------------------
;  :Program.	Millennium2-2.asm
;  :Contents.	Slave for "Millennium 2·2" from Electronic Dreams
;  :Author.	Mr.Larmer & Wepl
;  :Original	v1 Harry
;  :Version.	$Id: Millennium2-2.asm 1.0 2001/02/22 12:17:18 jah Exp $
;  :History.	22.02.01 ml adapted for kickemu
;		24.02.01 savegame support added, cleanup
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:m/millennium2·2/Millennium2-2.Slave"
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	SUPER
	ENDC

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%0001

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
NOFPU

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
;HRTMON

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

; amount of memory available for the system
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
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

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Millennium 2·2",0
_copy		dc.b	"1989 Ian Bird / Electric Dreams",0
_info		dc.b	"adapted by Mr.Larmer & Wepl",10
		dc.b	"Version 1.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_savename	dc.b	"Disk.2",0
	EVEN

;============================================================================
_start	;	A0 = resident loader
;============================================================================

		move.l	a0,a2
	;check for savedisk
		lea	(_savename,pc),a0
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	.saveok
	;create savedisk
		lea	(_savename,pc),a0	;name
		lea	$2000,a1		;address
		move.l	#$16c65710,($3fc,a1)	;diskid
		move.l	#$1600,d0		;length
		move.l	#0,d1			;offset
		jsr	(resload_SaveFileOffset,a2)
	;savedisk ok
.saveok		move.l	a2,a0

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
		cmp.w	#$C367,D0
		beq	.verok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.verok
	;call bootblock
		lea	($2c,a5),a1

		move.w	#$6004,$24(a4)		; skip set stack
		move.w	#$6004,$326(a4)		; skip set stack
		move.w	#$6004,$356(a4)		; skip set stack

		pea	_intro(pc)
		move.l	(a7)+,$32E(a4)

		pea	_main(pc)
		move.l	(a7)+,$35E(a4)

		jmp	(12,a4)

_intro		move.w	#$4EB9,$4196A
		pea	.RemInt(pc)
		move.l	(a7)+,$4196C

		move.w	#$4E71,$41F26		; skip set stack
		move.w	#$601C,$41F40
		move.w	#$6002,$420AA

		jmp	$41000

.RemInt		move.l	#$4191A,a1
		moveq	#5,d0
		rts

_main		move.w	#$601A,$766E4		; skip set stack

		move.l	_expmem(pc),-(a7)
		add.l	#$D300,(a7)
		move.l	(a7),$68E7C		; random access area
		move.l	(a7)+,$790F2

	;	move.w	#$7001,$68f68		;df1:
	
		patchs	$69174,.change
		move.w	#3,$7056e		;disable format savedisk
	;	move.b	#0,$6e1fd

		jmp	$68000

.change		movem.l	d0-d1,-(a7)
		moveq	#0,d0			;unit
		moveq	#2,d1			;disk
		bsr	_trd_changedisk
		movem.l	(a7)+,d0-d1
		moveq	#0,d7
		rts

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

