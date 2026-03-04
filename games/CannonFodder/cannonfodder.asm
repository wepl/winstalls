;*---------------------------------------------------------------------------
;  :Program.	CF.Asm
;  :Contents.	Slave for "Cannon Fodder" from Sensible Software
;  :Author.	Galahad of Fairlight
;  :History.	25.01.01
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	sys:include/
	INCLUDE	whdload.i

	OUTPUT	sys:cannonfodder/cf.slave
	

;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	15		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$110000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	_data-base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = Del
		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

_name	dc.b	'--<> Cannon Fodder <>--',0
_copy	dc.b	'1993 Sensible Software / Virgin',0
_info	dc.b	'-------------------------------',10
	dc.b	'Installed & Fixed by',10
	dc.b	'Galahad of FAiRLiGHT',10
	dc.b	'v1.2 (05.06.03)',10
	dc.b	'-------------------------------',10
	dc.b	0
	dc.b	-1
	CNOP 0,2
_data:
	dc.b	'DATA',0
bootname:
	dc.b	'fload',0
name:
	dc.b	'cfdisk',0
CFSDISK:
	dc.b	'CFSDISK',0
saveroot:
	dc.b	'GALAHAD.ROOT',0
save_name:
	dc.b	'SAVE.'
param:	dcb.b	9
	even

	even


;======================================================================
Start	;	A0 = resident loader
;======================================================================

offset1:	=	$8a000
offset2:	=	$a4000

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		lea	CFSDISK(pc),a0
		bsr.s	_checkfile
		tst.l	d0
		bne.s	fileok
		move.l	rank+2(pc),a1
		clr.b	(a1)
		moveq	#1,d0
		bsr	_SaveFile		;Creates CFSDISK file
						;if it is not present!
		
fileok:		
		lea	saveroot(pc),a0
		bsr.s	_checkfile
		tst.l	d0
		bne.s	fileok2
		move.l	rank+2(pc),a1
		move.l	a1,a2
		move.l	#(6144/4)-1,d0		;Clear by Longword
		moveq	#0,d1
make_save:
		move.l	d1,(a1)+
		dbra	d0,make_save					
		move.l	a2,a1
		lea	name(pc),a0
copy_name:
		move.b	(a0)+,(a1)+
		bne.s	copy_name
		lea	32(a2),a2		;Offset
		lea	CFSDISK(pc),a0
copy_rooter:
		move.b	(a0)+,(a2)+
		bne.s	copy_rooter
		lea	saveroot(pc),a0
		move.l	rank+2(pc),a1
		moveq	#0,d0
		move.w	#6144,d0		;Size of root file
		bsr.s	_SaveFile

fileok2:
		lea	bootname(pc),a0
rank:		lea	$70000,a1
		bsr	_LoadFile
		move.l	#$4e714e71,d0		;NOP x 2
		move.w	#$4ef9,d1		;JMP
		move.l	d0,$20(a1)		;Remove Divide by 0
		move.l	#$6100cfd4,$3c82(a1)	;change bsr to loader
		lea	gamepatch(pc),a0
		move.w	d1,$3c82+4(a1)
		move.l	a0,$3c82+4+2(a1)	;Boot Loader patched!
		move.l	#$6000008a,$3bdc(a1)	;Memory routine patched!
		move.w	#$4e75,$180(a1)		;Remove disk check 1
		move.l	#$70004e75,$b90(a1)	;Remove disk check 2
		lea	loader(pc),a0
		move.w	d1,$c58(a1)		;Patch game file loader
		move.l	a0,$c58+2(a1)
		move.l	rank+2(pc),a0
		lea	$1d70(a0),a0		;Get RNC depack
		lea	RNC(pc),a2
		move.w	#$20c-1,d0
copy_rnc:
		move.b	(a0)+,(a2)+		;Copy it to slave
		dbra	d0,copy_rnc		
		jmp	(a1)			;Execute boot loader
