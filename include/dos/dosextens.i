	IFND DOS_DOSEXTENS_I
DOS_DOSEXTENS_I SET 1
 IFND EXEC_TYPES_I
 INCLUDE "exec/types.i"
 ENDC
 IFND EXEC_TASKS_I
 INCLUDE "exec/tasks.i"
 ENDC
 IFND EXEC_PORTS_I
 INCLUDE "exec/ports.i"
 ENDC
 IFND EXEC_LIBRARIES_I
 INCLUDE "exec/libraries.i"
 ENDC
 IFND EXEC_SEMAPHORES_I
 INCLUDE "exec/semaphores.i"
 ENDC
 IFND DEVICES_TIMER_I
 INCLUDE "devices/timer.i"
 ENDC
 IFND DOS_DOS_I
 INCLUDE "dos/dos.i"
 ENDC
 STRUCTURE Process,0
 STRUCT pr_Task,TC_SIZE
 STRUCT pr_MsgPort,MP_SIZE * This is BPTR address from DOS functions
 WORD pr_Pad * Remaining variables on 4 byte boundaries
 BPTR pr_SegList * Array of seg lists used by this process
 LONG pr_StackSize * Size of process stack in bytes
 APTR pr_GlobVec * Global vector for this process (BCPL)
 LONG pr_TaskNum * CLI task number of zero if not a CLI
 BPTR pr_StackBase * Ptr to high memory end of process stack
 LONG pr_Result2 * Value of secondary result from last call
 BPTR pr_CurrentDir * Lock associated with current directory
 BPTR pr_CIS * Current CLI Input Stream
 BPTR pr_COS * Current CLI Output Stream
 APTR pr_ConsoleTask * Console handler process for current window
 APTR pr_FileSystemTask * File handler process for current drive
 BPTR pr_CLI * pointer to CommandLineInterface
 APTR pr_ReturnAddr * pointer to previous stack frame
 APTR pr_PktWait * Function to be called when awaiting msg
 APTR pr_WindowPtr * Window pointer for errors
 BPTR pr_HomeDir * Home directory of executing program
 LONG pr_Flags * flags telling dos about process
 APTR pr_ExitCode * code to call on exit of program or NULL
 LONG pr_ExitData * Passed as an argument to pr_ExitCode
 APTR pr_Arguments * Arguments passed to the process at start
 STRUCT pr_LocalVars,MLH_SIZE * Local environment variables
 APTR pr_ShellPrivate * for the use of the current shell
 BPTR pr_CES * Error stream - if NULL, use pr_COS
 LABEL pr_SIZEOF * Process
 BITDEF PR,FREESEGLIST,0
 BITDEF PR,FREECURRDIR,1
 BITDEF PR,FREECLI,2
 BITDEF PR,CLOSEINPUT,3
 BITDEF PR,CLOSEOUTPUT,4
 BITDEF PR,FREEARGS,5
 STRUCTURE FileHandle,0
 APTR fh_Link * pointer to EXEC message
 APTR fh_Interactive * Boolean
 APTR fh_Type * Port to do PutMsg() to
 LONG fh_Buf
 LONG fh_Pos
 LONG fh_End
 LONG fh_Funcs
fh_Func1=fh_Funcs
 LONG fh_Func2
 LONG fh_Func3
 LONG fh_Args
fh_Arg1=fh_Args
 LONG fh_Arg2
 LABEL fh_SIZEOF * FileHandle
 STRUCTURE DosPacket,0
 APTR dp_Link * pointer to EXEC message
 APTR dp_Port * pointer to Reply port for the packet
 LONG dp_Type * See ACTION_... below and
 LONG dp_Res1 * For file system calls this is the result
 LONG dp_Res2 * For file system calls this is what would
 LONG dp_Arg1
dp_Action=dp_Type
dp_Status=dp_Res1
dp_Status2=dp_Res2
dp_BufAddr=dp_Arg1
 LONG dp_Arg2
 LONG dp_Arg3
 LONG dp_Arg4
 LONG dp_Arg5
 LONG dp_Arg6
 LONG dp_Arg7
 LABEL dp_SIZEOF * DosPacket
 STRUCTURE StandardPacket,0
 STRUCT sp_Msg,MN_SIZE
 STRUCT sp_Pkt,dp_SIZEOF
 LABEL sp_SIZEOF * StandardPacket
