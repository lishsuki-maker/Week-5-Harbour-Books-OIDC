SHELL := /bin/bash

lint:
	docker run --rm -i hadolint/hadolint < Dockerfile || true

build: lint
	docker build -t $(DOCKER_IMAGE_NAME):$(TAG) .

run:
	docker compose up -d --wait --wait-timeout 60

push:
	docker push "$(DOCKER_IMAGE_NAME):$(TAG)"
