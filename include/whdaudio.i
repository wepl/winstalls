;*---------------------------------------------------------------------------
;  :Module.	whdaudio.i
;  :Contens.	include file for WHDLoad audio plugin interface
;  :Author.	Bert Jahn
;  :History.	2026-10-15 created
;  :Copyright.	(c) 2026 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38, Devpac 3.18, VASM 1.8h
;---------------------------------------------------------------------------*

 IFND WHDAUDIO_I
WHDAUDIO_I SET 1

	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC

;=============================================================================
; misc
;=============================================================================

WAUD_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"WHDLDAUD"
	ENDM

WAUD_VERSION	= 1		; current version of the interface

;=============================================================================
; file header	Version 1+
; the file is a standard AmigaDOS hunk file loaded via dos.LoadSeg and
; searched by WHDLoad as PROGDIR:WHDLoad.Audio or in the directory where
; WHDLoad is located
; it must consist of exactly one hunk which contains code and all variables,
; uninitialized variables should be placed at the end of the hunk (e.g. dx)
; the plugin must not allocate any memory
; the whole hunk will be mapped readable and writable by the MMU while the
; installed program is running
; all functions get their arguments in registers, they may modify the
; registers d0/d1/a0/a1, all other registers must be preserved
; the plugin addresses its own data itself (e.g. pc-relative)
;=============================================================================

    STRUCTURE	WHDLoadAudio,0
	STRUCT	waud_security,4		; moveq #-1,d0 rts
	STRUCT	waud_id,8		; "WHDLDAUD"
	UWORD	waud_version		; version of this structure (WAUD_VERSION)
	UWORD	waud_flags		; reserved, must be 0
	CPTR	waud_name		; id-string of this plugin
					; displayed in informational messages
					; (e.g. "WHDLoad.Audio 1.0 (15.10.2026)")

	; set by WHDLoad before calling waud_init
	; trace function, writes a message to the WHDLoad trace file
	; can only be used during waud_init and waud_exit (operating system active)
	; IN:	a0 = CPTR  format string (see resload_VSNPrintF)
	;	a1 = APTR  argument array
	; OUT:	-
	APTR	waud_trace

	; initialize the plugin, detect the hardware
	; called with operating system active
	; all supported hardware will be checked until one is found
	; IN:	-
	; OUT:	d0 = LONG  WAUDINIT_*
	;	a0 = CPTR  error message if d0 = WAUDINIT_ERROR
	APTR	waud_init

	; all following fields may be set by waud_init, they are only used
	; after waud_init has returned WAUDINIT_OK

	; pointer to a list of supported file name extensions, each one is
	; terminated by a zero byte, the list is terminated by an empty string
	; e.g.: dc.b "mp3",0,"ogg",0,0
	; WHDLoad loads the audio files as track01.<ext> ... track99.<ext>
	APTR	waud_exts

	; pointer to a list of memory areas (e.g. hardware registers) which
	; must be accessible while the installed program is running
	; each entry consist of three longs: start, end (inclusive), WAUDMEM_*
	; the list is terminated by a zero long (like the ACA freezer interface)
	APTR	waud_mem

	; function table, a pointer to each function

	; free all resources obtained by waud_init
	; called with operating system active, only if waud_init has returned
	; WAUDINIT_OK
	; playing has already been stopped via waud_stop before
	; IN:	-
	; OUT:	-
	APTR	waud_exit

	; start playing an audio stream
	; called with operating system inactive and interrupts disabled
	; IN:	d0 = ULONG  length of audio data
	;	d1 = ULONG  flags, WHDLAUDF_* (whdload.i)
	;	a0 = APTR   audio data (readable until stopped or finished)
	;		    long aligned, readable also up to the next long boundary,
	;		    these pad bytes are 0
	; OUT:	-
	APTR	waud_play

	; stop playing
	; called with operating system inactive and interrupts disabled
	; IN:	-
	; OUT:	-
	APTR	waud_stop

	; suspend interrupt generation of the hardware because the operating
	; system becomes active (e.g. for loading files)
	; called with operating system inactive and interrupts disabled
	; IN:	-
	; OUT:	-
	APTR	waud_suspend

	; resume interrupt generation of the hardware
	; called with operating system inactive and interrupts disabled
	; IN:	-
	; OUT:	-
	APTR	waud_resume

	; set volume
	; called with operating system inactive and interrupts disabled
	; IN:	d0 = ULONG  volume 0 (silent) .. $7fff (maximum)
	; OUT:	-
	APTR	waud_volume

	; interrupt routine
	; called on each level 2 interrupt (INTB_PORTS) while the installed
	; program is running and before the interrupt handler of the installed
	; program is called
	; must check itself whether the interrupt was caused by its hardware
	; and acknowledge the interrupt on the hardware only
	; it must not modify any custom or cia register (e.g. intreq, ciaicr)
	; IN:	-
	; OUT:	d0 = ULONG  WAUDIRQF_*
	APTR	waud_irq

	LABEL	waud_SIZEOF

;=============================================================================
; return values of waud_init
;=============================================================================

WAUDINIT_OK	= 0	; supported hardware found and initialized
WAUDINIT_NOHW	= 1	; no supported hardware found (no error)
WAUDINIT_ERROR	= -1	; error, a0 contains error message

;=============================================================================
; flags returned by waud_irq
;=============================================================================

 BITDEF WAUDIRQ,FINISHED,0	; the audio stream has been finished

;=============================================================================
; memory attributes for waud_mem (same as WHDLoad MMU descriptor types)
;=============================================================================

WAUDMEM_NC	= 1	; non cachable
WAUDMEM_NCS	= 2	; non cachable serialized (use this for hardware registers)
WAUDMEM_WT	= 3	; cachable write through
WAUDMEM_CB	= 4	; cachable copy back
 BITDEF WAUDMEM,WP,3	; write protected

;=============================================================================

 ENDC

