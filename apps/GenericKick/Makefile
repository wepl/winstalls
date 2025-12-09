
# where to install via 'make dest'
DEST := awart:GenericKick

# multiple slaves are build
BASE = $(notdir $(CURDIR))
SLAVE = $(foreach rel,13 31,$(BASE)$(rel).Slave)

# replace default rule in Makemacros
default : $(SLAVE)

# disable SLAVE rule in Makemacros
NOSLAVERULE = 1

# no install script, directly runnable
NOINSTALL := true

# additional files to copy from 'inst' to install directory
INSTFILES := data

include ../../Makemacros

