
# where to install via 'make dest'
DEST := wart:n/north\&south
# two ISlaves from one source
ISLAVE1 := $(notdir $(CURDIR)).ISlave
ISLAVE2 := $(notdir $(CURDIR))-files.ISlave
ISLAVE := $(ISLAVE1) $(ISLAVE2)
# disable ISLAVE rule in Makemacros
NOISLAVERULE = 1

include ../../Makemacros

$(ISLAVE1) : $(ISLAVESRC)
	$(DATE)
	$(ASM) $(ASMOUT)$@ $<

$(ISLAVE2) : $(ISLAVESRC)
	$(DATE)
	$(ASM) $(ASMDEF)_Files $(ASMOUT)$@ $<

