#
# Makefile for WHDLoad.Audio, the audio plugin for WHDLoad
# the plugin must be copied to the directory where WHDLoad is located
#

INCLUDE=../include

include ../Maketools

PLUGIN=WHDLoad.Audio

all : $(PLUGIN)

$(PLUGIN) : $(PLUGIN).asm amigus.s vs1063a-patches.bin $(INCLUDE)/whdaudio.i $(INCLUDE)/whdload.i
	$(DATE)
	$(ASM) $(ASMOUT)$@ $<

clean :
	$(RM) $(PLUGIN) .date .depend.*

