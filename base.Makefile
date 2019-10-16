VERSION := 1.4.16
# This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/
# Your project Makefile must import `MakeCitron.Makefile` first
# Use `-super` suffix to call for parent tasks
# NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored
#     Therefore a least-specific target is used as dependency
# It supports NODE_ONLY and PYTHON_ONLY configuration variables
COLOR := $(shell [ -t 0 ] && echo 'yes')
SPACE := $(shell echo -e "\t")
ifdef COLOR
C_LEMON := $(shell echo -e "\e[93m")
C_RED := $(shell echo -e "\e[31m")
C_GREEN := $(shell echo -e "\e[32m")
C_YELLOW := $(shell echo -e "\e[33m")
C_PINK := $(shell echo -e "\e[35m")
C_BLUE := $(shell echo -e "\e[36m")
C_WHITE := $(shell echo -e "\e[37m")
C_BOLD := $(shell echo -e "\e[1m")
C_NORMAL := $(shell echo -e "\e[m")
endif
INFO := $(SPACE)$(C_LEMON)🍋  $(C_BOLD)$(C_WHITE)Make$(C_YELLOW)Citron $(C_WHITE)$(VERSION)$(SPACE)$(SPACE)$(C_NORMAL)$(C_WHITE)<$(MAKECMDGOALS)>$(C_BOLD)$(C_YELLOW)@$(C_NORMAL)$(C_WHITE)$(shell hostname)$(C_NORMAL)

# Use bash
SHELL := /bin/bash


# Set PATH to node and python binaries
export PATH := ./node_modules/.bin:$(VENV)/bin:$(PATH)

LOG = @echo -e "\n    $(C_BOLD)$(C_PINK)🞋  $(C_WHITE)$(@:$*=)$(C_RED)$* $(C_BLUE)$(shell seq -s"➘" $$((MAKELEVEL + 1)) | tr -d '[:digit:]')$(C_NORMAL)"

_PYTHON =
_NODE =
ifndef NODE_ONLY
_PYTHON = 1
endif
ifndef PYTHON_ONLY
_NODE = 1
endif

check-enviro%: ## check-environ: Environment checking
	$(LOG)
ifdef _PYTHON
ifeq (, $(PIPENV))
	$(error $(shell echo -e "$(C_BOLD)$(C_PINK)⚠  $(C_RED)ERROR: $(C_NORMAL)$(C_RED)You must have pipenv installed$(C_NORMAL)"))
endif
endif
ifdef _NODE
ifeq (, $(NPM))
	$(error $(shell echo -e "$(C_BOLD)$(C_PINK)⚠  $(C_RED)ERROR: $(C_NORMAL)$(C_RED)You must have yarn installed$(C_NORMAL)"))
endif
endif

#
# Utilities
#
hel%: ## help: Show this help message. (Default)
	$(LOG)
	@echo -e "usage: make [target] ...\n\ntargets:\n	"
	@grep -Eh '^.+:\ .*##\ .+' $(MAKEFILE_LIST) | cut -d '#' -f '3-' | sed -e 's/^\(.*\):\(.*\)/$(C_BOLD)$(C_PINK)\ \1$(C_WHITE):\2$(C_NORMAL)/' | column -t -s ':'
.DEFAULT_GOAL := help

least-specific%:
	@true

make-p: ## make-p: Launch all ${P} targets in parallel and exit as soon as one exits.
	$(LOG)
	set -m; (for p in $(P); do ($(MAKE) $$p || kill 0)& done; wait)
.PHONY: make-p

en%: ## env: Run ${RUN} with Makefile environment
	$(LOG)
	$(RUN)

al%: install build ## all: Install then build
	$(LOG)


ifdef _NODE
STAGED_NODE_FILES := $(shell git diff --cached --name-only --diff-filter=ACM "*.js" "*.jsx" | tr '\n' ' ')
ifneq ($(STAGED_NODE_FILES),)
PARTIALLY_STAGED_NODE_FILES := $(shell git diff --name-only $(STAGED_NODE_FILES))
ifneq ($(PARTIALLY_STAGED_NODE_FILES),)
PARTIALLY_STAGED_FILES += $(PARTIALLY_STAGED_NODE_FILES)
endif
endif
endif

