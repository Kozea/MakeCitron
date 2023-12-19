VERSION := 1.4.16

# Use bash
SHELL := bash

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

_PYTHON =
_NODE =
ifndef NODE_ONLY
_PYTHON = 1
endif
ifndef PYTHON_ONLY
_NODE = 1
endif

# Default values
# Could be overridden in `config.Makefile` or environment
## Python env
ifdef _PYTHON
PYTHON ?= python
VENV ?= $(PWD)/.venv
PYTHON_BINDIR ?= $(VENV)/bin
PYTHON_SRCDIR ?= lib
PYTHON_PKG_TOOLS ?= pip pip-tools setuptools wheel
### Commands (from `PYTHON_BINDIR` via `PATH` environment variable)
FLASK ?= flask
PIP ?= pip
PIP_COMPILE ?= pip-compile --generate-hashes
PIP_SYNC ?= pip-sync
PYTEST ?= pytest
RUFF ?= ruff
### Ordered layers of requirements
REQUIREMENTS_LAYERS ?= base dev
### Set PATH to python binaries
export PATH := $(PYTHON_BINDIR):$(PATH)
endif
## Node env
ifdef _NODE
NODE_MODULES ?= $(PWD)/node_modules
NPM ?= $(shell command -v yarn 2> /dev/null)
NODE_BINDIR ?= $(shell $(NPM) bin)
### Commands (from `NODE_BINDIR` via `PATH` environment variable)
JEST ?= jest
# Set PATH to node binaries
export PATH := $(NODE_BINDIR):$(PATH)
endif

WEBPACK ?= webpack

LOG = @echo -e "\n    $(C_BOLD)$(C_PINK)🞋  $(C_WHITE)$(@:$*=)$(C_RED)$* $(C_BLUE)$(shell seq -s"➘" $$((MAKELEVEL + 1)) | tr -d '[:digit:]')$(C_NORMAL)"

check-enviro%: ## check-environ: Environment checking
	$(LOG)
ifdef _PYTHON
ifeq (, $(PIP))
	$(error $(shell echo -e "$(C_BOLD)$(C_PINK)⚠  $(C_RED)ERROR: $(C_NORMAL)$(C_RED)You must have pip installed$(C_NORMAL)"))
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
	@grep -Eh '^.+:\ .*##\ .+' $(MAKEFILE_LIST) \
		| cut -d '#' -f '3-' \
		| sed -e 's/^\(.*\):\(.*\)/$(C_BOLD)$(C_PINK)\ \1$(C_WHITE):\2$(C_NORMAL)/' \
		| sort \
		| column -t -s ':'
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
STAGED_NODE_FILES := $(shell git diff --cached --name-only --diff-filter=ACM "*.js" "*.jsx" 2> /dev/null | tr '\n' ' ')
ifneq ($(STAGED_NODE_FILES),)
PARTIALLY_STAGED_NODE_FILES := $(shell git diff --name-only $(STAGED_NODE_FILES))
ifneq ($(PARTIALLY_STAGED_NODE_FILES),)
PARTIALLY_STAGED_FILES += $(PARTIALLY_STAGED_NODE_FILES)
endif
endif
endif

ifdef _PYTHON
STAGED_PYTHON_FILES := $(shell git diff --cached --name-only --diff-filter=ACM "*.py" 2> /dev/null | tr '\n' ' ')
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
	@$(RUFF) format $(STAGED_PYTHON_FILES)
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

install-python-ven%: ## install-python-venv: Create Python virtual environment
	$(LOG)
	test -d "$(VENV)" || $(PYTHON) -m venv "$(VENV)"
	# `venv` could install outdated `pip` and `setuptools` versions
	# Install `wheel` too (used by `pip` if available when installing packages)
	$(PIP) install --upgrade $(PYTHON_PKG_TOOLS)

install-node-pro%: ## install-node-prod: Install node dependencies for production
	$(LOG)
	$(NPM) install --prod

install-python-pro%: install-python-venv ## install-python-prod: Install python dependencies for production
	$(LOG)
	$(PIP_SYNC) $(patsubst %, requirements/%.txt, $(word 1, $(REQUIREMENTS_LAYERS)))

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

requirements/%.txt: requirements/%.in ## requirements/%.txt: Generate python requirements
	$(PIP_COMPILE) $<

