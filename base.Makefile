VERSION := 1.2.12
# This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/
# It should be used with the script present in exemple.Makefile
# Use `-super` suffix to call for parent tasks
# NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored
#     Therefore a least-specific target is used as dependency
# It supports NODE_ONLY and PYTHON_ONLY configuration variables

INFO := $(shell echo -e "    \e[0;93m🍋  \e[1;37mMake\e[1;33mCitron \e[1;37m$(VERSION)\e[0m")

# Use bash
SHELL := /bin/bash

# Set PATH to node and python binaries
export PATH := ./node_modules/.bin:.venv/bin:$(PATH)

LOG = @echo -e "\n  \e[1;35m🞋  \e[1;37m$(@:$*=)\e[1;31m$* \e[1;36m$(shell seq -s"➘" $$((MAKELEVEL + 1)) | tr -d '[:digit:]')\e[0m"

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
	$(error $(shell echo -e "\e[1;35m⚠  \e[1;31mERROR: \e[0;35mYou must have pipenv installed\e[0m"))
endif
endif
ifdef _NODE
ifeq (, $(NPM))
	$(error $(shell echo -e "\e[1;35m⚠  \e[1;31mERROR: \e[0;35mYou must have yarn installed\e[0m"))
endif
endif

#
# Utilities
#
hel%: ## help: Show this help message. (Default)
	$(LOG)
	@echo -e "usage: make [target] ...\n\ntargets:\n	"
	@grep -Eh '^.+:\ .*##\ .+' $(MAKEFILE_LIST) | cut -d '#' -f '3-' | sed -e 's/^\(.*\):\(.*\)/\o033[1;35m\ \1\o033[0;37m:\2\o033[0m/' | column -t -s ':'
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

pre-commi%: ## pre-commit: Target to run at pre-commit
	$(LOG)
	$(MAKE) fix
	$(MAKE) lint

#
# Installing
#
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

yarn.lock: node_modules package.json
	$(LOG)
	yarn install --production=false --check-files
	touch -mr $(shell ls -Atd $? | head -1) $@

node_modules:
	$(LOG)
	mkdir -p $@

Pipfile.lock: .venv Pipfile
	$(LOG)
	$(PIPENV) install --dev
	touch -mr $(shell ls -Atd $? | head -1) $@

.venv:
	$(LOG)
	$(PIPENV) --python $(PYTHON_VERSION)

install-nod%: yarn.lock ## install-node: Install node dependencies for development
	$(LOG)

install-pytho%: Pipfile.lock ## install-python: Install python dependencies for development
	$(LOG)

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
upgrade-pytho%: ## upgrade-python: Upgrade locked python dependencies
	$(LOG)
	$(PIPENV) update
	$(PIPENV) lock  # Maybe remove this later
	$(PIPENV) install

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

clean-instal%: clean ## clean-install: Clean all installed dependencies
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
	yapf -vv -p -i -r lib

fix-nod%: ## fix-node: Fix node source format
	$(LOG)
	prettier --write '{,lib/tests/**/,lib/frontend/src/**/}*.js?(x)'

fi%: least-specific-fix install ## fix: Fix all source format
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
	jest --no-cache
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

buil%: least-specific-build install ## build: Build node files
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
	WEBPACK_ENV=server NODE_ENV=development webpack

serve-node-clien%: ## serve-node-client: Run node development files
	$(LOG)
	WEBPACK_ENV=browser NODE_ENV=development webpack-dev-server

serv%: least-specific-serve clean install ## serve: Run all servers in development
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

ru%: install ## run: Run built production servers
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
URL_TEST_API ?= https://test-$(CI_PROJECT_NAME)-$(BRANCH_NAME).kozea.fr/api
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
	@echo "Communicating with Junkrat... (outing to $(JUNKRAT_RESPONSE))"
	@wget --no-verbose --content-on-error -O- --header="Content-Type:application/json" --post-data=$(subst $(newline),,$(JUNKRAT_PARAMETERS)) $(JUNKRAT) | tee $(JUNKRAT_RESPONSE)
ifneq ($(shell tail -n1 $(JUNKRAT_RESPONSE)),Success)
	exit 9
endif
	wget --no-verbose --content-on-error -O- $(URL_TEST)
	wget --no-verbose --content-on-error -O- $(URL_TEST_API)