ACTION_NIL=0
ACTION_STARTUP=0
ACTION_GET_BLOCK=2
ACTION_SET_MAP=4
ACTION_DIE=5
ACTION_EVENT=6
ACTION_CURRENT_VOLUME=7
ACTION_LOCATE_OBJECT=8
ACTION_RENAME_DISK=9
ACTION_WRITE='W'
ACTION_READ='R'
ACTION_FREE_LOCK=15
ACTION_DELETE_OBJECT=16
ACTION_RENAME_OBJECT=17
ACTION_MORE_CACHE=18
ACTION_COPY_DIR=19
ACTION_WAIT_CHAR=20
ACTION_SET_PROTECT=21
ACTION_CREATE_DIR=22
ACTION_EXAMINE_OBJECT=23
ACTION_EXAMINE_NEXT=24
ACTION_DISK_INFO=25
ACTION_INFO=26
ACTION_FLUSH=27
ACTION_SET_COMMENT=28
ACTION_PARENT=29
ACTION_TIMER=30
ACTION_INHIBIT=31
ACTION_DISK_TYPE=32
ACTION_DISK_CHANGE=33
ACTION_SET_DATE=34
ACTION_SCREEN_MODE=994
ACTION_READ_RETURN=1001
ACTION_WRITE_RETURN=1002
ACTION_SEEK=1008
ACTION_FINDUPDATE=1004
ACTION_FINDINPUT=1005
ACTION_FINDOUTPUT=1006
ACTION_END=1007
ACTION_SET_FILE_SIZE=1022
ACTION_WRITE_PROTECT=1023
ACTION_SAME_LOCK=40
ACTION_CHANGE_SIGNAL=995
ACTION_FORMAT=1020
ACTION_MAKE_LINK=1021
ACTION_READ_LINK=1024
ACTION_FH_FROM_LOCK=1026
ACTION_IS_FILESYSTEM=1027
ACTION_CHANGE_MODE=1028
ACTION_COPY_DIR_FH=1030
ACTION_PARENT_FH=1031
ACTION_EXAMINE_ALL=1033
ACTION_EXAMINE_FH=1034
ACTION_LOCK_RECORD=2008
ACTION_FREE_RECORD=2009
ACTION_ADD_NOTIFY=4097
ACTION_REMOVE_NOTIFY=4098
ACTION_EXAMINE_ALL_END=1035
ACTION_SET_OWNER=1036
ACTION_SERIALIZE_DISK=4200
 STRUCTURE ErrorString,0
 APTR estr_Nums
 APTR estr_Strings
 LABEL ErrorString_SIZEOF
 STRUCTURE DosLibrary,0
 STRUCT dl_lib,LIB_SIZE
 APTR dl_Root * Pointer to RootNode, described below
 APTR dl_GV * Pointer to BCPL global vector
 LONG dl_A2 * BCPL standard register values
 LONG dl_A5
 LONG dl_A6
 APTR dl_Errors * PRIVATE pointer to array of error msgs
 APTR dl_TimeReq * PRIVATE pointer to timer request
 APTR dl_UtilityBase * PRIVATE pointer to utility library base
 APTR dl_IntuitionBase * PRIVATE pointer to intuition library base
 LABEL dl_SIZEOF * DosLibrary
 STRUCTURE RootNode,0
 BPTR rn_TaskArray * [0] is max number of CLI's
*			       * [1] is APTR to process id of CLI 1
*			       * [n] is APTR to process id of CLI n
    BPTR    rn_ConsoleSegment  * SegList for the CLI
    STRUCT  rn_Time,ds_SIZEOF  * Current time
    LONG    rn_RestartSeg      * SegList for the disk validator process
    BPTR    rn_Info	       * Pointer to the Info structure
    BPTR    rn_FileHandlerSegment * code for file handler
    STRUCT  rn_CliList,MLH_SIZE * new list of all CLI processes
*			       * the first cpl_Array is also rn_TaskArray
    APTR    rn_BootProc	       * private! ptr to msgport of boot fs
    BPTR    rn_ShellSegment    * seglist for Shell (for NewShell)
    LONG    rn_Flags	       * dos flags
    LABEL   rn_SIZEOF * RootNode

 BITDEF	RN,WILDSTAR,24
 BITDEF RN,PRIVATE1,1

* ONLY to be allocated by DOS!
 STRUCTURE CliProcList,0
    STRUCT  cpl_Node,MLN_SIZE
    LONG    cpl_First	       * number of first entry in array
    APTR    cpl_Array	       * pointer to array of process msgport pointers
*			       * [0] is max number of CLI's in this entry (n)
 LABEL cpl_SIZEOF
 STRUCTURE DosInfo,0
 BPTR di_McName * PRIVATE: system resident module list