gamepatch:
		movem.l	d0-d4/a0-a3,-(a7)
		move.l	#$4eb94ef9,d4		;JSR/JMP
		move.l	#$70004e75,d0		;MOVEQ #0,D0 /RTS
		move.l	a1,a2
		move.w	#$6018,$5d92(a1)	;Patch CACR / Illegal
		add.l	#$bd94,a2
		lea	loader2(pc),a0
		move.w	d4,(a2)+
		move.l	a0,(a2)
		move.l	a1,a2
		add.l	#$b12a,a2		;$8bcbc
		lea	loader3(pc),a0
		move.w	d4,(a2)+
		move.l	a0,(a2)
		move.l	a1,a2
		add.l	#$bcbc,a2
		move.w	d4,(a2)+
		move.l	a0,(a2)			
		lea	offset1,a3
		move.w	d0,$8b5c0-offset1(a3)		;Remove disk stop code!
		move.w	d0,$8b972-offset1(a3)
		move.w	d0,$8bd26-offset1(a3)
		move.w	d0,$8c5aa-offset1(a3)
		move.w	d0,$8b43a-offset1(a3)
		move.w	d0,$8b49e-offset1(a3)
		move.w	d0,$8b50c-offset1(a3)
		lea	offset2,a3
		move.w	d0,$aa1ce-offset2(a3)		;Remove "insert save disk"	
		move.w	d0,$aacfe-offset2(a3)		;Remove "insert disk 3"
		move.w	#$64,$aaaa2-offset2(a3)		;Alter position of text box!
		move.w	#$6016,$aaa82-offset2(a3)	;Remove more save shit!
		move.w	#$6008,$aa29e-offset2(a3)	;Bypass stupid load whilst
							;Saving!
		
		lea	savepatch(pc),a0
		move.l	a0,$a9e96-offset2(a3)		
		lea	savepatch2(pc),a0
		move.l	a0,$aa162-offset2(a3)
		lea	save(pc),a0
		lea	$8b5f6,a1
		move.w	d4,(a1)+
		move.l	a0,(a1)				;SAVING IS DONE HERE!!!
		swap	d4	
		lea	$9eb48,a0
		move.w	d4,(a0)+
		lea	access1(pc),a1
		move.l	a1,(a0)
		lea	$96d92,a0
		move.w	d4,(a0)+
		lea	access2(pc),a1
		move.l	a1,(a0)

		lea	$8a74e,a0			;Copylock 1
		lea	$87a14,a1
		lea	$9fcf6,a2
		lea	$ac0a8,a3
		move.l	#$203c3d74,d0
		move.l	#$2cf121c0,d1
		move.l	#$00604e75,d2
		move.l	d0,(a0)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a3)+
		move.l	d1,(a0)+
		move.l	d1,(a1)+
		move.l	d1,(a1)+
		move.l	d1,(a3)+
		move.l	d2,(a0)+
		move.l	d2,(a1)+
		move.l	d2,(a1)+
		move.l	d2,(a3)+		
		;move.w	#$4e71,$85eee		;End game enable!
		movem.l	(a7)+,d0-d4/a0-a3
		jmp	(a1)		



access1:
		move.l	d0,-(a7)
		move.l	(a1),a1
		move.l	a1,d0
		and.l	#$000fffff,d0
		move.l	d0,a1
		move.l	(a7)+,d0
		tst.b	$6e(a1)
		rts
access2:
		move.l	d0,-(a7)
		move.l	(a1),a1
		move.l	a1,d0
		and.l	#$000fffff,d0
		move.l	d0,a1
		move.l	(a7)+,d0
		move.l	$46(a1),a1
		rts

;-------------------------------------
;Load save game loads root track
;with filename data
;-------------------------------------
savepatch:
	movem.l	d0-d7/a2-a6,-(a7)
	lea	saveroot(pc),a0
	lea	$3d48.w,a1
	bra.s	no_point
	
;Save game loads root track
savepatch2:
	movem.l	d0-d7/a2-a6,-(a7)
	lea	saveroot(pc),a0
saver:	lea	$aff3a,a1
no_point:
	bsr.s	_LoadFile
	exg	a0,a1
	movem.l	(a7)+,d0-d7/a2-a6
	moveq	#0,d0
	rts
;--------------------------------------

