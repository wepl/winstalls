	IFND GRAPHICS_DISPLAYINFO_I
GRAPHICS_DISPLAYINFO_I SET 1
 IFND EXEC_TYPES_I
 include 'exec/types.i'
 ENDC
 IFND GRAPHICS_GFX_I
 include 'graphics/gfx.i'
 ENDC
 IFND UTILITY_TAGITEM_I
 include 'utility/tagitem.i'
 ENDC
DTAG_DISP= $80000000
DTAG_DIMS= $80001000
DTAG_MNTR= $80002000
DTAG_NAME= $80003000
DTAG_VEC= $80004000
 STRUCTURE QueryHeader,0
 ULONG qh_StructID
 ULONG qh_DisplayID
 ULONG qh_SkipID
 ULONG qh_Length
 LABEL qh_SIZEOF
 STRUCTURE DisplayInfo,qh_SIZEOF
 UWORD dis_NotAvailable
 ULONG dis_PropertyFlags
 STRUCT dis_Resolution,tpt_SIZEOF
 UWORD dis_PixelSpeed
 UWORD dis_NumStdSprites
 UWORD dis_PaletteRange
 STRUCT dis_SpriteResolution,tpt_SIZEOF
 STRUCT dis_pad,4
 UBYTE RedBits
 UBYTE GreenBits
 UBYTE BlueBits
 STRUCT dis_pad2,5
 STRUCT dis_reserved,8
 LABEL dis_SIZEOF
DI_AVAIL_NOCHIPS=$0001
DI_AVAIL_NOMONITOR=$0002
DI_AVAIL_NOTWITHGENLOCK=$0004
DIPF_IS_LACE=$00000001
DIPF_IS_DUALPF=$00000002
DIPF_IS_PF2PRI=$00000004
DIPF_IS_HAM=$00000008
DIPF_IS_ECS=$00000010
DIPF_IS_AA=$00010000
DIPF_IS_PAL=$00000020
DIPF_IS_SPRITES=$00000040
DIPF_IS_GENLOCK=$00000080
DIPF_IS_WB=$00000100
DIPF_IS_DRAGGABLE=$00000200
DIPF_IS_PANELLED=$00000400
DIPF_IS_BEAMSYNC=$00000800
DIPF_IS_EXTRAHALFBRITE=$00001000
DIPF_IS_SPRITES_ATT=$00002000
DIPF_IS_SPRITES_CHNG_RES=$00004000
DIPF_IS_SPRITES_BORDER=$00008000
DIPF_IS_SCANDBL=$00020000
DIPF_IS_SPRITES_CHNG_BASE=$00040000
DIPF_IS_SPRITES_CHNG_PRI=$00080000
DIPF_IS_DBUFFER=$00100000
DIPF_IS_PROGBEAM=$00200000
DIPF_IS_FOREIGN=$80000000
 STRUCTURE DimensionInfo,qh_SIZEOF
 UWORD dim_MaxDepth
 UWORD dim_MinRasterWidth
 UWORD dim_MinRasterHeight
 UWORD dim_MaxRasterWidth
 UWORD dim_MaxRasterHeight
 STRUCT dim_Nominal,ra_SIZEOF
 STRUCT dim_MaxOScan,ra_SIZEOF
 STRUCT dim_VideoOScan,ra_SIZEOF
 STRUCT dim_TxtOScan,ra_SIZEOF
 STRUCT dim_StdOScan,ra_SIZEOF
 STRUCT dim_pad,14
 STRUCT dim_reserved,8
 LABEL dim_SIZEOF
 STRUCTURE MonitorInfo,qh_SIZEOF
 APTR mtr_Mspc
 STRUCT mtr_ViewPosition,tpt_SIZEOF
 STRUCT mtr_ViewResolution,tpt_SIZEOF
 STRUCT mtr_ViewPositionRange,ra_SIZEOF
 UWORD mtr_TotalRows
 UWORD mtr_TotalColorClocks
 UWORD mtr_MinRow
 WORD mtr_Compatibility
 STRUCT mtr_pad,32
 STRUCT mtr_MouseTicks,tpt_SIZEOF
 STRUCT mtr_DefaultViewPosition,tpt_SIZEOF
 ULONG mtr_PreferredModeID
 STRUCT mtr_reserved,8
 LABEL mtr_SIZEOF
MCOMPAT_MIXED= 0
MCOMPAT_SELF= 1
MCOMPAT_NOBODY=-1
DISPLAYNAMELEN=32
 STRUCTURE NameInfo,qh_SIZEOF
 STRUCT nif_Name,DISPLAYNAMELEN
 STRUCT nif_reserved,8
 LABEL nif_SIZEOF
 STRUCTURE VecInfo,qh_SIZEOF
 APTR vec_Vec
 APTR vec_Data
 UWORD vec_Type
 STRUCT vec_pad,6
 STRUCT vec_reserved,8
 LABEL vec_SIZEOF
 IFND GRAPHICS_MODEID_I
 include 'graphics/modeid.i'
 ENDC
 ENDC
