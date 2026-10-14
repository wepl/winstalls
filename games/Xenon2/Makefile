
DEST := wart:x-y/xenon2

# two slaves are built from one source via a define
BASE = $(notdir $(CURDIR))
SLAVESRC = xenon2.asm
SLAVE = $(BASE).Slave $(BASE)CDTV.Slave
# $(info SLAVE=$(SLAVE))

# replace default rule in Makemacros
slaves : $(SLAVE)

$(SLAVE) : $(SLAVESRC)
	$(DATE)
	$(ASM) $(if $(findstring CDTV,$@),$(ASMDEF)CDTV) $(ASMOUT)$@ $<

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

include ../../Makemacros

