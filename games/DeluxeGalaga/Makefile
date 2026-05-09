
DEST := wart:de/DeluxeGalaga

# multiple slaves are build from one source via a define
BASE = $(notdir $(CURDIR))
SLAVESRC = DeluxeGalaga.s
SLAVE = $(foreach cs,AGA ECS,$(BASE)$(cs).Slave)
# $(info SLAVE=$(SLAVE))

# replace default rule in Makemacros
slaves : $(SLAVE)

$(SLAVE) : $(SLAVESRC)
	$(DATE)
	$(ASM) $(ASMDEF)AGA=$(if $(findstring AGA,$@),1,0) $(ASMOUT)$@ $<

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

include ../../Makemacros

