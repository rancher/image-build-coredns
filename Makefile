SEVERITIES = HIGH,CRITICAL

UNAME_M = $(shell uname -m)
ARCH=
ifeq ($(UNAME_M), x86_64)
	ARCH=amd64
else ifeq ($(UNAME_M), aarch64)
	ARCH=arm64
else 
	ARCH=$(UNAME_M)
endif

BUILD_META=-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG_COREDNS ?= github.com/coredns/coredns
SRC_COREDNS ?= github.com/coredns/coredns
PKG_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler
SRC_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler 
TAG ?= v1.11.1$(BUILD_META)
export DOCKER_BUILDKIT?=1

ifneq ($(DRONE_TAG),)
	TAG := $(DRONE_TAG)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
	$(error TAG needs to end with build metadata: $(BUILD_META))
endif

AUTOSCALER_BUILD_TAG := 1.8.10
AUTOSCALER_TAG := v$(AUTOSCALER_BUILD_TAG)$(BUILD_META)

.PHONY: image-build-coredns
image-build-coredns:
	docker build \
		--pull \
		--build-arg PKG=$(PKG_COREDNS) \
		--build-arg SRC=$(SRC_COREDNS) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--build-arg ARCH=$(ARCH) \
		--target coredns \
		--tag $(ORG)/hardened-coredns:$(TAG) \
		--tag $(ORG)/hardened-coredns:$(TAG)-$(ARCH) \
	.

.PHONY: image-push-coredns
image-push-coredns:
	docker push $(ORG)/hardened-coredns:$(TAG)-$(ARCH)

.PHONY: image-manifest-coredns
image-manifest-coredns:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-coredns:$(TAG) \
		$(ORG)/hardened-coredns:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-coredns:$(TAG)

.PHONY: image-scan-coredns
image-scan-coredns:
	trivy image --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-coredns:$(TAG)

.PHONY: image-build-autoscaler
image-build-autoscaler:
	docker build \
		--pull \
		--build-arg PKG=$(PKG_AUTOSCALER) \
		--build-arg SRC=$(SRC_AUTOSCALER) \
		--build-arg TAG=$(AUTOSCALER_BUILD_TAG) \
		--build-arg ARCH=$(ARCH) \
		--target autoscaler \
		--tag $(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG) \
		--tag $(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG)-$(ARCH) \
	.

.PHONY: image-push-autoscaler
image-push-autoscaler:
	docker push $(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG)-$(ARCH)

.PHONY: image-manifest-autoscaler
image-manifest-autoscaler:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG) \
		$(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG)

.PHONY: image-scan-autoscaler
image-scan-autoscaler:
	trivy image --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-cluster-autoscaler:$(AUTOSCALER_TAG)

