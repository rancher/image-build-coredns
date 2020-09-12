SEVERITIES = HIGH,CRITICAL

.PHONY: all
all:
	docker build --build-arg TAG=$(TAG) -t rancher/hardened-coredns:$(TAG) .

.PHONY: image-push
image-push:
	docker push rancher/hardened-coredns:$(TAG) >> /dev/null

.PHONY: scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --skip-update --ignore-unfixed rancher/hardened-coredns:$(TAG)

.PHONY: image-manifest
image-manifest:
	docker image inspect rancher/hardened-coredns:$(TAG)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create rancher/hardened-coredns:$(TAG) \
		$(shell docker image inspect rancher/hardened-coredns:$(TAG) | jq -r '.[] | .RepoDigests[0]')
