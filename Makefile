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
# Blowhorn site and distribution. The site is hand-written HTML, CSS and JS
# with no build step beyond copying, so nothing here needs Go, Hugo or an
# npm install: `make`, Python 3 and Node.js (for `npx`) are enough.
#-----------------------------------------------------------------------------
SITE_DIR ?= site
SITE_OUT ?= _site
SITE_PORT ?= 8080
HTML_VALIDATE_VERSION ?= 9.5.5
ACTIONLINT_VERSION ?= 1.7.7
BIN_DIR ?= .bin
# actionlint from PATH when installed; otherwise a pinned copy is downloaded into $(BIN_DIR).
ACTIONLINT ?= $(shell command -v actionlint 2>/dev/null)
# Workflows owned by this repo. Template workflows (labeler and friends) are left as-is.
WORKFLOWS ?= .github/workflows/site.yml .github/workflows/publish-dmg.yml

## Build the static Blowhorn site into _site/ (the GitHub Pages artifact).
site-build:
	rm -rf $(SITE_OUT)
	mkdir -p $(SITE_OUT)
	cp -R $(SITE_DIR)/. $(SITE_OUT)/
	touch $(SITE_OUT)/.nojekyll
	@echo "Built $(SITE_OUT)/"

## Validate site HTML (html-validate via npx) and check every local link, image and font reference.
site-check:
	npx --yes html-validate@$(HTML_VALIDATE_VERSION) "$(SITE_DIR)/**/*.html"
	python3 .github/scripts/check-site-links.py $(SITE_DIR)

## Build the site and serve it at http://localhost:8080 (SITE_PORT to change).
site-serve: site-build
	python3 -m http.server $(SITE_PORT) --directory $(SITE_OUT)

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

## Run every check CI runs: site-check and workflow-check.
check: site-check workflow-check

## Sanity-check a local disk image before publishing: make dmg-check DMG=path/to/Blowhorn.dmg
dmg-check:
	@test -n "$(DMG)" || (echo "usage: make dmg-check DMG=path/to/file.dmg"; exit 1)
	.github/scripts/check-dmg.sh "$(DMG)"

## Remove the build output and downloaded tools.
clean:
	rm -rf $(SITE_OUT) $(BIN_DIR)

.PHONY: site-build site-check site-serve workflow-check check dmg-check clean
