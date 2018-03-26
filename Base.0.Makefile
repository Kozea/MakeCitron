SHELL := /bin/bash

hel%: ## help: Show this help message. ## hel?: TODO
	@echo "usage: make [target] ..."
	@echo ""
	@echo "targets:"
	@grep -Eh '^.+:\ ##\ .+' ${MAKEFILE_LIST} | cut -d ' ' -f '3-' | column -t -s ':'
.PHONY: help help-super

al%: install build ## all: Default target: install then build
.PHONY: all all-super

make-p: ## make-p: Launch all ${P} targets in parallel and exit as soon as one exits.
	set -m; (for p in $(P); do ($(MAKE) $$p || kill 0)& done; wait)
.PHONY: make-p make-p-super

en%: ## env: Run ${RUN} with Makefile environment
	$(RUN)
.PHONY: env env-super

fix-node-instal%: ## fix-node-install: Various fix for node (including node-sass rebuild)
	test -d $(NODE_MODULES)/node-sass/vendor/ || npm rebuild node-sass
.PHONY: fix-node-install fix-node-install-super

check-node-binar%: ## check-node-binary: TODO
ifeq (, $(NPM))
	echo 'You must have yarn installed'
	exit 4
endif
.PHONY: check-node-binary check-node-binary-super

check-python-binar%: ## check-python-binary: TODO
ifeq (, $(PIPENV))
	echo 'You must have pipenv installed'
	exit 4
endif
.PHONY: check-python-binary check-python-binary-super

check-python-enviro%: ## check-python-environ: TODO
	test -d $(PWD)/.venv || (echo "Python virtual environment not found. Creating with $(PYTHON_VERSION)..." && $(PIPENV) --python $(PYTHON_VERSION))
.PHONY: check-python-environ check-python-environ-super

install-nod%: check-node-binary ## install-node: TODO
	$(NPM) install
	$(MAKE) fix-node-install
.PHONY: install-node install-node-super

install-node-pro%: check-node-binary ## install-node-prod: TODO
	$(NPM) install --prod
	$(MAKE) fix-node-install
.PHONY: install-node-prod install-node-prod-super

install-pytho%: check-python-binary check-python-environ ## install-python: TODO
	$(PIPENV) install --dev
.PHONY: install-python install-python-super

install-python-pro%: check-python-binary check-python-environ ## install-python-prod: TODO
	$(PIPENV) install --deploy
.PHONY: install-python-prod install-python-prod-super

instal%: install-node install-python ## install: TODO
.PHONY: install install-super

install-pro%: install-node-prod install-python-prod ## install-prod: TODO
.PHONY: install-prod install-prod-super

full-instal%: clean-install install ## full-install: TODO
.PHONY: full-install full-install-super

upgrade-pytho%: ## upgrade-python: TODO
	$(PIPENV) update
	$(PIPENV) lock  # Maybe remove this later
	$(PIPENV) install
.PHONY: upgrade-python upgrade-python-super

upgrade-nod%: ## upgrade-node: TODO
	$(NPM) upgrade-interactive --latest
.PHONY: upgrade-node upgrade-node-super

upgrad%: upgrade-python upgrade-node ## upgrade: TODO
.PHONY: upgrade upgrade-super

clean-clien%: ## clean-client: TODO
	rm -fr $(PWD)/lib/frontend/assets/*
.PHONY: clean-client clean-client-super

clean-serve%: ## clean-server: TODO
	rm -fr dist
.PHONY: clean-server clean-server-super

clea%: clean-client clean-server ## clean: TODO
.PHONY: clean clean-super

clean-instal%: clean ## clean-install: TODO
	rm -fr $(NODE_MODULES)
	rm -fr $(VENV)
	rm -fr *.egg-info
.PHONY: clean-install clean-install-super

lint-pytho%: ## lint-python: TODO
	test -s $(PWD)/Pipfile.lock || (echo 'Missing Pipfile.lock file' && exit 5)
	$(PIPENV) run py.test --flake8 --isort -m "flake8 or isort" lib --ignore=lib/frontend/static
.PHONY: lint-python lint-python-super

lint-nod%: ## lint-node: TODO
	test -s $(PWD)/yarn.lock || (echo 'Missing yarn.lock file' && exit 6)
	$(NPM) run lint
.PHONY: lint-node lint-node-super

lin%: lint-python lint-node ## lint: TODO
.PHONY: lint lint-super

fix-pytho%: ## fix-python: TODO
	$(PIPENV) run yapf -vv -p -i lib/**/*.py
.PHONY: fix-python fix-python-super

fix-nod%: ## fix-node: TODO
	$(NPM) run fix
.PHONY: fix-node fix-node-super

fi%: fix-python fix-node ## fix: TODO
.PHONY: fix fix-super

check-pytho%: ## check-python: TODO
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) $(PIPENV) run py.test lib $(PYTEST_ARGS)
.PHONY: check-python check-python-super

check-node-debu%: ## check-node-debug: TODO
	$(NPM) run test-debug
.PHONY: check-node-debug check-node-debug-super

check-nod%: ## check-node: TODO
	$(NPM) run test
.PHONY: check-node check-node-super

check-outdate%: ## check-outdated: TODO
	$(NPM) outdated ||:
	$(PIPENV) update --outdated ||:
.PHONY: check-outdated check-outdated-super

chec%: check-python check-node check-outdated ## check: TODO
.PHONY: check check-super

env-chec%: ## env-check: TODO
	@test -d $(NODE_MODULES) || (@echo 'Please run make install before serving.' && exit 1)
.PHONY: env-check env-check-super

build-clien%: clean-client ## build-client: TODO
	$(NPM) run build-client
.PHONY: build-client build-client-super

build-serve%: clean-server ## build-server: TODO
	$(NPM) run build-server
.PHONY: build-server build-server-super

buil%: build-server build-client ## build: TODO
.PHONY: build build-super

serve-pytho%: ## serve-python: TODO
	$(PIPENV) run flask run --with-threads -h $(HOST) -p $(API_PORT)
.PHONY: serve-python serve-python-super

serve-nod%: ## serve-node: TODO
	$(NPM) run serve
.PHONY: serve-node serve-node-super

serve-node-serve%: ## serve-node-server: TODO
	$(NPM) run serve-server
.PHONY: serve-node-server serve-node-server-super

serve-node-clien%: ## serve-node-client: TODO
	$(NPM) run serve-client
.PHONY: serve-node-client serve-node-client-super

serv%: env-check clean ## serve: TODO
	$(MAKE) P="serve-node-client serve-node-server serve-python" make-p
.PHONY: serve serve-super

ru%: ## run: TODO
	FLASK_DEBUG=0 MOCK_NGINX=y $(MAKE) P="serve-python serve-node" make-p
.PHONY: run run-super
