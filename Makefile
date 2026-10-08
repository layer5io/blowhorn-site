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

## Install docs.layer5.io dependencies on your local machine.
## See https://gohugo.io/categories/installation
setup:
	npm install

## Run docs.layer5.io on your local machine with draft and future content enabled.
site: check-go
	hugo server -D -F
	
## Run docs.layer5.io on your local machine. Alternate method.
site-fast:
	gatsby develop

## Build docs.layer5.io on your local machine.
build:
	hugo

## Empty build cache and run docs.layer5.io on your local machine.
clean: 
	hugo --cleanDestinationDir
	make site

.PHONY: setup build site clean site-fast check-go

check-go:
	@echo "Checking if Go is installed..."
	@command -v go > /dev/null || (echo "Go is not installed. Please install it before proceeding."; exit 1)
	@echo "Go is installed."

docker:
	docker compose watch

#-----------------------------------------------------------------------------
# Blowhorn site and distribution (no Go, Hugo, or npm install required)
#-----------------------------------------------------------------------------
SITE_DIR ?= site
SITE_OUT ?= _site
SITE_PORT ?= 8080
HTML_VALIDATE_VERSION ?= 9.5.5
ACTIONLINT_VERSION ?= 1.7.7
BIN_DIR ?= .bin
# Workflows owned by this repo. Template workflows (labeler, etc.) are left as-is.
WORKFLOWS ?= $(wildcard .github/workflows/site.yml .github/workflows/publish-dmg.yml ci/workflows/*.yml)

## Build the static Blowhorn site into _site/ (the GitHub Pages artifact).
site-build:
	rm -rf $(SITE_OUT)
	mkdir -p $(SITE_OUT)
	cp -R $(SITE_DIR)/. $(SITE_OUT)/
	touch $(SITE_OUT)/.nojekyll
	@echo "Built $(SITE_OUT)/"

## Validate site HTML (html-validate via npx) and check local links.
site-check:
	npx --yes html-validate@$(HTML_VALIDATE_VERSION) "$(SITE_DIR)/**/*.html"
	python3 .github/scripts/check-site-links.py $(SITE_DIR)

## Serve the built site at http://localhost:8080.
site-serve: site-build
	python3 -m http.server $(SITE_PORT) --directory $(SITE_OUT)

## Lint GitHub Actions workflows with actionlint.
workflow-check:
	@test -x $(BIN_DIR)/actionlint || (mkdir -p $(BIN_DIR) && cd $(BIN_DIR) && \
		curl -fsSL https://raw.githubusercontent.com/rhysd/actionlint/v$(ACTIONLINT_VERSION)/scripts/download-actionlint.bash | \
		bash -s -- $(ACTIONLINT_VERSION) .)
	$(BIN_DIR)/actionlint -color $(WORKFLOWS)

## Sanity-check a local disk image before publishing: make dmg-check DMG=path/to/Blowhorn.dmg
dmg-check:
	@test -n "$(DMG)" || (echo "usage: make dmg-check DMG=path/to/file.dmg"; exit 1)
	.github/scripts/check-dmg.sh "$(DMG)"

.PHONY: site-build site-check site-serve workflow-check dmg-check
