
INCLUDE=../include
SOURCES=../sources

include ../Maketools

%.slave : %.asm
	$(DATE)
	$(ASM) $(ASMOUT)$@ $<

#
# build all Slaves
#

all : $(patsubst %.asm,%.slave,$(wildcard *.asm))

#
# dummy targets to make globally working
#
img :
dest :
inst :
arc :
rel :

#
# generic targets
#

clean :
	$(RM) .date .depend.* *.slave *.bak

#
# targets to always build
#
.PHONY : clean

