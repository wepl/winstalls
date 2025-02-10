
# where to install via 'make dest'
DEST := wart:po/Powermonger
# additional generated files to put into install
GENFILES := sgsaver

include ../../Makemacros

sgsaver : sgsaver.asm
	$(ASM) $(ASMOUT)$@ $<

