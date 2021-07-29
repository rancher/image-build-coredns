SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META=-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG_COREDNS ?= github.com/coredns/coredns
SRC_COREDNS ?= github.com/coredns/coredns
PKG_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler
SRC_AUTOSCALER ?= github.com/kubernetes-sigs/cluster-proportional-autoscaler 
PKG_NODECACHE ?= github.com/kubernetes/dns
SRC_NODECACHE ?= github.com/kubernetes/dns
TAG ?= v1.8.3$(BUILD_META)
NODECACHE_TAG ?=1.19.1$(BUILD_META)
export DOCKER_BUILDKIT?=1

ifneq ($(DRONE_TAG),)
TAG := $(DRONE_TAG)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

ifeq (,$(filter %$(BUILD_META),$(NODECACHE_TAG)))
$(error NODECACHE_TAG needs to end with build metadata: $(BUILD_META))
endif

AUTOSCALER_BUILD_TAG := $(TAG:v%=%)

.PHONY: image-build-coredns
image-build-coredns:
	docker build \
		--pull \
		--build-arg PKG=$(PKG_COREDNS) \
		--build-arg SRC=$(SRC_COREDNS) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
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
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-coredns:$(TAG)

.PHONY: image-build-autoscaler
image-build-autoscaler:
	docker build \
		--pull \
		--build-arg PKG=$(PKG_AUTOSCALER) \
		--build-arg SRC=$(SRC_AUTOSCALER) \
		--build-arg TAG=$(AUTOSCALER_BUILD_TAG:$(BUILD_META)=) \
		--target autoscaler \
		--tag $(ORG)/hardened-cluster-autoscaler:$(TAG) \
		--tag $(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH) \
	.

.PHONY: image-push-autoscaler
image-push-autoscaler:
	docker push $(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH)

.PHONY: image-manifest-autoscaler
image-manifest-autoscaler:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-cluster-autoscaler:$(TAG) \
		$(ORG)/hardened-cluster-autoscaler:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-cluster-autoscaler:$(TAG)

.PHONY: image-scan-autoscaler
image-scan-autoscaler:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-cluster-autoscaler:$(TAG)

.PHONY: image-build-dnsnodecache
image-build-dnsnodecache:
	docker build \
		--pull \
		--build-arg PKG=$(PKG_NODECACHE) \
		--build-arg SRC=$(SRC_NODECACHE) \
		--build-arg TAG=$(NODECACHE_TAG:$(BUILD_META)=) \
		--target dnsNodeCache \
		--tag $(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG) \
		--tag $(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG)-$(ARCH) \
	.

.PHONY: image-push-dnsnodecache
image-push-dnsnodecache:
	docker push $(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG)-$(ARCH)

.PHONY: image-manifest-dnsnodecache
image-manifest-dnsnodecache:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG) \
		$(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG)

.PHONY: image-scan-dnsnodecache
image-scan-dnsnodecache:
	trivy --severity $(SEVERITIESdnsNodeCache) --no-progress --ignore-unfixed $(ORG)/hardened-dns-node-cache:$(NODECACHE_TAG)