;on entry: a0 = Filename
;          a1 = Data to save
;          d1 = Size of data to save
save:
	movem.l	d0-d7/a0-a6,-(a7)
	movem.l	d1/a0-a1,-(a7)
	move.l	saver+2(pc),a2		;Root track location
	moveq	#0,d0
	move.l	a2,a3
	move.l	a0,a4
get_slot:
	move.l	a2,a3
	move.l	a0,a4
	tst.l	(a2)
	beq.s	_emptyslot
check_next_char:
	move.b	(a4)+,d2
	cmp.b	(a3)+,d2
	bne.s	_not_same_filename	
	tst.b	d2
	bne.s	check_next_char	
	bra.s	_samename
_not_same_filename:
	lea	$20(a2),a2		;Get next slot!
	addq.w	#1,d0
	cmp.w	#180,d0
	beq.s	_emptyslot
	bra.s	get_slot
_emptyslot:
	move.b	(a0)+,(a2)+		;Copy filename to roottrack!
	bne.s	_emptyslot
	clr.b	(a2)			;Make sure the filename is null!
_samename:
	movem.l	(a7)+,d1/a0-a1
	lea	param(pc),a2
	move.l	a0,-(a7)
copy_param:
	move.b	(a0)+,(a2)+
	bne.s	copy_param
	clr.b	(a2)
	move.l	(a7)+,a0		;SAVE.NAME done!
	lea	save_name(pc),a0	;Change save filename with prefix!
	moveq	#0,d0
	exg	d0,d1
	bsr.s	_SaveFile
	move.l	saver+2(pc),a1
	lea	saveroot(pc),a0
	moveq	#0,d0
	move.w	#6144,d0		;Size of save file!
	bsr.s	_SaveFile
	movem.l	(a7)+,d0-d7/a0-a6
	moveq	#0,d0
	rts

loader:
	movem.l	d0-d7/a0-a6,-(a7)
	bsr.s	_LoadFile
	move.l	a1,a0
	bsr	RNC
	movem.l	(a7)+,d0-d7/a0-a6
	moveq	#0,d0
	tst.w	d0
	rts
loader2:
	movem.l	d0-d7/a0-a6,-(a7)
	cmp.l	#-1,a0			;Fake call to loader if -1
	beq.s	skip_out
	cmp.w	#8,d0			;Fake call to loader if 8
	bne.s	skip_out
	cmp.l	#$80626,a1		;Not a save file if $80626
	bne.s	_not_save_file
	movem.l	a0-a1,-(a7)
	lea	param(pc),a1
copy_sav:
	move.b	(a0)+,(a1)+
	bne.s	copy_sav
	clr.b	(a1)
	movem.l	(a7)+,a0-a1
	lea	save_name(pc),a0	;Change format to prefix!
_not_save_file:
	bsr.s	_LoadFile
	move.l	a1,a0
	bsr.s	RNC			;Depack
skip_out:
	movem.l	(a7)+,d0-d7/a0-a6
	move.l	si(pc),d1		;Put filesize in d1 for game!
	moveq	#0,d0			;No errors
	tst.w	d0			;Test for errors
	rts
;--------------------------------------------
; IFF Decoder for ALL Sensible Software games
;--------------------------------------------
;a0 = filename
;a1 = rawdata	(Where to depack to)
;a2 = cmap	(Where to put CMAP to)
loader3:
	movem.l	d0-d7/a0-a6,-(a7)
	lea	preserver(pc),a3
	move.l	a1,(a3)+
	move.l	a2,(a3)
	movem.l	a0-a2,-(a7)
pos:	lea	$100000,a1		;Area to load IFF file to
	bsr	_LoadFile
	movem.l	(a7)+,a0-a2
	bsr.s	Decode_iff
	movem.l	(a7)+,d0-d7/a0-a6
	move.l	preserver(pc),a0
	add.l	si(pc),a0
	move.l	preserver+4(pc),a1
	add.l	cmap_size(pc),a1
	ori.b	#$80,$8c801
	moveq	#0,d0
	rts
preserver:
	dc.l	0
	dc.l	0
cmap_size:
	dc.l	0
_cmap:
	dc.l	0