ifdef _PYTHON
STAGED_PYTHON_FILES := $(shell git diff --cached --name-only --diff-filter=ACM "*.py" | tr '\n' ' ')
ifneq ($(STAGED_PYTHON_FILES),)
PARTIALLY_STAGED_PYTHON_FILES := $(shell git diff --name-only $(STAGED_PYTHON_FILES))
ifneq ($(PARTIALLY_STAGED_PYTHON_FILES),)
PARTIALLY_STAGED_FILES += $(PARTIALLY_STAGED_PYTHON_FILES)
endif
endif
endif

pre-commi%: ## pre-commit: Target to run at pre-commit
	$(LOG)
# If there are no interesting staged files, do nothing
ifneq ($(STAGED_PYTHON_FILES)$(STAGED_NODE_FILES),)
ifdef PARTIALLY_STAGED_FILES
	@echo $(C_BOLD)$(C_YELLOW)You have unstaged changes in the following staged files:$(C_NORMAL)
	@$(foreach file, $(PARTIALLY_STAGED_FILES), echo "  $(C_BOLD)$(C_BLUE)*$(C_NORMAL) $(file)";)
	@echo
	@echo Please stash your unstaged changes with $(C_BOLD)git stash -k$(C_NORMAL) and try again.
	@echo $(C_RED)Autoformating failed, aborting commit$(C_NORMAL)
	@echo
	@exit 1
endif
ifneq (,$(STAGED_PYTHON_FILES))
	@isort -rc $(STAGED_PYTHON_FILES)
	@black $(STAGED_PYTHON_FILES)
endif
ifneq (,$(STAGED_NODE_FILES))
	@prettier --write $(STAGED_NODE_FILES)
endif
	@FORMATTED_FILES=`git diff --name-only $(STAGED_PYTHON_FILES) $(STAGED_NODE_FILES)`; if [[ "$$FORMATTED_FILES" ]]; then \
		echo; \
		echo "$(C_BOLD)$(C_YELLOW)Some files have been auto-formatted. Please review these files and add them to the commit: $(C_NORMAL)$(C_BLUE)"; \
		for file in $${FORMATTED_FILES[@]}; do \
			echo "  $(C_BOLD)$(C_GREEN)+$(C_NORMAL) $${file}"; \
		done; \
		echo $(C_NORMAL); \
		exit 1; \
	fi
	$(MAKE) lint
endif


#
# Installing
#
DOT_FILES ?= MakeCitron.Makefile .sass-lint.yml
PYTHON_DOT_FILES ?= .isort.cfg pyproject.toml setup.cfg
NODE_DOT_FILES ?= .eslintrc.json .eslintignore .prettierrc .prettierignore jsconfig.json
ifdef _NODE
DOT_FILES += $(NODE_DOT_FILES)
endif
ifdef _PYTHON
DOT_FILES += $(PYTHON_DOT_FILES)
endif
install-dot-files: ## install-dot-files: Install dot files in project from MakeCitron dots dir
	$(LOG)
	@wget -N -nv $(foreach dot, $(DOT_FILES), $(MAKE_CITRON_ROOT)dots/$(dot))


install-pre-commit: ## install-pre-commit: Install pre-commit hook
	$(LOG)
	@# TODO: Find a better solution to not do this every run
ifneq ($(wildcard .git/hooks),)
	echo 'make pre-commit' > .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit
else
	@echo 'No .git/hooks directory found'
endif

install-node-pro%: ## install-node-prod: Install node dependencies for production
	$(LOG)
	$(NPM) install --prod

install-python-pro%: ## install-python-prod: Install python dependencies for production
	$(LOG)
	$(PIPENV) install --deploy

install-pro%: ## install-prod: Install project dependencies for production
	$(LOG)
ifdef _NODE
	$(MAKE) install-node-prod
endif
ifdef _PYTHON
	$(MAKE) install-python-prod
endif

install-nod%: ## install-node: Install node dependencies for development
	$(LOG)
	yarn install --production=false --check-files
	rm -fr .eslintcache

