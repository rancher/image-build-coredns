SEVERITIES = HIGH,CRITICAL

.PHONY: all
all:
	docker build --build-arg TAG=$(TAG) -t ranchertest/coredns:$(TAG) .

.PHONY: image-push
image-push:
	docker push ranchertest/coredns:$(TAG) >> /dev/null

.PHONY: scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed ranchertest/coredns:$(TAG)

.PHONY: image-manifest
image-manifest:
	docker image inspect ranchertest/coredns:$(TAG)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create fips-image-build-flannel:$(TAG) \
		$(shell docker image inspect ranchertest/coredns:$(TAG) | jq -r \'.[] | .RepoDigests[0]\')
