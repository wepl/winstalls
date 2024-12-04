
		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"Pacmania.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	10			;ws_Version
		dc.w	WHDLF_EmulTrap|WHDLF_NoError		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================
		IFND	.passchk
		DOSCMD	"WDate  >T:date"
.passchk
		ENDC

_name		dc.b	"Pacmania",0
_copy		dc.b	"1988 Grandslam",0
_info		dc.b	"Installed by Codetapper/Action!",10
		dc.b	"Version 1.0 "
		INCBIN	"T:date"
		dc.b	-1,"Keys: Help - Toggle infinite lives",10
		dc.b	"       Del - Toggle permanent turbo",-1
		dc.b	"Thanks to Chris Vella for the original!",0
_Highs		dc.b	"Pacmania.highs",0
_CheatFlag	dc.b	0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

_restart	lea	$8,a0
		lea	$7f000,a1
_Clear		clr.l	(a0)+
		cmp.l	a0,a1
		bcc	_Clear

		lea	_Bootblock(pc),a0	;Decrunch bootblock into position
		lea	$7dbd4,a1
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_Decrunch(a2)

		lea	_PL_Boot(pc),a0
		move.l	a5,a1
		jsr	resload_Patch(a2)

		move.l	#$18c00,d0		;Load main game
		move.l	#$b000,d1
		moveq	#1,d2
		lea	$70000,a0
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		move.l	#$fffffffe,$3fc		;Setup copperlist
		move.l	#$3fc,$dff080
		move.l	#$3fc,$dff088
		move.w	#$83d0,$dff096		;Enable DMA

		jmp	$7dc02

_PL_Boot	PL_START
		PL_S	$66,$ea-$66		;Load first file
		PL_P	$126,_Picture
		PL_END

;======================================================================

