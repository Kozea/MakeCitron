include config.Makefile
-include config.custom.Makefile

BASEVERSION ?= v1
BASEROOT ?= https://raw.githubusercontent.com/Kozea/MakeCitron/$(BASEVERSION)/
BASENAME = base.Makefile
ifeq ($(MAKELEVEL), 0)
include $(shell wget -q --show-progress -O $(BASENAME) $(BASEROOT)$(BASENAME) && echo $(BASENAME))
else
include $(BASENAME)
endif
