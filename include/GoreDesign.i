
;--- define some opcodes

_nop	=$4e71
_rte	=$4e73
_rts	=$4e75
_rtr	=$4e77

_jmp	=$4ef9
_jsr	=$4eb9

_trap0	=$4e40
_trap1	=$4e41
_trap2	=$4e42
_trap3	=$4e43
_trap4	=$4e44
_trap5	=$4e45
_trap6	=$4e46
_trap7	=$4e47
_trap8	=$4e48
_trap9	=$4e49
_trapa	=$4e4a
_trapb	=$4e4b
_trapc	=$4e4c
_trapd	=$4e4d
_trape	=$4e4e
_trapf	=$4e4f

_cd0	=$7000					; moveq	#0,d0
_cd1	=$7200					; moveq	#0,d1
_cd2	=$7400					; moveq	#0,d2
_cd3	=$7600					; moveq	#0,d3
_cd4	=$7800					; moveq	#0,d4
_cd5	=$7a00					; moveq	#0,d5
_cd6	=$7c00					; moveq	#0,d6
_cd7	=$7e00					; moveq	#0,d7

_nopnop	=$4e714e71


;--- put all registers on stack

pushall	macro

	movem.l	d0-a7,-(sp)

	endm


;--- get all registers from stack

pullall	macro

	movem.l	(sp)+,d0-a7

	endm


;--- flash screen and wait for lmb

flash	macro

.loop	move	$dff006,$dff180
	btst	#6,$bfe001
	bne.b	.loop

	endm

****************************************************************
***** write opcode JMP \2 to address \1
patch	MACRO
	IFNE	NARG-2
		FAIL	arguments "patch"
	ENDC
		move.w	#$4ef9,\1
		pea	\2(pc)
		move.l	(a7)+,2+\1
	ENDM

****************************************************************
***** write opcode JSR \2 to address \1
patchs	MACRO
	IFNE	NARG-2
		FAIL	arguments "patchs"
	ENDC
		move.w	#$4eb9,\1
		pea	\2(pc)
		move.l	(a7)+,2+\1
	ENDM

