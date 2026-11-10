IMAGE_NAME := psyb0t/safe-transmission
DEV_TAG    := dev

# Every tool runs from a pinned image, so the host needs only Docker and Make.
SHELLCHECK_IMAGE := koalaman/shellcheck:v0.11.0@sha256:bb596a0d169b85ddd81d8b6d3a2ff6d5baf5fca10b97f575ebc647c3dff62b3d
SHFMT_IMAGE      := mvdan/shfmt:v3.14.1@sha256:8c06884a35683d8763fba6c0d9484d11a61a96da65f8d497d6f625825a6043f2
HADOLINT_IMAGE   := hadolint/hadolint:v2.15.1@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d
# GitHub Pages' own Jekyll build image, so the local site matches the live one.
JEKYLL_IMAGE     := ghcr.io/actions/jekyll-build-pages:v1.0.13@sha256:6791ebfd912185ed59bfb5fb102664fa872496b79f87ff8b9cfba292a7345041
DOCS_SITE        := .testing/docs-site

SHELL_SCRIPTS := run.sh tests/test.sh
RUN_AS_ME     := --user $$(id -u):$$(id -g)

.PHONY: help build lint format test docs clean

help: ## Show the documented targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-8s\033[0m %s\n", $$1, $$2}'

build: ## Build the image as psyb0t/safe-transmission:dev
	docker build -t $(IMAGE_NAME):$(DEV_TAG) .

lint: ## shellcheck + shfmt on the scripts, hadolint on the Dockerfile
	docker run --rm -v "$(CURDIR)":/mnt:ro -w /mnt $(SHELLCHECK_IMAGE) $(SHELL_SCRIPTS)
	docker run --rm -v "$(CURDIR)":/mnt:ro -w /mnt $(SHFMT_IMAGE) -d -i 4 -ci $(SHELL_SCRIPTS)
	docker run --rm -i $(HADOLINT_IMAGE) hadolint - < Dockerfile

format: ## Rewrite the scripts with shfmt
	docker run --rm $(RUN_AS_ME) -v "$(CURDIR)":/mnt -w /mnt $(SHFMT_IMAGE) -w -i 4 -ci $(SHELL_SCRIPTS)

test: build ## Build the image and run the container smoke tests (no VPN, no credentials)
	IMAGE=$(IMAGE_NAME):$(DEV_TAG) bash tests/test.sh

docs: ## Build the documentation site into .testing/docs-site with GitHub Pages' Jekyll image
	@mkdir -p "$(DOCS_SITE)"
	docker run --rm \
		$(RUN_AS_ME) \
		-e HOME=/tmp \
		-e GITHUB_WORKSPACE=/work \
		-e GITHUB_REPOSITORY=psyb0t/safe-transmission \
		-e INPUT_SOURCE=docs \
		-e INPUT_DESTINATION="$(DOCS_SITE)" \
		-e INPUT_VERBOSE=false \
		-v "$(CURDIR):/work" \
		$(JEKYLL_IMAGE)

clean: ## Remove the dev image and .testing/
	docker rmi $(IMAGE_NAME):$(DEV_TAG) 2>/dev/null || true # an absent image is fine
	rm -rf .testing
