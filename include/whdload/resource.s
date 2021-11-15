;*---------------------------------------------------------------------------
;  :Modul.	resource.s
;  :Contents.	whdload.resource for kick emulation under WHDLoad
;  :Author.	Wepl
;  :Version.	$Id: kickfs.s 1.26 2020/05/11 00:43:34 wepl Exp wepl $
;  :History.	13.11.21 created
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.16, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	-
;---------------------------------------------------------------------------*

	INCLUDE	exec/initializers.i

;============================================================================
; this creates the resource, must be called once at startup
; data structure:
;	LIB_SIZE ULONG resload base

_resource_init	movem.l	d0-d1/a0-a2/a6,-(a7)
		lea	(.name,pc),a0
		lea	(.struct_name+2,pc),a1
		move.l	a0,(a1)
		move.l	#LIB_SIZE+4,d0		;data size
		moveq	#0,d1			;segment list
		lea	(.vectors,pc),a0
		lea	(.structure,pc),a1
		sub.l	a2,a2
		move.l	(4),a6
		jsr	(_LVOMakeLibrary,a6)
		move.l	d0,a1
		move.l	(_resload,pc),(LIB_SIZE,a1)
		jsr	(_LVOAddResource,a6)
		movem.l	(a7)+,d0-d1/a0-a2/a6
		rts

.structure	INITBYTE LN_TYPE,NT_RESOURCE
.struct_name	INITLONG LN_NAME,0
		INITBYTE LIB_FLAGS,LIBF_CHANGED|LIBF_SUMUSED
		INITWORD LIB_VERSION,1
		dc.w	0

.vectors	dc.w	-1
		dc.w	-1

.name		dc.b	"whdload.resource",0
	EVEN

