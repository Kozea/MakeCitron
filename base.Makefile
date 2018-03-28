VERSION := 1.0.2
INFO := $(shell echo -e "    \e[0;93m🍋  \e[1;37mMake\e[1;33mCitron \e[1;37m$(VERSION)\e[0m")
# This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/
# It should be used with the script present in exemple.Makefile
# Use `-super` suffix to call for parent tasks
# NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored

# Use bash
SHELL := /bin/bash

# Set PATH to node and python binaries
export PATH := ./node_modules/.bin:.venv/bin:$(PATH)

#
# Functions
#
define target_log
	@echo -e "\n  \e[1;35m🞋  \e[1;37m$(@:$*=)\e[1;31m$* \e[1;36m$(shell seq -s"➘" $$((MAKELEVEL + 1)) | tr -d '[:digit:]')\e[0m\n"
endef


# Environment checking
ifeq (, $(NODE_ONLY))
ifeq (, $(PIPENV))
ERROR := $(shell echo -e "\e[1;35m⚠  \e[1;31mERROR: \e[0;35mYou must have pipenv installed\e[0m")
$(error $(ERROR))
endif
endif

ifeq (, $(PYTHON_ONLY))
ifeq (, $(NPM))
ERROR := $(shell echo -e "\e[1;35m⚠  \e[1;31mERROR: \e[0;35mYou must have yarn installed\e[0m")
$(error $(ERROR))
endif
endif

#
# Utilities
#
hel%: ## help: Show this help message. (Default)
	$(call target_log)
	@echo -e "usage: make [target] ...\n\ntargets:\n	"
	@grep -Eh '^.+:\ .*##\ .+' $(MAKEFILE_LIST) | cut -d '#' -f '3-' | sed -e 's/^\(.*\):\(.*\)/\o033[1;35m\ \1\o033[0;37m:\2\o033[0m/' | column -t -s ':'
.DEFAULT_GOAL := help

make-p: ## make-p: Launch all ${P} targets in parallel and exit as soon as one exits.
	$(call target_log)
	set -m; (for p in $(P); do ($(MAKE) $$p || kill 0)& done; wait)
.PHONY: make-p

en%: ## env: Run ${RUN} with Makefile environment
	$(call target_log)
	$(RUN)

al%: install build ## all: Install then build
	$(call target_log)

#
# Environment checking
#
check-node-binar%: ## check-node-binary: Ensure yarn is installed or throw error
	$(call target_log)

check-python-binar%: ## check-python-binary: Ensure pipenv is installed or throw error
	$(call target_log)


#
# Installing
#
install-node-pro%: check-node-binary ## install-node-prod: Install node dependencies for production
	$(call target_log)
	$(NPM) install --prod

install-python-pro%: check-python-binary check-python-environ ## install-python-prod: Install python dependencies for production
	$(call target_log)
	$(PIPENV) install --deploy

install-pro%: install-node-prod install-python-prod ## install-prod: Install project dependencies for production
	$(call target_log)

yarn.lock: node_modules package.json
	$(call target_log)
	yarn install --production=false --check-files
	touch -mr $(shell ls -Atd $? | head -1) $@

node_modules:
	$(call target_log)
	mkdir -p $@

Pipfile.lock: .venv Pipfile
	$(call target_log)
	$(PIPENV) install --dev
	touch -mr $(shell ls -Atd $? | head -1) $@

.venv:
	$(call target_log)
	$(PIPENV) --python $(PYTHON_VERSION)

install-nod%: check-node-binary yarn.lock ## install-node: Install node dependencies for development
	$(call target_log)

install-pytho%: check-python-binary Pipfile.lock ## install-python: Install python dependencies for development
	$(call target_log)

install-d%: ## install-db: Install database if any
	$(call target_log)

instal%: install-node install-python ## install: Install project dependencies for development
	$(call target_log)

full-instal%: ## full-install: Clean everything and install again
	$(call target_log)
	$(MAKE) clean-install
	$(MAKE) install

