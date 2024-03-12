MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := image
DOCKER_REGISTRY := public.ecr.aws/d9q4v8a4
IMAGE_NAME := apppack-db-utils

.PHONY: test-mysql
test-mysql:
	cd mysql; docker compose -f docker-compose.test.yml run --rm utils
	cd mysql; docker compose -f docker-compose.test.yml down

.PHONY: test-postgres
test-postgres:
	cd postgres; docker compose -f docker-compose.test.yml run --rm utils
	cd postgres; docker compose -f docker-compose.test.yml down

.PHONY: test
test: test-mysql test-postgres  ## run tests

.PHONY: image
image: ## Make a production docker container build
	cd mysql; docker build --platform linux/amd64 -t $(IMAGE_NAME)-mysql:$(shell git rev-parse HEAD) .
	cd postgres; docker build  --platform linux/amd64 -t $(IMAGE_NAME)-postgres:$(shell git rev-parse HEAD) .

.PHONY: push-image
push-image: image ## Upload a production docker container to the docker registry
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/d9q4v8a4
	docker tag $(IMAGE_NAME)-mysql:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)-mysql
	docker tag $(IMAGE_NAME)-postgres:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)-postgres

	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)-mysql
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(shell git rev-parse HEAD)-postgres
ifeq ($(shell git rev-parse --abbrev-ref HEAD),main)
	docker tag $(IMAGE_NAME)-mysql:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):mysql
	docker tag $(IMAGE_NAME)-mysql:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):aurora-mysql
	docker tag $(IMAGE_NAME)-postgres:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):postgres
	docker tag $(IMAGE_NAME)-postgres:$(shell git rev-parse HEAD) $(DOCKER_REGISTRY)/$(IMAGE_NAME):aurora-postgresql
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):mysql
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):aurora-mysql
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):postgres
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):aurora-postgresql
endif

# This insanity makes it easy to list available commands with a short description
.PHONY: help
help:
	@echo -e "Available make commands:"
	@echo -e ""
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sort | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)"
