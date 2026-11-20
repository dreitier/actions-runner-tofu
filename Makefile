IMAGE ?= ghcr.io/dreitier/actions-runner-tofu
TAG ?= local

.PHONY: build test hooks lint

# local image only; releases are published by .github/workflows/release.yml
build:
	docker build -t $(IMAGE):$(TAG) .

test: build
	.github/ci/smoke-test.sh $(IMAGE):$(TAG)

hooks:
	pre-commit install

lint:
	pre-commit run --all-files