_Picture	move.l	#$82a00,d0		;Load main game
		move.l	#$25200,d1
		moveq	#1,d2
		lea	$4c00,a0
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)

		lea	_PL_Picture(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		movea.l	#$4c00,a6		;Stolen code
		jmp	(a6)

_PL_Picture	PL_START
		PL_P	$100,_Game
		PL_W	$4c54,$b4ac
		PL_END

;======================================================================

_Game		movem.l	d0-d2/a0-a2,-(sp)

		clr.l	-(a7)			;TAG_DONE
                clr.l	-(a7)			;data to fill
		move.l	#WHDLTAG_BUTTONWAIT_GET,-(a7)
		move.l	a7,a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		move.l	(4,a7),d0		;d0 = -1 if ButtonWait
		lea	(12,a7),a7		;Restore sp

		tst.l	d0
		beq	_ShortDelay

		move.l	#5*60*50,d0		;Wait 5 minutes
		bra	_Delay

_ShortDelay	move.l	#50,d0
_Delay		bsr	_DelayD0

_1		lea	_PL_Game(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)

		bsr	_LoadHighScores

;		lea	$d0fe,a0
;		moveq	#4,d0
;		move.l	_resload(pc),a2
;		jsr	resload_ProtectWrite(a2)
		movem.l	(sp)+,d0-d2/a0-a2

		jmp	$5014

_PL_Game	PL_START
	PL_L	$d192,$4e714e71
		PL_P	$8756,_Loader		;Patch loader
		PL_PS	$56fc,_Keybd		;Detect quit key
		PL_L	$5702,$4e714e71
		PL_L	$575a,$4eb80112		;Empty DBF loop
		PL_PS	$cec6,_SaveHighScores	;Save scores unless cheating
		PL_P	$100,_Blit_d4_a0	;Setup blitter patches
		PL_P	$106,_Blit_d6_a0
		PL_P	$10c,_Blit_d4_a2
		PL_P	$112,_EmptyDBF		;Empty DBF loop
		PL_L	$C95E,$4eb80100
		PL_L	$C950,$4eb80100
		PL_L	$C942,$4eb80100
		PL_L	$C8F0,$4eb80100
		PL_L	$C8DE,$4eb80100
		PL_L	$C8CC,$4eb80100
		PL_L	$722A,$4eb80100
		PL_L	$723C,$4eb80100
		PL_L	$724E,$4eb80100
		PL_L	$7CC8,$4eb80106
		PL_L	$7070,$4eb80106
		PL_L	$707E,$4eb80106
		PL_L	$708C,$4eb80106
		PL_L	$6E8E,$4eb8010c
		PL_L	$6EA0,$4eb8010c
		PL_L	$6EB2,$4eb8010c
		PL_PS	$CC3A,_Blit_0204_a0
		PL_PS	$CC4A,_Blit_0204_a0
		PL_PS	$CC5A,_Blit_0204_a0
		PL_PS	$CA8C,_Blit_0405_a0
		PL_PS	$CA9C,_Blit_0405_a0
		PL_PS	$CAAC,_Blit_0405_a0
		PL_PS	$CA24,_Blit_0401_a0
		PL_PS	$CA3C,_Blit_0401_a0
		PL_PS	$CA54,_Blit_0401_a0
		PL_PS	$C828,_Blit_0203_a0
		PL_PS	$C838,_Blit_0203_a0
		PL_PS	$C848,_Blit_0203_a0
		PL_PS	$B4B2,_Blit_4b34_a0
		PL_PS	$B4C0,_Blit_4b34_a0
		PL_PS	$B4CE,_Blit_4b34_a0
		PL_PS	$BC14,_Blit_4b34_a0
		PL_PS	$BC22,_Blit_4b34_a0
		PL_PS	$BC30,_Blit_4b34_a0
		PL_PS	$7E9E,_Blit_0102_a0
		PL_PS	$7EBA,_Blit_0102_a0
		PL_PS	$7ED6,_Blit_0102_a0
		PL_PS	$7C1A,_Blit_0202_a0
		PL_PS	$7C90,_Blit_0202_a0
		PL_PS	$7170,_Blit_0603_a0
		PL_PS	$7188,_Blit_0603_a0
		PL_PS	$71A0,_Blit_0603_a0
		PL_PS	$6588,_Blit_4416_a0
		PL_PS	$658E,_Blit_4416_a0
		PL_PS	$6594,_Blit_4416_a0
		PL_PS	$65A8,_Blit_4416_a0
		PL_PS	$65AE,_Blit_4416_a0
		PL_PS	$65B4,_Blit_4416_a0
		PL_END

;======================================================================

_Keybd		ori.b	#$40,($e00,a1)		;Stolen code
		not.b	d0
		ror.b	#1,d0

		cmp.b	_keyexit(pc),d0
		beq	_exit

_CheckHelp	cmp.b	#$5f,d0
		bne	_CheckDel

		eor.w	#$5339^$6018,$d34e	;Toggle infinite lives
		bsr	_SetCheat

_CheckDel	cmp.b	#$46,d0
		bne	_RTS

		cmp.w	#$5379,$d380
		beq	_StartCheat
		move.w	#0,$53f8		;Set turbo off
		bra	_ToggleIns
_StartCheat	move.w	#$320,$53f8		;Set 16 seconds of turbo
_ToggleIns	eor.w	#$5379^$4a79,$d380	;Turbo mode at all times
		eor.w	#$4279^$4a79,$5cb4

		bsr	_SetCheat

_RTS		cmp.b	#$58,d0
		beq	_1Life
		rts

_1Life		move.b	#1,$53ec
		rts

;======================================================================

_SetCheat	move.l	a0,-(sp)
		lea	_CheatFlag(pc),a0
		move.b	#-1,(a0)
		move.l	(sp)+,a0
		rts

;======================================================================

_Loader		movem.l	d0-d2/a0-a2,-(sp)	;d1 = address, d2 = length, (8,a6).w = offset (tracks)
		moveq	#0,d0
		move.l	d1,a0			;a0 = dest address
		move.l	d2,d1			;d1 = length
		move.w	(8,a6),d0
		mulu.w	#$1600,d0		;d0 = offset
		moveq	#1,d2			;d2 = disk
                move.l  _resload(pc),a2
		jsr	resload_DiskLoad(a2)	;a0 = destination
		movem.l	(sp)+,d0-d2/a0-a2
		rts

;======================================================================

_LoadHighScores	movem.l	d0-d1/a0-a3,-(sp)
		lea	$d0aa,a1
		move.l	a1,a3
		lea	_Highs(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		tst.l	d0
		beq	_NoHighsFound

		lea	_Highs(pc),a0		;a0 = Filename
		move.l	a3,a1			;a1 = Address
		move.l	a1,-(sp)
		jsr	resload_LoadFile(a2)
		move.l	(sp)+,a1
		bsr	_Encrypt

_NoHighsFound	movem.l	(sp)+,d0-d1/a0-a3
		rts

;======================================================================

_SaveHighScores	movem.l	d0-d1/a0-a2,-(sp)

		move.b	_CheatFlag(pc),d0	;Check if user is a cheat
		bne	_DoNotSave

		lea	_Highs(pc),a0		;a0 = Filename
		lea	$d0aa,a1		;a1 = Address
		move.l  _resload(pc),a2
		bsr	_Encrypt		;Encrypt scores
		move.l	a1,-(sp)
		jsr	resload_SaveFile(a2)	;Save scores
		move.l	(sp)+,a1
		bsr	_Encrypt		;Decrypt scores

_DoNotSave	movem.l	(sp)+,d0-d1/a0-a2
		cmpi.b	#' ',(3,a3)		;Stolen code
		rts

;======================================================================

_Encrypt	move.l	#80,d0			;Set d0 = length
		move.l	d0,-(sp)
.enc		eor.b	d0,(a1)+
		subq.l	#1,d0
		bne.s	.enc
		move.l	(sp)+,d0
		sub.l	d0,a1
		rts

;======================================================================

_EmptyDBF	movem.l	d0-d1,-(sp)
	move.w	#$f00,$dff180
		moveq	#3-1,d1			;wait because handshake min 75 탎
.int2w1		move.b	(_custom+vhposr),d0
.int2w2		cmp.b	(_custom+vhposr),d0	;one line is 63.5 탎
		beq	.int2w2
		dbf	d1,.int2w1		;(min=127탎 max=190.5탎)
	move.w	#$0,$dff180
		movem.l	(sp)+,d0-d1
		rts

;======================================================================

_Blit_d4_a0	move.w	d4,($58,a0)
		bra.b	_BlitWait

_Blit_d4_a2	move.w	d4,($58,a2)
		bra.w	_BlitWait

_Blit_d6_a0	move.w	d6,($58,a0)
		bra.b	_BlitWait

_Blit_0102_a0	move.w	#$102,($58,a0)
		bra.b	_BlitWait

_Blit_0202_a0	move.w	#$202,($58,a0)
		bra.b	_BlitWait

_Blit_0203_a0	move.w	#$203,($58,a0)
		bra.b	_BlitWait

_Blit_0204_a0	move.w	#$204,($58,a0)
		bra.b	_BlitWait

_Blit_0401_a0	move.w	#$401,($58,a0)
		bra.b	_BlitWait

_Blit_0405_a0	move.w	#$405,($58,a0)
		bra.b	_BlitWait

_Blit_0603_a0	move.w	#$603,($58,a0)
		bra.b	_BlitWait

_Blit_4416_a0	move.w	#$4416,($58,a0)
		bra.b	_BlitWait

_Blit_4b34_a0	move.w	#$4B34,($58,a0)
		bra.b	_BlitWait

_BlitWait	
_11		btst	#6,$dff002
		bne	_11
		rts
		BLITWAIT
		rts

;======================================================================

_DelayD0	move.l	a0,-(a7)		;Waits for d0 frames or
		lea	(_custom),a0		;the mouse button
.down		bsr	.wait
		subq	#1,d0
		beq	.done
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)	;LMB
		beq	.up
		btst	#POTGOB_DATLY-8,(potinp,a0)	;RMB
		beq	.up
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)	;FIRE
		bne	.down