install-pytho%: install-python-venv ## install-python: Install python dependencies for development
	$(LOG)
	$(foreach req, $(REQUIREMENTS_LAYERS), $(MAKE) requirements/$(req).txt;)
	$(PIP_SYNC) $(patsubst %, requirements/%.txt, $(REQUIREMENTS_LAYERS))

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
ifdef PKG
UPGRADE_ARG := --upgrade-package "$(PKG)"
UPGRADE_ARG := $(patsubst %,--upgrade-package %,$(PKG))
else
UPGRADE_ARG := --upgrade
endif
upgrade-pytho%: ## upgrade-python: Upgrade locked python dependencies (or specific ones with PKG="foo bar")
	$(LOG)
	# Upgrade packages not directly managed by pip-tools
	$(PIP) install --upgrade $(PYTHON_PKG_TOOLS)
	$(foreach req, $(REQUIREMENTS_LAYERS), $(PIP_COMPILE) $(UPGRADE_ARG) requirements/$(req).in;)
	$(PIP_SYNC) $(patsubst %, requirements/%.txt, $(REQUIREMENTS_LAYERS))

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
	$(RUFF) check --show-files $(PYTHON_SRCDIR)

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
	isort "$(PYTHON_SRCDIR)"
	black "$(PYTHON_SRCDIR)"

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
	FLASK_CONFIG=$(FLASK_TEST_CONFIG) $(PYTEST) "$(PYTHON_SRCDIR)" $(PYTEST_ARGS)

check-nod%: ## check-node: Run node tests
	$(LOG)
ifeq (,$(DEBUG_NODE))
	$(JEST) --no-cache --coverage
else
	inspect $(JEST) --runInBand --env jest-environment-node-debug
endif

check-outdate%: ## check-outdated: Check for outdated dependencies
	$(LOG)
ifdef _NODE
	$(NPM) outdated ||:
endif
ifdef _PYTHON
	$(PIP) list --outdated ||:
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
	$(FLASK) run --with-threads -h $(HOST) -p $(API_PORT)

serve-nod%: ## serve-node: Run build node server
	$(LOG)
	NODE_ENV=production node dist/server.js

serve-node-serve%: ## serve-node-server: Run node server
	$(LOG)
	WEBPACK_ENV=server NODE_ENV=development $(WEBPACK)

serve-node-clien%: ## serve-node-client: Run node development files
	$(LOG)
	WEBPACK_ENV=browser NODE_ENV=development $(WEBPACK) serve

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

DOCKER ?= docker
DOCKER_COMPOSE ?= docker compose

DEFAULT_APP_CONTAINER ?= app
DEFAULT_CI_CONTAINER ?= ci
DEFAULT_CONTAINER_SHELL ?= bash

export CI_REGISTRY ?= registry.gitlab.com

# Do not use `?=` when variable is set from call `shell` function then exported
# (it could be very slow)
# See https://stackoverflow.com/a/77364656/611407
ifndef CI_PROJECT_NAME
	CI_PROJECT_NAME := $(shell basename -s .git "$(shell git config --get remote.origin.url 2> /dev/null)")
endif
export CI_PROJECT_NAME

export CI_REGISTRY_IMAGE ?= $(CI_REGISTRY)/kozea/$(CI_PROJECT_NAME)

ifndef CI_COMMIT_REF_SLUG
	CI_COMMIT_REF_SLUG := $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null | tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
endif
export CI_COMMIT_REF_SLUG

ifndef CI_COMMIT_SHORT_SHA
	CI_COMMIT_SHORT_SHA := $(shell git describe --dirty --always --abbrev=8 2> /dev/null)
endif
export CI_COMMIT_SHORT_SHA

export CI_DEFAULT_BRANCH ?= master

export REGISTRY_IMAGE ?= ${CI_REGISTRY_IMAGE}/${CI_COMMIT_REF_SLUG}:${CI_COMMIT_SHORT_SHA}
export REGISTRY_IMAGE_LATEST ?= ${CI_REGISTRY_IMAGE}/${CI_COMMIT_REF_SLUG}:latest

# Every CI pipeline must have its own docker-compose namespace to enable parallelism
ifdef CI_JOB_ID
COMPOSE_NAMESPACE := ${CI_PROJECT_NAME}_ci_job_${CI_JOB_ID}
else
COMPOSE_NAMESPACE := ${CI_PROJECT_NAME}
endif

