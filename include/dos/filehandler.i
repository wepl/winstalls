	IFND DOS_FILEHANDLER_I
DOS_FILEHANDLER_I SET 1
 IFND EXEC_TYPES_I
 INCLUDE "exec/types.i"
 ENDC
 IFND EXEC_PORTS_I
 INCLUDE "exec/ports.i"
 ENDC
 IFND DOS_DOS_I
 INCLUDE "libraries/dos.i"
 ENDC
 STRUCTURE DosEnvec,0
 ULONG de_TableSize
 ULONG de_SizeBlock
 ULONG de_SecOrg
 ULONG de_Surfaces
 ULONG de_SectorPerBlock
 ULONG de_BlocksPerTrack
 ULONG de_Reserved
 ULONG de_PreAlloc
 ULONG de_Interleave
 ULONG de_LowCyl
 ULONG de_HighCyl
 ULONG de_NumBuffers
 ULONG de_BufMemType
 ULONG de_MaxTransfer
 ULONG de_Mask
 LONG de_BootPri
 ULONG de_DosType
 ULONG de_Baud
 ULONG de_Control
 ULONG de_BootBlocks
 LABEL DosEnvec_SIZEOF
DE_TABLESIZE=0
DE_SIZEBLOCK=1
DE_SECORG=2
DE_NUMHEADS=3
DE_SECSPERBLK=4
DE_BLKSPERTRACK=5
DE_RESERVEDBLKS=6
DE_PREFAC=7
DE_INTERLEAVE=8
DE_LOWCYL=9
DE_UPPERCYL=10
DE_NUMBUFFERS=11
DE_MEMBUFTYPE=12
DE_BUFMEMTYPE=12
DE_MAXTRANSFER=13
DE_MASK=14
DE_BOOTPRI=15
DE_DOSTYPE=16
DE_BAUD=17
DE_CONTROL=18
DE_BOOTBLOCKS=19
 STRUCTURE FileSysStartupMsg,0
 ULONG fssm_Unit
 BSTR fssm_Device
 BPTR fssm_Environ
 ULONG fssm_Flags
 LABEL FileSysStartupMsg_SIZEOF
 STRUCTURE DeviceNode,0
 BPTR dn_Next
 ULONG dn_Type
 CPTR dn_Task
 BPTR dn_Lock
 BSTR dn_Handler
 ULONG dn_StackSize
 LONG dn_Priority
 BPTR dn_Startup
 BPTR dn_SegList
 BPTR dn_GlobalVec
 BSTR dn_Name
 LABEL DeviceNode_SIZEOF
 ENDC
