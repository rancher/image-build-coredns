SEVERITIES = HIGH,CRITICAL

.PHONY: all
all:
	docker build --build-arg TAG=$(TAG) -t ranchertest/coredns:$(TAG) .

.PHONY: image-push
image-push:
	docker push ranchertest/coredns:$(TAG) >> /dev/null

.PHONY: scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --skip-update --ignore-unfixed ranchertest/coredns:$(TAG)

.PHONY: image-manifest
image-manifest:
	docker image inspect ranchertest/coredns:$(TAG)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ranchertest/coredns:$(TAG) \
		$(shell docker image inspect ranchertest/coredns:$(TAG) | jq -r '.[] | .RepoDigests[0]')
