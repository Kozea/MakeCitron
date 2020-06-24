# #############################
# Replace block with following
# statement as first line of
# target project makefile:
#
# include MakeCitron.Makefile
#
###############################
include config.Makefile
-include config.custom.Makefile
include base.Makefile
$(info $(INFO))
###############################

lint:
	@echo It works!
.DEFAULT_GOAL := test

serve-makefile-test:
	python -m http.server 11111
