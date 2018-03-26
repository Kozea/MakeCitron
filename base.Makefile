SHELL := /bin/bash

define target_log
	@echo -e "\n  \e[1;35m🞋  \e[1;37m$(@:$*=)\e[1;31m$*\e[0m\n"
endef

hel%: ## help: Show this help message.
	$(call target_log)
	@echo "usage: make [target] ..."
	@echo ""
	@echo "targets:"
	@grep -Eh '^.+:\ ##\ .+' ${MAKEFILE_LIST} | cut -d ' ' -f '3-' | column -t -s ':'

al%: install build ## all: Default target: install then build
	$(call target_log)
.DEFAULT_GOAL := all

make-p: ## make-p: Launch all ${P} targets in parallel and exit as soon as one exits.
	$(call target_log)
	set -m; (for p in $(P); do ($(MAKE) $$p || kill 0)& done; wait)
.PHONY: make-p

en%: ## env: Run ${RUN} with Makefile environment
	$(call target_log)
	$(RUN)

fix-node-instal%: ## fix-node-install: Various fix for node (including node-sass rebuild)
	$(call target_log)
	@test -d $(NODE_MODULES)/node-sass/vendor/ || npm rebuild node-sass

check-node-binar%: ## check-node-binary: TODO
	$(call target_log)
ifeq (, $(NPM))
	@echo 'You must have yarn installed'
	exit 4
endif

check-python-binar%: ## check-python-binary: TODO
	$(call target_log)
ifeq (, $(PIPENV))
	@echo 'You must have pipenv installed'
	exit 4
endif

check-python-enviro%: ## check-python-environ: TODO
	$(call target_log)
	@test -d $(PWD)/.venv || (echo "Python virtual environment not found. Creating with $(PYTHON_VERSION)..." && $(PIPENV) --python $(PYTHON_VERSION))

install-node-pro%: check-node-binary ## install-node-prod: TODO
	$(call target_log)
	$(NPM) install --prod
	$(MAKE) fix-node-install

install-python-pro%: check-python-binary check-python-environ ## install-python-prod: TODO
	$(call target_log)
	$(PIPENV) install --deploy

install-pro%: install-node-prod install-python-prod ## install-prod: TODO
	$(call target_log)

install-nod%: check-node-binary ## install-node: TODO
	$(call target_log)
	@$(NPM) install
	@$(MAKE) fix-node-install

install-pytho%: check-python-binary check-python-environ ## install-python: TODO
	$(call target_log)
	@$(PIPENV) install --dev

install-d%:  ## install-db: TODO
	$(call target_log)

instal%: install-node install-python ## install: TODO
	$(call target_log)

full-instal%: clean-install install ## full-install: TODO
	$(call target_log)

upgrade-pytho%: ## upgrade-python: TODO
	$(call target_log)
	$(PIPENV) update
	$(PIPENV) lock  # Maybe remove this later
	$(PIPENV) install

upgrade-nod%: ## upgrade-node: TODO
	$(call target_log)
	$(NPM) upgrade-interactive --latest

upgrad%: upgrade-python upgrade-node ## upgrade: TODO
	$(call target_log)

clean-clien%: ## clean-client: TODO
	$(call target_log)
	rm -fr $(PWD)/lib/frontend/assets/*

clean-serve%: ## clean-server: TODO
	$(call target_log)
	rm -fr dist

clean-instal%: clean ## clean-install: TODO
	$(call target_log)
	rm -fr $(NODE_MODULES)
	rm -fr $(VENV)
	rm -fr *.egg-info

clea%: clean-client clean-server ## clean: TODO
	$(call target_log)

lint-pytho%: ## lint-python: TODO
	$(call target_log)
	test -s $(PWD)/Pipfile.lock || (echo 'Missing Pipfile.lock file' && exit 5)
	$(PIPENV) run py.test --flake8 --isort -m "flake8 or isort" lib --ignore=lib/frontend/static

lint-nod%: ## lint-node: TODO
	$(call target_log)
	test -s $(PWD)/yarn.lock || (echo 'Missing yarn.lock file' && exit 6)
	$(NPM) run lint

lin%: lint-python lint-node ## lint: TODO
	$(call target_log)

fix-pytho%: ## fix-python: TODO
	$(call target_log)
	$(PIPENV) run yapf -vv -p -i lib/**/*.py

fix-nod%: ## fix-node: TODO
	$(call target_log)
	$(NPM) run fix

fi%: fix-python fix-node ## fix: TODO
	$(call target_log)
	$(NOOP)

check-pytho%: ## check-python: TODO
	$(call target_log)
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) $(PIPENV) run py.test lib $(PYTEST_ARGS)

check-node-debu%: ## check-node-debug: TODO
	$(call target_log)
	$(NPM) run test-debug

check-nod%: ## check-node: TODO
	$(call target_log)
	$(NPM) run test

check-outdate%: ## check-outdated: TODO
	$(call target_log)
	$(NPM) outdated ||:
	$(PIPENV) update --outdated ||:

chec%: check-python check-node check-outdated ## check: TODO
	$(call target_log)

env-chec%: ## env-check: TODO
	$(call target_log)
	@test -d $(NODE_MODULES) || (@echo 'Please run make install before serving.' && exit 1)

build-clien%: clean-client ## build-client: TODO
	$(call target_log)
	$(NPM) run build-client

build-serve%: clean-server ## build-server: TODO
	$(call target_log)
	$(NPM) run build-server

buil%: build-server build-client ## build: TODO
	$(call target_log)

serve-pytho%: ## serve-python: TODO
	$(call target_log)
	$(PIPENV) run flask run --with-threads -h $(HOST) -p $(API_PORT)

serve-nod%: ## serve-node: TODO
	$(call target_log)
	$(NPM) run serve

serve-node-serve%: ## serve-node-server: TODO
	$(call target_log)
	$(NPM) run serve-server

serve-node-clien%: ## serve-node-client: TODO
	$(call target_log)
	$(NPM) run serve-client

serv%: env-check clean ## serve: TODO
	$(call target_log)
	$(MAKE) P="serve-node-client serve-node-server serve-python" make-p

ru%: ## run: TODO
	$(call target_log)
	FLASK_DEBUG=0 MOCK_NGINX=y $(MAKE) P="serve-python serve-node" make-p
