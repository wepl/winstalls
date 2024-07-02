#
# Makefile macros for WHDLoad Slaves
#
# supports basm/vasm on Amiga/MacOS/Linux
#
# $@ target
# $< first dependency
# $^ all dependencies

# enable a non-debug assemble:
# 'setenv DEBUG=0' or 'make DEBUG=0'

# print all make variables
#$(foreach v,$(.VARIABLES),$(info $(v) = $($(v))))
# print all make variables defined between both statements
#VARS_OLD := $(.VARIABLES)
#$(foreach v,$(filter-out $(VARS_OLD) VARS_OLD,$(.VARIABLES)),$(info $(v) = $($(v))))

ARCH=$(shell uname -p)
BIN=bin/arch-$(ARCH)
INCLUDE=../../include

# different commands for build under Amiga or Vamos
ifdef AMIGA

# basm options: -x+ = use cachefile.library -s1+ = create SAS/D1 debug hunks -sa+ = create symbol hunks
BASMOPT=-x+
BASMOPTDBG=-sa+
# vincludeos3: must before netinclude: because broken netinclude
CFLAGS=-Ivincludeos3: -Inetinclude:
CP=Copy Clone
RM=Delete

# on Amiga default=DEBUG
ifndef DEBUG
DEBUG=1
endif

else

# basm options: -x- = don't use cachefile.library -sa+ = create symbol hunks
BASMOPT=-x-
BASMOPTDBG=-sa+
VASMOPT=-I$(INCLUDE)
CFLAGS=-I$(VBCC)/targets/m68k-amigaos/include -I$(INCLUDE)
CP=cp -p
RM=rm
VAMOS=vamos -qC68020 -m4096 -s128 --

# on Vamos default=NoDEBUG
ifndef DEBUG
DEBUG=0
endif

endif

ifeq ($(DEBUG),1)

# Debug options
# ASM creates executables, ASMB binary files, ASMO object files
# BASM: -H to show all unused Symbols/Labels, requires -OG-
ASM=$(VAMOS) basm -v+ $(BASMOPT) $(BASMOPTDBG) -O+ -ODc- -ODd- -wo- -dDEBUG=1
ASMB=$(ASM)
ASMO=$(ASM)
ASMDEF=-d
ASMOUT=-o
CC=vc -c99 -g -I. $(CFLAGS) -DOS_AMIGAOS -DDEBUG -sc

else

# normal options
# VASM: -wfail -warncomm -databss
ASMBASE=vasmm68k_mot $(VASMOPT) -ignore-mult-inc -nosym -quiet -wfail -opt-allbra -opt-clr -opt-lsl -opt-movem -opt-nmoveq -opt-pea -opt-size -opt-st
ASM=$(ASMBASE) -Fhunkexe
ASMB=$(ASMBASE) -Fbin
ASMO=$(ASMBASE) -Fhunk
ASMDEF=-D
ASMOUT=-o 
CC=vc -c99 -g -I. $(CFLAGS) -DOS_AMIGAOS -O2 -size -sc

endif

# general programs
RELOC=$(VAMOS) Reloc
LN=vlink -bamigahunk -Bstatic -Cvbcc -nostdlib -s -Rstd -sc -o

#
# default target: build Slave
#
$(SLAVE) : $(SLAVESRC)
	$(ASM) $(ASMOUT)$@ $<

#
# target: copy Slave to installed location for testing
#
dest : $(SLAVE)
	$(CP) $< $(SLAVEDEST)

#
# target: build install package
#
inst : $(SLAVE)

#
# generic rules
#

%.abs : %.exe
	$(RELOC) ADR=0 $< $@ FailRelocs

%.o : %.s
	${ASMO} $(ASMOUT)$@ $<

%.o : %.c
	$(CC) -o $@ -c $<

#
# generic targets
#

clean :
	$(RM) $(SLAVE)

