#
# recurse over all directories
#

TOPTARGETS := img inst arc wepl clean
SUBDIRS := apps ctros games misc

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TOPTARGETS) $(SUBDIRS)