;-----------------------------------------
; Routine to decode ALL IFF files!!
;-----------------------------------------
Decode_iff:
	MoveM.L	D0-D7/A0-A6,-(Sp)
	lea	_cmap(pc),a3
	move.l	a2,(a3)
	move.l	pos+2(pc),a0
	Lea	DisplayIff_Variables(Pc),A6
	Moveq	#0,D0
	Moveq	#0,D1
	Moveq	#0,D2
	Moveq	#0,D3
	moveq	#8-1,d4			;8 Variables used, must be clear!
	move.l	a6,-(a7)
clear_vars:
	move.l	d0,(a6)+
	dbra	d4,clear_vars
	move.l	(A7)+,a6	
	
	
	Cmp.L	#"FORM",(A0)		;FORM Header?
	Bne	DisplayIFF_End

	Addq.L	#8,A0	
	Cmp.L	#"ILBM",(A0)+		;Interleaved Bitmap file?
	Bne	DisplayIFF_End



get_it:		Cmp.L	#"BMHD",(A0)		
		beq.s	go_it
		addq.l	#2,a0
		bra.s	get_it

go_it:		Move.W	8(A0),D0	;Width of screen
		LsR.W	#3,D0		;Convert width to bytes
		Move.W	10(A0),D1	;Height of screen
		Move.B	16(A0),D2	;No. of bitplanes
		Move.B  18(A0),D3	;Compression byte - 0=No compression
				;			   1=Compressed		
		Move.L	D0,VAR_IffWidth(A6)
		Move.L	D1,VAR_IffHeight(A6)
		Move.L	D2,VAR_IffNoPlanes(A6)
	
DisplayIFF_Find_CMAP:
	Cmp.L	#"CMAP",(A0)		;Test if colour map chunk
	Beq.S	DisplayIFF_CMAP_Found	;If yes.. process chunk
	Addq.L	#2,A0			;If not.. keep on looking
	Bra.S	DisplayIFF_Find_CMAP

DisplayIFF_CMAP_Found:
	bsr	_8bit
	
	


fucker
; -----------------------------------------------------------------------------
; ----- Process bitplane data chunk -------------------------------------------
; -----------------------------------------------------------------------------

DisplayIff_Find_BODY:
	Cmp.L	#"BODY",(A0)		;Test if body chunk
	Beq.S	DisplayIff_BODY_Found	;If yes.. process chunk
	Addq.L	#2,A0			;If not.. keep on looking
	Bra.S	DisplayIff_Find_BODY
DisplayIff_BODY_Found:
	Addq.L	#8,A0			;Point to start of bitplane data
	tst.l	D3			;Test compression flag
	Beq	DisplayIFF_NoCompression ; If 0, no compression... copy data...
	
					;If 1, compression used
					;so decompress..



; -----	Decompress bitplane data to screen ------------------------------------

	Move.L	VAR_IffWidth(A6),D0	;Get width of screen
	Move.L	VAR_IffHeight(A6),D1	;Get height of screen
	Subq.L	#1,D1
	Mulu.W	D0,D1
	Move.L	D1,D3		;D3=Width*(Height-1)
	
	Move.L	A1,A4		;Store address of screen (Destination)

DisplayIff_ByteLoop:
	Move.L	VAR_IffWidth(A6),D0	;Get width of screen
	Move.L	VAR_IffByteCount(A6),D1	;Get current byte across screen
	Cmp.L	D0,D1		;Test if at end of current line
	Bne.S	DisplayIff_NotEndLine	;If not.. carry on with line..


; ----- Reset line position -----

		clr.l	VAR_IffByteCount(A6)	;Clear byte count
		Addq.L	#1,VAR_IffPlaneCount(A6)	;Update bitplane count
		Add.L	D3,A1		;Point to next screen bitplane (Dest)

		Move.L	VAR_IffNoPlanes(A6),D0	;Get number of bitplanes
		Move.L	VAR_IffPlaneCount(A6),D1	;Get bitplane counter
		Cmp.L	D0,D1		;Test if last bitplane
		Bne.S	DisplayIff_NotLastPlane	;If not.. carry on..


