SEVERITIES = HIGH,CRITICAL

.PHONY: all
all:
	docker build --build-arg TAG=$(TAG) -t rancher/coredns:$(TAG) .

.PHONY: image-push
image-push:
	docker push rancher/coredns:$(TAG) >> /dev/null

.PHONY: scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --skip-update --ignore-unfixed rancher/coredns:$(TAG)

.PHONY: image-manifest
image-manifest:
	docker image inspect rancher/coredns:$(TAG)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create rancher/coredns:$(TAG) \
		$(shell docker image inspect rancher/coredns:$(TAG) | jq -r '.[] | .RepoDigests[0]')