ifndef COMPOSE_PROJECT_NAME
	COMPOSE_PROJECT_NAME := $(shell echo "$(COMPOSE_NAMESPACE)" | tr -dc '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
endif
export COMPOSE_PROJECT_NAME

export COMPOSE_FILE ?= $(CURDIR)/docker-compose.yml

# Enable BuildKit that brings substantial improvements in build process
export DOCKER_BUILDKIT ?= 1
export COMPOSE_DOCKER_CLI_BUILD ?= 1
export BUILDKIT_INLINE_CACHE ?= 1

# UID/GUD of the default user in the container
ifndef CONTAINER_UID
	CONTAINER_UID := $(shell id -u)
endif
export CONTAINER_UID

ifndef CONTAINER_GID
	CONTAINER_GID := $(shell id -g)
endif
export CONTAINER_GID

ifeq (, $(DOCKER))
	$(error $(shell echo -e "$(C_BOLD)$(C_PINK)⚠  $(C_RED)ERROR: $(C_NORMAL)$(C_RED)You must have docker installed$(C_NORMAL)"))
endif

ifeq (, $(DOCKER_COMPOSE))
	$(error $(shell echo -e "$(C_BOLD)$(C_PINK)⚠  $(C_RED)ERROR: $(C_NORMAL)$(C_RED)You must have docker-compose installed$(C_NORMAL)"))
endif

docker-buil%: ## docker-build: Build docker image
	ln -sf $(CURDIR)/.gitignore $(CURDIR)/.dockerignore
	$(DOCKER_COMPOSE) build --pull $(DEFAULT_APP_CONTAINER)

docker-ru%: docker-build ## docker-run: Start containers in foreground
	$(DOCKER_COMPOSE) run --rm --service-ports $(DEFAULT_APP_CONTAINER)

docker-u%: docker-build ## docker-up: Start containers in background
	$(DOCKER_COMPOSE) up -d $(DEFAULT_APP_CONTAINER)

docker-sto%: ## docker-stop: Stop all containers
	$(DOCKER_COMPOSE) stop

docker-restar%: docker-stop docker-start ## docker-restart: Restart all containers

docker-log%: ## docker-logs: Show last logs of the app container
	$(DOCKER_COMPOSE) logs --tail=100 -f $(DEFAULT_APP_CONTAINER)

docker-exe%: ## docker-exec: Execute in interactive shell in the app container.
	$(DOCKER_COMPOSE) exec $(DEFAULT_APP_CONTAINER) "$(DEFAULT_CONTAINER_SHELL)"

docker-statu%: ## docker-status: List all containers
	$(DOCKER_COMPOSE) ps -a

docker-clea%: ## docker-clean: Delete all containers, images and named volumes
	$(DOCKER_COMPOSE) down -v --remove-orphans

docker-releas%: ## docker-release: Push docker image tags to the gitlab registry
	$(DOCKER) tag $(REGISTRY_IMAGE) $(REGISTRY_IMAGE_LATEST)
	$(DOCKER) push $(REGISTRY_IMAGE)
	$(DOCKER) push $(REGISTRY_IMAGE_LATEST)

docker-ci-tes%: docker-build ## docker-ci-test: Run continuous integration tests
	$(DOCKER_COMPOSE) run -T --rm $(DEFAULT_CI_CONTAINER)

docker-ci-lin%: docker-build ## docker-ci-lint: Lint all source
	$(DOCKER_COMPOSE) run -T --rm -e WAIT_POSTGRES=0 -e POPULATE_DB=0 -e MIGRATE_DB=0 --no-deps $(DEFAULT_CI_CONTAINER) make lint


ANSIBLE := ansible
ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_DIR ?= $(CURDIR)/ansible

DEPLOY_PLAYBOOK_FILE ?= $(ANSIBLE_DIR)/playbooks/deploy.yml
UNDEPLOY_PLAYBOOK_FILE ?= $(ANSIBLE_DIR)/playbooks/undeploy.yml

export ANSIBLE_INVENTORY ?= $(ANSIBLE_DIR)/hosts
export ANSIBLE_VAULT_PASSWORD_FILE ?= $(ANSIBLE_DIR)/vault-pass-client

deploy-tes%: ## deploy-test: Run deploy ansible playbook on testing
	$(LOG)
	$(ANSIBLE_PLAYBOOK) $(DEPLOY_PLAYBOOK_FILE) -l testing

undeploy-tes%: ## undeploy-test: Run undeploy ansible playbook on testing
	$(LOG)
	$(ANSIBLE_PLAYBOOK) $(UNDEPLOY_PLAYBOOK_FILE) -l testing

deploy-pro%: ## deploy-prod: Run deploy ansible playbook on prod
	$(LOG)
	$(ANSIBLE_PLAYBOOK) $(DEPLOY_PLAYBOOK_FILE) -l production