di_ResList=di_McName
 BPTR di_DevInfo * Device List
 BPTR di_Devices * Currently zero
 BPTR di_Handlers * Currently zero
 APTR di_NetHand * Network handler processid currently zero
 STRUCT di_DevLock,SS_SIZE * do NOT access directly!
 STRUCT di_EntryLock,SS_SIZE * do NOT access directly!
 STRUCT di_DeleteLock,SS_SIZE * do NOT access directly!
 LABEL di_SIZEOF * DosInfo
 STRUCTURE Segment,0
 BPTR seg_Next
 LONG seg_UC
 BPTR seg_Seg
 STRUCT seg_Name,4
 LABEL seg_SIZEOF
CMD_SYSTEM=-1
CMD_INTERNAL=-2
CMD_DISABLED=-999
 STRUCTURE CommandLineInterface,0
 LONG cli_Result2 * Value of IoErr from last command
 BSTR cli_SetName * Name of current directory
 BPTR cli_CommandDir * Head of the path locklist
 LONG cli_ReturnCode * Return code from last command
 BSTR cli_CommandName * Name of current command
 LONG cli_FailLevel * Fail level (set by FAILAT)
 BSTR cli_Prompt * Current prompt (set by PROMPT)
 BPTR cli_StandardInput * Default (terminal) CLI input
 BPTR cli_CurrentInput * Current CLI input
 BSTR cli_CommandFile * Name of EXECUTE command file
 LONG cli_Interactive * Boolean True if prompts required
 LONG cli_Background * Boolean True if CLI created by RUN
 BPTR cli_CurrentOutput * Current CLI output
 LONG cli_DefaultStack * Stack size to be obtained in long words
 BPTR cli_StandardOutput * Default (terminal) CLI output
 BPTR cli_Module * SegList of currently loaded command
 LABEL cli_SIZEOF * CommandLineInterface
 STRUCTURE DevList,0
 BPTR dl_Next
 LONG dl_Type
 APTR dl_Task
 BPTR dl_Lock
 STRUCT dl_VolumeDate,ds_SIZEOF
 BPTR dl_LockList
 LONG dl_DiskType
 LONG dl_unused
 BSTR dl_Name
 LABEL DevList_SIZEOF
 STRUCTURE DevInfo,0
 BPTR dvi_Next
 LONG dvi_Type
 APTR dvi_Task
 BPTR dvi_Lock
 BSTR dvi_Handler
 LONG dvi_Stacksize
 LONG dvi_Priority
 LONG dvi_Startup
 BPTR dvi_SegList
 BPTR dvi_GlobVec
 BSTR dvi_Name
 LABEL dvi_SIZEOF
 STRUCTURE DosList,0
 BPTR dol_Next
 LONG dol_Type
 APTR dol_Task
 BPTR dol_Lock
 STRUCT dol_VolumeDate,0
 STRUCT dol_AssignName,0
 BSTR dol_Handler
 STRUCT dol_List,0
 LONG dol_StackSize
 LONG dol_Priority
 STRUCT dol_LockList,0
 ULONG dol_Startup
 STRUCT dol_DiskType,0
 BPTR dol_SegList
 BPTR dol_GlobVec
 BSTR dol_Name
 LABEL DosList_SIZEOF
DLT_DEVICE=0
DLT_DIRECTORY=1
DLT_VOLUME=2
DLT_LATE=3
DLT_NONBINDING=4
DLT_PRIVATE=-1
 STRUCTURE DevProc,0
 APTR dvp_Port
 BPTR dvp_Lock
 ULONG dvp_Flags
 APTR dvp_DevNode
 LABEL dvp_SIZEOF
 BITDEF DVP,UNLOCK,0
 BITDEF DVP,ASSIGN,1
 BITDEF LD,DEVICES,2
 BITDEF LD,VOLUMES,3
 BITDEF LD,ASSIGNS,4
 BITDEF LD,ENTRY,5
 BITDEF LD,DELETE,6
 BITDEF LD,READ,0
 BITDEF LD,WRITE,1
LDF_ALL=(LDF_DEVICES!LDF_VOLUMES!LDF_ASSIGNS)
 STRUCTURE FileLock,0
 BPTR fl_Link
 LONG fl_Key
 LONG fl_Access
 APTR fl_Task
 BPTR fl_Volume
 LABEL fl_SIZEOF
REPORT_STREAM=0
REPORT_TASK=1
REPORT_LOCK=2
REPORT_VOLUME=3
REPORT_INSERT=4
ABORT_DISK_ERROR=296
ABORT_BUSY=288
RUN_EXECUTE=-1
RUN_SYSTEM=-2
RUN_SYSTEM_ASYNCH=-3
ST_ROOT=1
ST_USERDIR=2
ST_SOFTLINK=3
ST_LINKDIR=4
ST_FILE=-3
ST_LINKFILE=-4
ST_PIPEFILE=-5
 ENDC
