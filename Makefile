#
# recurse over all directories
#

TOPTARGETS := inst arc wepl clean
SUBDIRS := ctros games

$(TOPTARGETS): $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TOPTARGETS) $(SUBDIRS)

