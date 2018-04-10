include base.Makefile
$(info $(INFO))

test:
	@echo It works!
.DEFAULT_GOAL := test

serve-makefile-test:
	python -m http.server 11111