#
# Upgrading
#
upgrade-pytho%: ## upgrade-python: Upgrade locked python dependencies
	$(call target_log)
	$(PIPENV) update
	$(PIPENV) lock  # Maybe remove this later
	$(PIPENV) install

upgrade-nod%: ## upgrade-node: Upgrade interactively locked node dependencies
	$(call target_log)
	$(NPM) upgrade-interactive --latest

upgrad%: upgrade-python upgrade-node ## upgrade: Upgrade all dependencies
	$(call target_log)

#
# Cleaning
#
clean-clien%: ## clean-client: Clean built client assets
	$(call target_log)
	rm -fr $(PWD)/lib/frontend/assets/*

clean-serve%: ## clean-server: Clean built server assets
	$(call target_log)
	rm -fr dist

clean-instal%: clean ## clean-install: Clean all installed dependencies
	$(call target_log)
	rm -fr $(NODE_MODULES)
	rm -fr $(VENV)
	rm -fr *.egg-info

clea%: clean-client clean-server ## clean: Clean all built assets
	$(call target_log)

#
# Linting
#
lint-pytho%: ## lint-python: Lint python source
	$(call target_log)
	py.test --flake8 --isort -m "flake8 or isort" lib --ignore=lib/frontend/static

lint-nod%: ## lint-node: Lint node source
	$(call target_log)
	eslint --cache --ext .jsx --ext .js lib/

lin%: lint-python lint-node ## lint: Lint all source
	$(call target_log)

fix-pytho%: ## fix-python: Fix python source format
	$(call target_log)
	yapf -vv -p -i lib/**/*.py

fix-nod%: ## fix-node: Fix node source format
	$(call target_log)
	prettier --write '{,lib/tests/**/,lib/frontend/src/**/}*.js?(x)'

fi%: install fix-python fix-node ## fix: Fix all source format
	$(call target_log)

#
# Testing
#
check-pytho%: ## check-python: Run python tests
	$(call target_log)
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) py.test lib $(PYTEST_ARGS)

check-nod%: ## check-node: Run node tests
	$(call target_log)
ifeq (,$(DEBUG_NODE))
	jest --no-cache
else
	inspect $(NODE_MODULES)/.bin/jest --runInBand --env jest-environment-node-debug
endif

check-outdate%: ## check-outdated: Check for outdated dependencies
	$(call target_log)
	$(NPM) outdated ||:
	$(PIPENV) update --outdated ||:

chec%: check-python check-node check-outdated ## check: Run all test and output outdated dependencies
	$(call target_log)

#
# Building
#
build-clien%: clean-client ## build-client: Build node client files
	$(call target_log)
	WEBPACK_ENV=browser NODE_ENV=production webpack

build-serve%: clean-server ## build-server: Build node server files
	$(call target_log)
	WEBPACK_ENV=server NODE_ENV=production webpack

buil%: install build-server build-client ## build: Build node files
	$(call target_log)

#
# Serving
#
serve-pytho%: ## serve-python: Run python server
	$(call target_log)
	flask run --with-threads -h $(HOST) -p $(API_PORT)

serve-nod%: ## serve-node: Run build node server
	$(call target_log)
	NODE_ENV=production node dist/server.js

serve-node-serve%: ## serve-node-server: Run node server
	$(call target_log)
	WEBPACK_ENV=server NODE_ENV=development webpack

serve-node-clien%: ## serve-node-client: Run node development files
	$(call target_log)
	WEBPACK_ENV=browser NODE_ENV=development webpack-dev-server

serv%: clean install ## serve: Run all servers in development
	$(call target_log)
	$(MAKE) P="serve-node-client serve-node-server serve-python" make-p

ru%: install ## run: Run built production servers
	$(call target_log)
	FLASK_DEBUG=0 MOCK_NGINX=y $(MAKE) P="serve-python serve-node" make-p