; ----- Reset bitplane position -----

			clr.l	VAR_IffPlaneCount(A6)	;Clear bitplane count
			Move.L	VAR_IffWidth(A6),D0
			Add.L	D0,VAR_IffLineCount(A6)	;Update line count
			Addq.L	#1,VAR_IffHeightCount(A6)	;Update height count
			Move.L	VAR_IffHeight(A6),D0	;Get height of screen
			Move.L	VAR_IffHeightCount(A6),D1	;Get current height count
			Cmp.L	D0,D1		;Test if last line of screen
			Beq	DisplayIFF_End	;If so.. exit routine..
			
			Move.L	A4,A1			;Address of screen
			Add.L	VAR_IffLineCount(A6),A1	;Add current screen offset
; -----

DisplayIff_NotLastPlane:	
DisplayIff_NotEndLine:	
	moveq	#0,d0
	Move.B	(A0),D0			;Get byte code
	Bpl.s	DisplayIff_BytePlus	;Process uncompressed data
	Bmi.s	DisplayIff_ByteMinus	;Process compressed data

; ----- Process uncompressed scan line data -----

DisplayIff_BytePlus:
	Addq.L	#1,A0			;Point past byte code address

	Moveq	#0,D1			;Get value to add to byte count
	Move.B	D0,D1		
	Addq.B	#1,D1		
DisplayIff_PlusLoop:
	Move.B	(A0)+,(A1)+		;Copy byte of data
	Dbf	D0,DisplayIff_PlusLoop	;If D0 not 0.. keep on copying..

	Add.L	D1,VAR_IffByteCount(A6)	;Update byte count
	Bra	DisplayIff_ByteLoop


; ----- Process compressed scan line data -----

DisplayIff_ByteMinus:
	Addq.L	#1,A0			;Point past byte code address
	Neg.B	D0			;Convert byte code to positive

	Moveq	#0,D2			;Get value to add to byte count
	Move.B	D0,D2
	Addq.B	#1,D2

	Move.B	(A0)+,D1		;Get byte of data
DisplayIff_MinusLoop:
	Move.B	D1,(A1)+		;Copy byte of data	
	Dbf	D0,DisplayIff_MinusLoop	;If D0 not 0.. keep on copying

	Add.L	D2,VAR_IffByteCount(A6)	;Update byte count
	Bra	DisplayIff_ByteLoop

; -----

DisplayIFF_NoCompression:	
DisplayIFF_End:	

fucker2
	MoveM.L	(Sp)+,D0-D7/A0-A6
	Rts

;----------------------------------------------------
; This cmap converter is SPECIFIC to all Sensible
; Software games.  Might not work correctly with other
; games
;----------------------------------------------------

_8bit:
	movem.l	d0-d7/a0-a6,-(a7)
	addq.l	#4,a0
	move.l	(a0)+,d0
	lea	cmap_size(pc),a2
	move.l	d0,(a2)			;Cmap Size!
	divs	#$3,d0
	subq.l	#1,d0
	
	move.l	_cmap(pc),a1
Col_Loop:
	clr.w	(a1)
	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	lsl.w	#8,d1
	add.w	d1,(a1)
	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	lsl.w	#4,d1
	add.w	d1,(a1)	
	move.b	(a0)+,d1
	lsr.b	#4,d1
	ext.w	d1
	add.w	d1,(a1)+
	dbf	d0,Col_Loop
	movem.l	(a7)+,d0-d7/a0-a6
	rts
			RsReset
VAR_IffByteCount:	Rs.L	1
VAR_IffPlaneCount:	Rs.L	1
VAR_IffLineCount:	Rs.L	1
VAR_IffHeightCount:	Rs.L	1
VAR_IffNoPlanes:	Rs.L	1
VAR_IffWidth:		Rs.L	1
VAR_IffHeight:		Rs.L	1
VAR_IffLastVar:		Rs.L	1

DisplayIff_Variables:
	DcB.L	VAR_IffLastVar

	
	

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		bra.b	au
_LoadFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		lea	si(pc),a0
		move.l	d0,(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rts
_checkfile:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
_SaveFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
au:		movem.l	(a7)+,d0-d1/a0-a2
		rts

si:
	dc.l	0


RNC:
	dcb.b	$20c

;----------------------------------

	
;======================================================================

	END
