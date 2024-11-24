
# where to install via 'make dest'
DEST := awart:workbench31

# multiple slaves are build from one source via a define
BASE = $(notdir $(CURDIR))
SLAVESRC = workbench31.asm
SLAVE = $(foreach mem,1 4 32,$(BASE)_$(mem).Slave)
# $(info SLAVE=$(SLAVE))

# replace default rule in Makemacros
slaves : $(SLAVE)

$(SLAVE) : $(SLAVESRC)
	$(DATE)
	$(ASM) $(ASMDEF)MEM=$(patsubst $(BASE)_%.Slave,%,$@) $(ASMOUT)$@ $<

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

include ../../Makemacros

