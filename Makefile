SEVERITIES = HIGH,CRITICAL

ifneq ($(DRONE_TAG),)
TAG := $(DRONE_TAG)
else
TAG ?= v1.6.9
endif

.PHONY: image-build
image-build:
	docker build --build-arg TAG=$(TAG) -t rancher/hardened-coredns:$(TAG) .

.PHONY: image-push
image-push:
	docker push rancher/hardened-coredns:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create rancher/hardened-coredns:$(TAG) rancher/hardened-coredns:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push rancher/hardened-coredns:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed rancher/hardened-coredns:$(TAG)