install-pytho%: ## install-python: Install python dependencies for development
	$(LOG)
	$(PIPENV) install --dev

install-d%: ## install-db: Install database if any
	$(LOG)

pre-instal%:  ## pre-install: Run pre install hooks
	$(LOG)

instal%: least-specific-install check-environ pre-install install-pre-commit ## install: Install project dependencies for development
	$(LOG)
ifdef _NODE
	$(MAKE) install-node
endif
ifdef _PYTHON
	$(MAKE) install-python
endif

full-instal%: ## full-install: Clean everything and install again
	$(LOG)
	$(MAKE) clean-install
	$(MAKE) install

#
# Upgrading
#
upgrade-pytho%: ## upgrade-python: Upgrade locked python dependencies (or ${PKG})
	$(LOG)
	$(PIPENV) update ${PKG}
	$(PIPENV) install --dev

upgrade-nod%: ## upgrade-node: Upgrade interactively locked node dependencies
	$(LOG)
	$(NPM) upgrade-interactive --latest

upgrad%: least-specific-upgrade ## upgrade: Upgrade all dependencies
	$(LOG)
ifdef _NODE
	$(MAKE) upgrade-node
endif
ifdef _PYTHON
	$(MAKE) upgrade-python
endif
#
# Cleaning
#
clean-clien%: ## clean-client: Clean built client assets
	$(LOG)
	rm -fr $(PWD)/lib/frontend/assets/*

clean-serve%: ## clean-server: Clean built server assets
	$(LOG)
	rm -fr dist

clean-lint-cach%:
	rm -fr .eslintcache
	rm -fr .pytest_cache

clean-instal%: clean clean-lint-cache ## clean-install: Clean all installed dependencies
	$(LOG)
ifdef _PYTHON
	rm -fr $(VENV)
	rm -fr *.egg-info
endif
ifdef _NODE
	rm -fr $(NODE_MODULES)
endif

clea%: least-specific-clean ## clean: Clean all built assets
	$(LOG)
	$(MAKE) clean-client
	$(MAKE) clean-server

#
# Linting
#
lint-pytho%: ## lint-python: Lint python source
	$(LOG)
	py.test --flake8 --isort -m "flake8 or isort" lib --ignore=lib/frontend/static

lint-nod%: ## lint-node: Lint node source
	$(LOG)
	eslint --cache --ext .jsx --ext .js lib/

lin%: least-specific-lint ## lint: Lint all source
	$(LOG)
ifdef _NODE
	$(MAKE) lint-node
endif
ifdef _PYTHON
	$(MAKE) lint-python
endif

fix-pytho%: ## fix-python: Fix python source format
	$(LOG)
	isort -rc lib
	black lib

fix-nod%: ## fix-node: Fix node source format
	$(LOG)
	prettier --write '{,lib/**/}*.js?(x)'

fi%: least-specific-fix ## fix: Fix all source format
	$(LOG)
ifdef _NODE
	$(MAKE) fix-node
endif
ifdef _PYTHON
	$(MAKE) fix-python
endif

#
# Testing
#
check-pytho%: ## check-python: Run python tests
	$(LOG)
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) py.test lib $(PYTEST_ARGS)

check-nod%: ## check-node: Run node tests
	$(LOG)
ifeq (,$(DEBUG_NODE))
	jest --no-cache --coverage
else
	inspect $(NODE_MODULES)/.bin/jest --runInBand --env jest-environment-node-debug
endif

check-outdate%: ## check-outdated: Check for outdated dependencies
	$(LOG)
ifdef _NODE
	$(NPM) outdated ||:
endif
ifdef _PYTHON
	$(PIPENV) update --outdated ||:
endif

chec%: least-specific-check ## check: Run all test and output outdated dependencies
	$(LOG)
ifdef _PYTHON
	$(MAKE) check-python
endif
ifdef _NODE
	$(MAKE) check-node
endif
	$(MAKE) check-outdated

#
# Building
#
build-clien%: clean-client ## build-client: Build node client files
	$(LOG)
	WEBPACK_ENV=browser NODE_ENV=production webpack

