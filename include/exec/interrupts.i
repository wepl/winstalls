	IFND EXEC_INTERRUPTS_I
EXEC_INTERRUPTS_I SET 1
 IFND EXEC_NODES_I
 INCLUDE "exec/nodes.i"
 ENDC
 IFND EXEC_LISTS_I
 INCLUDE "exec/lists.i"
 ENDC
 STRUCTURE IS,LN_SIZE
 APTR IS_DATA
 APTR IS_CODE
 LABEL IS_SIZE
 STRUCTURE IV,0
 APTR IV_DATA
 APTR IV_CODE
 APTR IV_NODE
 LABEL IV_SIZE
 BITDEF S,SAR,15
 BITDEF S,TQE,14
 BITDEF S,SINT,13
 STRUCTURE SH,LH_SIZE
 UWORD SH_PAD
 LABEL SH_SIZE
SIH_PRIMASK=$0F0
SIH_QUEUES=5
 BITDEF INT,NMI,15
 ENDC
