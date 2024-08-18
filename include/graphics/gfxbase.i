 IFND GRAPHICS_GFXBASE_I
GRAPHICS_GFXBASE_I SET 1
 IFND EXEC_LISTS_I
 include 'exec/lists.i'
 ENDC
 IFND EXEC_LIBRARIES_I
 include 'exec/libraries.i'
 ENDC
 IFND EXEC_INTERRUPTS_I
 include 'exec/interrupts.i'
 ENDC
 IFND GRAPHICS_MONITOR_I
 include 'graphics/monitor.i'
 ENDC
 STRUCTURE GfxBase,LIB_SIZE
 APTR gb_ActiView
 APTR gb_copinit
 APTR gb_cia
 APTR gb_blitter
 APTR gb_LOFlist
 APTR gb_SHFlist
 APTR gb_blthd
 APTR gb_blttl
 APTR gb_bsblthd
 APTR gb_bsblttl
 STRUCT gb_vbsrv,IS_SIZE
 STRUCT gb_timsrv,IS_SIZE
 STRUCT gb_bltsrv,IS_SIZE
 STRUCT gb_TextFonts,LH_SIZE
 APTR gb_DefaultFont
 UWORD gb_Modes
 BYTE gb_VBlank
 BYTE gb_Debug
 UWORD gb_BeamSync
 WORD gb_system_bplcon0
 BYTE gb_SpriteReserved
 BYTE gb_bytereserved
 WORD gb_Flags
 WORD gb_BlitLock
 WORD gb_BlitNest
 STRUCT gb_BlitWaitQ,LH_SIZE
 APTR gb_BlitOwner
 STRUCT gb_TOF_WaitQ,LH_SIZE
 WORD gb_DisplayFlags
 APTR gb_SimpleSprites
 WORD gb_MaxDisplayRow
 WORD gb_MaxDisplayColumn
 WORD gb_NormalDisplayRows
 WORD gb_NormalDisplayColumns
 WORD gb_NormalDPMX
 WORD gb_NormalDPMY
 APTR gb_LastChanceMemory
 APTR gb_LCMptr
 WORD gb_MicrosPerLine
 WORD gb_MinDisplayColumn
 UBYTE gb_ChipRevBits0
 UBYTE gb_MemType
 STRUCT gb_crb_reserved,4
 STRUCT gb_monitor_id,2
 STRUCT gb_hedley,4*8
 STRUCT gb_hedley_sprites,4*8
 STRUCT gb_hedley_sprites1,4*8
 WORD gb_hedley_count
 WORD gb_hedley_flags
 WORD gb_hedley_tmp
 APTR gb_hash_table
 UWORD gb_current_tot_rows
 UWORD gb_current_tot_cclks
 UBYTE gb_hedley_hint
 UBYTE gb_hedley_hint2
 STRUCT gb_nreserved,4*4
 APTR gb_a2024_sync_raster
 UWORD gb_control_delta_pal
 UWORD gb_control_delta_ntsc
 APTR gb_current_monitor
 STRUCT gb_MonitorList,LH_SIZE
 APTR gb_default_monitor
 APTR gb_MonitorListSemaphore
 APTR gb_DisplayInfoDataBase
 UWORD gb_TopLine
 APTR gb_ActiViewCprSemaphore
 APTR gb_UtilBase
 APTR gb_ExecBase
 APTR gb_bwshifts
 APTR gb_StrtFetchMasks
 APTR gb_StopFetchMasks
 APTR gb_Overrun
 APTR gb_RealStops
 WORD gb_SpriteWidth
 WORD gb_SpriteFMode
 BYTE gb_SoftSprites
 BYTE gb_arraywidth
 WORD gb_DefaultSpriteWidth
 BYTE gb_SprMoveDisable
 BYTE gb_WantChips
 UBYTE gb_BoardMemType
 UBYTE gb_Bugs
 ULONG gb_LayersBase
 ULONG gb_ColorMask
 APTR gb_IVector
 APTR gb_IData
 ULONG gb_SpecialCounter
 APTR gb_DBList
 UWORD gb_MonitorFlags
 BYTE gb_ScanDoubledSprites
 BYTE gb_BP3Bits
 STRUCT gb_MonitorVBlank,asi_SIZEOF
 APTR gb_natural_monitor
 APTR gb_ProgData
 BYTE gb_ExtSprites
 UBYTE gb_pad3
 WORD gb_GfxFlags
 ULONG gb_VBCounter
 APTR gb_HashTableSemaphore
 STRUCT gb_HWEmul,9*4
 LABEL gb_SIZE
gb_ChunkyToPlanarPtr=gb_HWEmul
OWNBLITTERn=0 * blitter owned bit
QBOWNERn=1 * blitter owned by blit queuer
BLITMSG_FAULTn=2
BLITMSG_FAULT=1<<BLITMSG_FAULTn
QBOWNER=1<<QBOWNERn
 BITDEF GBFLAGS,TIMER,6
 BITDEF GBFLAGS,LASTBLIT,7
 BITDEF GFX,BIG_BLITS,0
 BITDEF GFX,HR_AGNUS,0
 BITDEF GFX,HR_DENISE,1
 BITDEF GFX,AA_ALICE,2
 BITDEF GFX,AA_LISA,3
 BITDEF GFX,AA_MLISA,4
SETCHIPREV_A=GFXF_HR_AGNUS
SETCHIPREV_ECS=(GFXF_HR_AGNUS!GFXF_HR_DENISE)
SETCHIPREV_AA=(GFXF_AA_ALICE!GFXF_AA_LISA!SETCHIPREV_ECS)
SETCHIPREV_BEST=$ffffffff
BUS_16=0
NML_CAS=0
BUS_32=1
DBL_CAS=2
BANDWIDTH_1X=(BUS_16!NML_CAS)
BANDWIDTH_2XNML=BUS_32
BANDWIDTH_2XDBL=DBL_CAS
BANDWIDTH_4X=(BUS_32!DBL_CAS)
NTSCn=0
NTSC=1<<NTSCn
GENLOCn=1
GENLOC=1<<GENLOCn
PALn=2
PAL=1<<PALn
TODA_SAFEn=3
TODA_SAFE=1<<TODA_SAFEn
REALLY_PALn=4
REALLY_PAL=1<<REALLY_PALn
LPEN_SWAP_FRAMESn=5
LPEN_SWAP_FRAMES=1<<LPEN_SWAP_FRAMESn
GRAPHICSNAME MACRO
 DC.B 'graphics.library',0
 ENDM
 ENDC