build-serve%: clean-server ## build-server: Build node server files
	$(LOG)
	WEBPACK_ENV=server NODE_ENV=production webpack

buil%: least-specific-build ## build: Build node files
	$(LOG)
	$(MAKE) build-server
	$(MAKE) build-client

#
# Serving
#
serve-pytho%: ## serve-python: Run python server
	$(LOG)
	flask run --with-threads -h $(HOST) -p $(API_PORT)

serve-nod%: ## serve-node: Run build node server
	$(LOG)
	NODE_ENV=production node dist/server.js

serve-node-serve%: ## serve-node-server: Run node server
	$(LOG)
	WEBPACK_ENV=server NODE_ENV=development webpack --info-verbosity none

serve-node-clien%: ## serve-node-client: Run node development files
	$(LOG)
	WEBPACK_ENV=browser NODE_ENV=development webpack-dev-server

serv%: least-specific-serve clean ## serve: Run all servers in development
	$(LOG)
ifdef NODE_ONLY
	$(MAKE) P="serve-node-client serve-node-server" make-p
else
ifdef PYTHON_ONLY
	$(MAKE) serve-python
else
	$(MAKE) P="serve-node-client serve-node-server serve-python" make-p
endif
endif

ru%: ## run: Run built production servers
	$(LOG)
ifdef NODE_ONLY
	MOCK_NGINX=y $(MAKE) serve-node
else
ifdef PYTHON_ONLY
	FLASK_DEBUG=0 $(MAKE) serve-python
else
	FLASK_DEBUG=0 MOCK_NGINX=y $(MAKE) P="serve-python serve-node" make-p
endif
endif


BRANCH_NAME = $(shell echo $(CI_COMMIT_REF_NAME) | tr -cd "[[:alnum:]]")
URL_TEST ?= https://test-$(CI_PROJECT_NAME)-$(BRANCH_NAME).kozea.fr
URL_TEST_API ?= $(URL_TEST)/api/
URL_PROD ?= https://$(CI_PROJECT_NAME).kozea.fr
URL_PROD_API ?= $(URL_PROD)/api/
JUNKRAT_RESPONSE = /tmp/$(CI_PROJECT_NAME)-$(CI_COMMIT_REF_NAME).log
define newline


endef
define JUNKRAT_PARAMETERS
'{
  "job_id": "$(CI_JOB_ID)",
  "token": "$(TOKEN)",
  "url": "$(CI_REPOSITORY_URL)",
  "build_stage": "$(CI_JOB_STAGE)",
  "project_name": "$(CI_PROJECT_NAME)",
  "branch": "$(CI_COMMIT_REF_NAME)",
  "password": "$(PASSWD)",
  "commit_sha": "$(CI_COMMIT_SHA)",
  "url_test": "$(URL_TEST)"
}'
endef

deploy-tes%: ## deploy-test: Run test deployment for ci
	$(LOG)
	@echo "Communicating with Junkrat..."
	@wget -nv --content-on-error -O- --header="Content-Type:application/json" --post-data=$(subst $(newline),,$(JUNKRAT_PARAMETERS)) $(JUNKRAT) | tee $(JUNKRAT_RESPONSE)
	if [[ $$(tail -n1 $(JUNKRAT_RESPONSE)) != "Success" ]]; then exit 9; fi
	wget -nv --content-on-error -O- $(URL_TEST)
	wget -nv --content-on-error -O- $(URL_TEST_API)

deploy-pro%: ## deploy-prod: Run prod deployment for ci
	$(LOG)
	@echo "Communicating with Junkrat..."
	@wget -nv --content-on-error -O- --header="Content-Type:application/json" --post-data=$(subst $(newline),,$(JUNKRAT_PARAMETERS)) $(JUNKRAT) | tee $(JUNKRAT_RESPONSE)
	if [[ $$(tail -n1 $(JUNKRAT_RESPONSE)) != "Success" ]]; then exit 9; fi
	wget -nv --content-on-error -O- $(URL_PROD)
	wget -nv --content-on-error -O- $(URL_PROD_API)
