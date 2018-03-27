# Version 1.0
# This Makefile is based on the ideas from https://mattandre.ws/2016/05/makefile-inheritance/
# It should be used with the script present in exemple.Makefile
# Use `-super` suffix to call for parent tasks
# NB: Targets that match less specifically must have dependencies otherwise the more specific ones are ignored

SHELL := /bin/bash


#
# Functions
#
define target_log
	@echo -e "\n\e[1;35m🞋  \e[1;37m$(@:$*=)\e[1;31m$* \e[1;36m$(shell seq -s"➘" $$((MAKELEVEL + 1)) | tr -d '[:digit:]')\e[0m\n"
endef

define error_log
	@echo -e "\n    \e[1;35m⚠  \e[1;31mERROR: \e[0;35m$1\e[0m\n"
endef

#
# Utilities
#
hel%: ## help: Show this help message.
	$(call target_log)
	@echo -e "usage: make [target] ...\n\ntargets:\n	"
	@grep -Eh '^.+:\ .*##\ .+' $(MAKEFILE_LIST) | cut -d '#' -f '3-' | sed -e 's/^\(.*\):\(.*\)/\o033[1;35m\ \1\o033[0;37m:\2\o033[0m/' | column -t -s ':'

make-p: ## make-p: Launch all ${P} targets in parallel and exit as soon as one exits.
	$(call target_log)
	set -m; (for p in $(P); do ($(MAKE) $$p || kill 0)& done; wait)
.PHONY: make-p

en%: ## env: Run ${RUN} with Makefile environment
	$(call target_log)
	$(RUN)

al%: install build ## all: Default target, install then build
	$(call target_log)
.DEFAULT_GOAL := all

#
# Environment checking
#
fix-node-instal%: ## fix-node-install: Various fixes for node (including node-sass rebuild)
	$(call target_log)
ifeq (, $(wildcard $(NODE_MODULES)/node-sass/vendor/))
	npm rebuild node-sass
endif

check-node-binar%: ## check-node-binary: Ensure yarn is installed or throw error
	$(call target_log)
ifeq (, $(NPM))
	$(call error_log, You must have yarn installed)
	exit 4
endif

check-python-binar%: ## check-python-binary: Ensure pipenv is installed or throw error
	$(call target_log)
ifeq (, $(PIPENV))
	$(call error_log, You must have pipenv installed)
	exit 5
endif

check-python-enviro%: ## check-python-environ: Create python env if empty
	$(call target_log)
ifeq (, $(wildcard $(PWD)/.venv))
	@echo "Python virtual environment not found. Creating with $(PYTHON_VERSION)..."
	$(PIPENV) --python $(PYTHON_VERSION)
endif

check-node-enviro%: ## env-check: Check for node installation
	$(call target_log)
ifeq (, $(wildcard $(NODE_MODULES)))
	$(call error_log, Please run make install before serving)
	exit 4
endif

#
# Installing
#
install-node-pro%: check-node-binary ## install-node-prod: Install node dependencies for production
	$(call target_log)
	$(NPM) install --prod
	$(MAKE) fix-node-install

install-python-pro%: check-python-binary check-python-environ ## install-python-prod: Install python dependencies for production
	$(call target_log)
	$(PIPENV) install --deploy

install-pro%: install-node-prod install-python-prod ## install-prod: Install project dependencies for production
	$(call target_log)

install-nod%: check-node-binary ## install-node: Install node dependencies for development
	$(call target_log)
	$(NPM) install
	$(MAKE) fix-node-install

install-pytho%: check-python-binary check-python-environ ## install-python: Install python dependencies for development
	$(call target_log)
	$(PIPENV) install --dev

install-d%: ## install-db: Install database if any
	$(call target_log)

instal%: install-node install-python ## install: Install project dependencies for development
	$(call target_log)

full-instal%: clean-install install ## full-install: Clean everything and install again
	$(call target_log)

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
ifeq (, $(wildcard $(PWD)/Pipfile.lock))
	$(call error_log, Missing Pipfile.lock file)
	exit 5
endif
	$(PIPENV) run py.test --flake8 --isort -m "flake8 or isort" lib --ignore=lib/frontend/static

lint-nod%: ## lint-node: Lint node source
	$(call target_log)
ifeq (, $(wildcard $(PWD)/yarn.lock))
	$(call error_log, Missing yarn.lock file)
	exit 4
endif
	$(NPM) run lint

lin%: lint-python lint-node ## lint: Lint all source
	$(call target_log)

fix-pytho%: ## fix-python: Fix python source format
	$(call target_log)
	$(PIPENV) run yapf -vv -p -i lib/**/*.py

fix-nod%: ## fix-node: Fix node source format
	$(call target_log)
	$(NPM) run fix

fi%: fix-python fix-node ## fix: Fix all source format
	$(call target_log)

#
# Testing
#
check-pytho%: ## check-python: Run python tests
	$(call target_log)
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) $(PIPENV) run py.test lib $(PYTEST_ARGS)

check-nod%: ## check-node: Run node tests
	$(call target_log)
	$(NPM) run test

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
	$(NPM) run build-client

build-serve%: clean-server ## build-server: Build node server files
	$(call target_log)
	$(NPM) run build-server

buil%: build-server build-client ## build: Build node files
	$(call target_log)

#
# Serving
#
serve-pytho%: ## serve-python: Run python server
	$(call target_log)
	$(PIPENV) run flask run --with-threads -h $(HOST) -p $(API_PORT)

serve-nod%: ## serve-node: Run build node server
	$(call target_log)
	$(NPM) run serve

serve-node-serve%: ## serve-node-server: Run node server
	$(call target_log)
	$(NPM) run serve-server

serve-node-clien%: ## serve-node-client: Run node development files
	$(call target_log)
	$(NPM) run serve-client

serv%: check-node-environ clean ## serve: Run all servers in development
	$(call target_log)
	$(MAKE) P="serve-node-client serve-node-server serve-python" make-p

ru%: ## run: Run built production servers
	$(call target_log)
	FLASK_DEBUG=0 MOCK_NGINX=y $(MAKE) P="serve-python serve-node" make-p