.up		bsr	.wait
		btst	#CIAB_GAMEPORT0,(ciapra+_ciaa)	;LMB
		beq	.up
		btst	#POTGOB_DATLY-8,(potinp,a0)	;RMB
		beq	.up
		btst	#CIAB_GAMEPORT1,(ciapra+_ciaa)	;FIRE
		beq	.up
		bsr	.wait
		bra	.done
.wait		waitvb	a0
		rts
.done		move.l	(a7)+,a0
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

_Bootblock	dc.l	$524E4301,$400,$2EA,$2049542F,$11C11
		dc.l	$19AA5A05,$33333343,$654286AA,$4A01CE0C,$444F5300
		dc.l	$462EA949,$370,$6022EFEB,$4B6D6002,$601A41FA
		dc.l	$FFFA303C,$FF43F9,$7DC00,$22D851C8,$FFFC4EC2
		dc.l	$5C024113,$1ADFF000,$317C3FFF,$9A4FFA,$462BFD0
		dc.l	$45AC5D,$E0011029,$1000240,$F97F1340,$5A26F5B5
		dc.l	$517261D5,$3E3A7E09,$A2B48BD4,$AD041C51,$CFFFF610
		dc.l	$2A087588,$4670E01,$E47AA666,$F2C165FD,$EAB84D81
		dc.l	$8D58426E,$6302E,$4E1AB07C,$126712,$52403D40
		dc.l	$926A0066,$EA6EC3AC,$60E42A47,$55074299,$2D4D0C44
		dc.l	$AF1AEC73,$66762C17,$4BFA01F0,$21B18580,$84302800
		dc.l	$88ADDD8A,$42680104,$C160038,$929391,$9419CC2C
		dc.l	$81008E60,$46FFC100,$90857000,$966369FE,$E67BD95F
		dc.l	$F6DD3EB6,$9B004CB6,$A77A6D8B,$162C6357,$4ED6613C
		dc.l	$422E768E,$954C7560,$FF7661,$2ED5D204,$D853D49E
		dc.l	$5244360C,$B298BF0,$525EF45A,$121A3700,$E64E75F4
		dc.l	$8477EC02,$6D3001E5,$400AB987,$41201F4,$FB800122
		dc.l	$866D2F18,$6304B16C,$AE662030,$76448900,$7E840C86
		dc.l	$38610024,$64F79ED8,$3D760574,$FF9B761E,$5A040156
		dc.l	$CAFFF656,$CBFFF267,$BBC78965,$9CDE4177,$744A5904
		dc.l	$5FEC2E3C,$556F74FD,$E60C5832,$5866FA0C,$504D5206
		dc.l	$41E860F4,$43C61504,$1B3B30E0,$9812565F,$B00167C3
		dc.l	$9D03E860,$D6345E64,$73512A4D,$68027C7F,$DFC70E2A
		dc.l	$C051CEFF,$F8D0CB71,$E1201822,$19C087E3,$80C28780
		dc.l	$81476EFC,$72FED119,$52004E71,$3FC42E05,$18303C21
		dc.l	$48C392E0,$35020500,$8298C64,$D0067F8,$A4310E6D
		dc.l	$3CC09774,$842E313,$7A747FC2,$876DF16B,$5CD93605
		dc.l	$5774FE01,$6A050120,$13132624,$C35D3036,$1282B98
		dc.l	$12C3298,$98303698,$98343A98,$98383E98,$183C6732
		dc.l	$A2310A32,$1FFFE02,$7E956CE2,$9CBCE4C5,$5BE61F40
		dc.l	$E8EA3E,$8000ECBC,$6CEE5D41,$5EF0F298,$F27D80D9
		dc.l	$79820EEE,$1840EE8,$1860820,$1880E5E,$4F50368A
		dc.l	$EC0018C,$EA0018E,$E800190,$C600192,$A940AF6
		dc.l	$289600AE,$198008E,$19A006E,$19C000C,$19E0238
		dc.l	$1C5A172,$1A20150,$1A40607,$7BA6F4E1,$A80CCC01
		dc.l	$AA0AAA01,$AC099901,$AE077701,$B0066601,$B2055501
		dc.l	$B4044401,$B6033301,$B800D601,$BA01A701,$BC019501
		dc.l	$BE018337,$567143E3,$181E401,$9F90FFFA,$22CA86FF
		dc.l	$FFF1DE00
		END
