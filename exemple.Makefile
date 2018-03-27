iinclude config.Makefile
-include config.custom.Makefile

BASEVERSION ?= v1
BASEROOT ?= https://raw.githubusercontent.com/Kozea/MakeCitron/$(BASEVERSION)/
BASENAME = base.Makefile
ifeq ($(MAKELEVEL), 0)
include $(shell wget -q -O $(BASENAME) $(BASEROOT)$(BASENAME) && echo $(BASENAME))
$(info $(INFO) $(shell md5sum $(BASENAME)))
else
include $(BASENAME)
endif
