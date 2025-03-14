*---------------------------------------------------------------------------
;  :Program.	North&South.asm
;  :Contents.	Slave for "North & South" from Infogrames
;  :Author.	Mr.Larmer of Wanted Team, Wepl
;  :Original	
;  :Version.	$Id: North&South.asm 1.2 2001/02/17 19:59:05 jah Exp $
;  :History.	17.02.01 Wepl adjusted
;		02.06.03 Wepl minor changes
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Asm-One 1.44
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:n/north&south/North&South.Slave"
	BOPT	O+	;enable optimizing
	BOPT	OG+	;enable optimizing
	BOPT	ODd-	;disable mul optimizing
	BOPT	ODe-	;disable mul optimizing
	BOPT	w4-	;disable 64k warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= 0000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
CACHE
;DEBUG
DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT	= 8
;HDINIT
;HRTMON
;IOCACHE	= 1024
;MEMFREE	= $100
;NEEDFPU
;POINTERTICKS	= 1
SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

_name		dc.b	"North & South",0
_copy		dc.b	"1989 Infogrames",0
_info		dc.b	"adapted by Wepl & Mr.Larmer",10
		dc.b	"Version 1.5"
		dc.b	0
	EVEN

;============================================================================

	;a1 = ioreq ($2c+a5)
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock

	;check version
		move.l	#$2A4,d0
		lea	12(a4),a0
		move.l	(_resload,pc),a2
		jsr	(resload_CRC16,a2)

		cmp.w	#$8E19,D0
		beq	.verok
.not_support
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.verok
		pea	.patch(pc)

	;call bootblock
		lea	($2c,a5),a1
		jmp	(12,a4)
.patch
		addq.l	#8,A0

		cmp.l	#$61A64A40,$7FFE(A0)
		bne.b	.another

		move.w	#$7001,$7FFE(A0)		; skip protection
.go
		subq.l	#8,A0

		jmp	(a0)
.another
		cmp.l	#$61A64A40,$7F42(A0)
		bne.b	.not_support

		move.w	#$7001,$7F42(A0)		; skip protection

		bra.b	.go

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END
