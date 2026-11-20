
# where to install via 'make dest'
DEST := wart:sh/simcity

# two slaves are built from one source via a define
BASE = $(notdir $(CURDIR))
SLAVESRC = simcity.asm
SLAVE = $(BASE).Slave $(BASE)CDTV.Slave

# replace default rule in Makemacros
slaves : $(SLAVE)

$(SLAVE) : $(SLAVESRC)
	$(DATE)
	$(ASM) $(if $(findstring CDTV,$@),$(ASMDEF)CDTV) $(ASMOUT)$@ $<

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

include ../../Makemacros
