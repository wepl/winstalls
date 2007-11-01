;*---------------------------------------------------------------------------
;  :Program.	GenericKickHD.asm
;  :Contents.	Slave for "GenericKick"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: wildwestworld.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	07.08.00 started
;		03.08.01 some steps forward ;)
;		30.01.02 final beta
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $400000
KICKSIZE	= $80000			;40.068
	IFD	BARFLY
	OUTPUT	"GenericKick31.slave"
	ENDC

	include	"GenericKickHD.asm"
