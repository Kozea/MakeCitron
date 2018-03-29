include config.Makefile
-include config.custom.Makefile

BASEVERSION ?= v1
BASEROOT ?= https://raw.githubusercontent.com/Kozea/MakeCitron/$(BASEVERSION)/
BASENAME := base.Makefile
ifeq ($(MAKELEVEL), 0)
RV := $(shell wget -nv -O $(BASENAME) $(BASEROOT)$(BASENAME) 2>&1)
ifeq (0,$(.SHELLSTATUS))
include $(BASENAME)
else
$(error Unable to download $(BASEROOT)$(BASENAME): $(RV))
endif
$(info $(INFO))
else
include $(BASENAME)
endif
