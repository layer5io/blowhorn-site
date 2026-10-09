# Copyright Layer5, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include .github/build/Makefile.show-help.mk

#-----------------------------------------------------------------------------
# blowhorn.ai is a Hugo site with Docsy as a Hugo module, built like
# layer5io/docs. You need Go (Hugo modules), Node.js and npm (the pinned
# hugo-extended and postcss come from package.json), Python 3 (checks) and make.
#
# MAIN TARGETS (the shared target contract of layer5io/docs: same names,
# prerequisites and npm scripts; see https://github.com/layer5io/docs/blob/master/Makefile)
#
#   setup              Install site dependencies (npm install).
#   build              Build locally with draft, future, and expired content.
#   build-preview      Build for a deploy preview (uses BASE_URL or DEPLOY_PRIME_URL).
#   build-production   Build for production. Pass BASE_URL=... to set the base URL.
#   site               Serve locally with live reload.
#   serve              Serve locally once, file watcher off (no live reload).
#   check-links        Check every local link, image and font in the built site.
#   check-deps         Verify required commands and local dependencies.
#   check-go           Verify Go is installed (required by Hugo Modules).
#
# BLOWHORN TARGETS
#
#   site-check         Production build, then html-validate, check-links, the
#                      third-party host check and the URL and anchor contract.
#   workflow-check     actionlint on this repository's workflows.
#   test-scripts       Unit tests for the check scripts in .github/scripts/.
#   check              site-check, test-scripts and workflow-check: everything CI runs.
#   dmg-check          Sanity-check a disk image before publishing it.
#   clean              Remove the build output, Hugo's cache and downloaded tools.
#-----------------------------------------------------------------------------
# Fixed: the npm build and link-check scripts and site.yml all use public/.
override BUILD_DIR := public
HTML_VALIDATE_VERSION ?= 9.5.5
ACTIONLINT_VERSION ?= 1.7.7
BIN_DIR ?= .bin
# actionlint from PATH when installed; otherwise a pinned copy is downloaded into $(BIN_DIR).
ACTIONLINT ?= $(shell command -v actionlint 2>/dev/null)
# Workflows owned by this repo. Template workflows (labeler and friends) are left as-is.
WORKFLOWS ?= .github/workflows/site.yml .github/workflows/publish-dmg.yml

# ---------------------------------------------------------------------------
# MAINTENANCE
# ---------------------------------------------------------------------------

## Verify required commands and local dependencies are present.
check-deps:
	@echo "Checking if 'npm' is installed and 'hugo' is available via node_modules (installed by 'make setup')..."
	@command -v npm > /dev/null || { echo "Error: 'npm' not found. Please install Node.js and npm."; exit 1; }
	@test -x node_modules/.bin/hugo || { echo "Error: Hugo binary not found in node_modules. Please run 'make setup' first."; exit 1; }
	@echo "Dependencies check passed."

## Verify Go is installed locally.
check-go:
	@echo "Checking if Go is installed..."
	@command -v go > /dev/null || { echo "Go is not installed. Please install it before proceeding."; exit 1; }
	@echo "Go is installed."

## Check every local link, image, font and srcset reference in a production build.
check-links: build-production
	npm run check:links

# ---------------------------------------------------------------------------
# LOCAL BUILDS
# ---------------------------------------------------------------------------

## Install blowhorn.ai dependencies (the pinned Hugo extended and postcss) on your local machine.
setup:
	npm install

## Build the site locally with draft and future content enabled.
build: check-go check-deps
	npm run build

## Build the site for a deploy preview.
build-preview: check-go check-deps
	npm run build:preview

## Build blowhorn.ai for production with optional base URL (what CI deploys).
build-production: check-go check-deps
	set -e; \
	if [ -n "$(BASE_URL)" ]; then \
		base_url="$(BASE_URL)"; \
		base_url="$${base_url%/}/"; \
		npm run build:production -- --baseURL "$$base_url"; \
	else \
		npm run build:production; \
	fi

## Build and run the site locally with live reload at http://localhost:1313 (draft and future content enabled).
site: check-go check-deps
	npm run site

## Build and serve the site once with the file-watcher off (no live reload).
serve: check-go check-deps
	npm run serve

# ---------------------------------------------------------------------------
# CHECKS
# ---------------------------------------------------------------------------

## Build for production, then validate the HTML, check local links, fail on any third-party request and on a lost URL or anchor.
site-check: build-production
	npx --yes html-validate@$(HTML_VALIDATE_VERSION) "$(BUILD_DIR)/**/*.html"
	npm run check:links
	python3 .github/scripts/check-third-party.py $(BUILD_DIR)
	python3 .github/scripts/check-site-contract.py $(BUILD_DIR)

## Run the unit tests for the check scripts in .github/scripts/.
test-scripts:
	python3 -m unittest discover -s .github/scripts -p 'test_*.py'

## Lint this repo's GitHub Actions workflows with actionlint.
workflow-check:
ifeq ($(ACTIONLINT),)
	@test -x $(BIN_DIR)/actionlint || (mkdir -p $(BIN_DIR) && cd $(BIN_DIR) && \
		curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/v$(ACTIONLINT_VERSION)/scripts/download-actionlint.bash | \
		bash -s -- $(ACTIONLINT_VERSION) .)
	$(BIN_DIR)/actionlint -color $(WORKFLOWS)
else
	$(ACTIONLINT) -color $(WORKFLOWS)
endif

## Run every check CI runs: site-check, test-scripts and workflow-check.
check: site-check test-scripts workflow-check

## Sanity-check a local disk image before publishing: make dmg-check DMG=path/to/Blowhorn.dmg
dmg-check:
	@test -n "$(DMG)" || (echo "usage: make dmg-check DMG=path/to/file.dmg"; exit 1)
	.github/scripts/check-dmg.sh "$(DMG)"

## Remove the build output, Hugo's resource cache and downloaded tools.
clean:
	npm run clean
	rm -rf $(BUILD_DIR) $(BIN_DIR)

.PHONY: \
	setup \
	build \
	build-preview \
	build-production \
	site \
	serve \
	check-links \
	check-deps \
	check-go \
	site-check \
	test-scripts \
	workflow-check \
	check \
	dmg-check \
	clean
