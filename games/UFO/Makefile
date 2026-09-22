# files from inst/ to be included in the install package
INSTFILES = locale.library

# where to install via 'make dest'
DEST := wart:u/ufo

# two slaves are build from two separate sources
BASE = $(notdir $(CURDIR))
SLAVESRC = ufo.asm
AGASLAVESRC = ufo_aga.asm
SLAVE = $(BASE).Slave $(BASE)_AGA.Slave
# $(info SLAVE=$(SLAVE))

# replace default rule in Makemacros
slaves : $(SLAVE)

$(BASE).Slave : $(SLAVESRC)
	$(DATE)
	$(ASM) $(ASMOUT)$@ $<

$(BASE)_AGA.Slave : $(AGASLAVESRC)
	$(DATE)
	$(ASM) $(ASMOUT)$@ $<

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

include ../../Makemacros
