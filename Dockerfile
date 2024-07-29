ARG BCI_IMAGE=registry.suse.com/bci/bci-busybox
ARG GO_IMAGE=rancher/hardened-build-base:v1.21.11b3
ARG ARCH="amd64"

# Image that provides cross compilation tooling.
FROM --platform=$BUILDPLATFORM rancher/mirrored-tonistiigi-xx:1.3.0 as xx

FROM ${BCI_IMAGE} as bci
FROM --platform=$BUILDPLATFORM ${GO_IMAGE} as base-builder
# copy xx scripts to your build stage
COPY --from=xx / /
RUN apk add file make git clang lld
ARG TARGETPLATFORM
# setup required packages
RUN set -x && \
    xx-apk --no-cache add musl-dev gcc lld 

# setup the coredns build
FROM --platform=$BUILDPLATFORM base-builder as coredns-builder
ARG SRC=github.com/coredns/coredns
ARG PKG=github.com/coredns/coredns
ARG ARCH
ARG TAG=v1.11.3
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN go mod download
# cross-compilation setup
ARG TARGETPLATFORM
RUN xx-go --wrap && \
    GO_LDFLAGS="-linkmode=external -X ${PKG}/coremain.GitCommit=$(git rev-parse --short HEAD)" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/coredns .
RUN go-assert-static.sh bin/*
RUN xx-verify --static bin/*
RUN if [ "${ARCH}" != "s390x" || "${ARCH}" != "arm64" ]; then \
    	go-assert-boring.sh bin/*; \
    fi

RUN install bin/* /usr/local/bin
RUN coredns --version

FROM ${GO_IMAGE} as strip_binary
#strip needs to run on TARGETPLATFORM, not BUILDPLATFORM
COPY --from=coredns-builder /usr/local/bin/coredns /coredns
RUN strip /coredns

FROM bci as coredns
COPY --from=strip_binary /coredns /coredns
ENTRYPOINT ["/coredns"]
