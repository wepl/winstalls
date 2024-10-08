	IFND EXEC_TASKS_I
EXEC_TASKS_I SET 1
 IFND EXEC_NODES_I
 INCLUDE "exec/nodes.i"
 ENDC
 IFND EXEC_LISTS_I
 INCLUDE "exec/lists.i"
 ENDC
 IFND EXEC_PORTS_I
 INCLUDE "exec/ports.i"
 ENDC
 STRUCTURE TC_Struct,LN_SIZE
 UBYTE TC_FLAGS
 UBYTE TC_STATE
 BYTE TC_IDNESTCNT
 BYTE TC_TDNESTCNT
 ULONG TC_SIGALLOC
 ULONG TC_SIGWAIT
 ULONG TC_SIGRECVD
 ULONG TC_SIGEXCEPT
 APTR tc_ETask
 APTR TC_EXCEPTDATA
 APTR TC_EXCEPTCODE
 APTR TC_TRAPDATA
 APTR TC_TRAPCODE
 APTR TC_SPREG
 APTR TC_SPLOWER
 APTR TC_SPUPPER
 FPTR TC_SWITCH
 FPTR TC_LAUNCH
 STRUCT TC_MEMENTRY,LH_SIZE
 APTR TC_Userdata
 LABEL TC_SIZE
 STRUCTURE ETask,MN_SIZE
 APTR et_Parent
 ULONG et_UniqueID
 STRUCT et_Children,MLH_SIZE
 UWORD et_TRAPALLOC
 UWORD et_TRAPABLE
 ULONG et_Result1
 APTR et_Result2
 STRUCT et_TaskMsgPort,MP_SIZE
 LABEL ETask_SIZEOF
CHILD_NOTNEW=1
CHILD_NOTFOUND=2
CHILD_EXITED=3
CHILD_ACTIVE=4
 STRUCTURE StackSwapStruct,0
 APTR stk_Lower
 ULONG stk_Upper
 APTR stk_Pointer
 LABEL StackSwapStruct_SIZEOF
 BITDEF T,PROCTIME,0
 BITDEF T,ETASK,3
 BITDEF T,STACKCHK,4
 BITDEF T,EXCEPT,5
 BITDEF T,SWITCH,6
 BITDEF T,LAUNCH,7
TS_INVALID= 0
TS_ADDED= TS_INVALID+1
TS_RUN= TS_ADDED+1
TS_READY= TS_RUN+1
TS_WAIT= TS_READY+1
TS_EXCEPT= TS_WAIT+1
TS_REMOVED= TS_EXCEPT+1
 BITDEF SIG,ABORT,0
 BITDEF SIG,CHILD,1
 BITDEF SIG,BLIT,4
 BITDEF SIG,SINGLE,4
 BITDEF SIG,INTUITION,5
 BITDEF SIG,NET,7
 BITDEF SIG,DOS,8
SYS_SIGALLOC=$0FFFF
SYS_TRAPALLOC=$08000
 ENDC
