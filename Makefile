MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := image
DOCKER_REGISTRY := lincolnloop
IMAGE_NAME := apppack-db-utils

.PHONY: test-postgres
test-postgres:
	cd postgres; docker-compose -f docker-compose.test.yml run --rm utils
	cd postgres; docker-compose -f docker-compose.test.yml down

.PHONY: image
image: ## Make a production docker container build
	docker build -t $(IMAGE_NAME):$(shell git rev-parse HEAD) .

.PHONY: push-image
push-image: image ## Upload a production docker container to the docker registry
	docker tag $(IMAGE_NAME):$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)
ifeq ($(shell git rev-parse --abbrev-ref HEAD),master)
	docker tag $(IMAGE_NAME):$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):latest
endif

# This insanity makes it easy to list available commands with a short description
.PHONY: help
help:
	@echo -e "Available make commands:"
	@echo -e ""
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sort | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
