ARG GO_IMAGE=rancher/hardened-build-base:v1.20.7b3
ARG TAG=v011
ARG ARCH="amd64"
FROM ${GO_IMAGE} as base-builder
# setup required packages
RUN set -x && \
    apk --no-cache add \
    file \
    gcc \
    git \
    make

# setup the coredns build
FROM base-builder as coredns-builder
ARG SRC=github.com/coredns/coredns
ARG PKG=github.com/coredns/coredns
ARG ARCH
ARG TAG=v011
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN GO_LDFLAGS="-linkmode=external -X ${PKG}/coremain.GitCommit=$(git rev-parse --short HEAD)" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/coredns .
RUN go-assert-static.sh bin/*
RUN if [ "${ARCH}" != "s390x" || "${ARCH}" != "arm64" ]; then \
    	go-assert-boring.sh bin/*; \
    fi

RUN install -s bin/* /usr/local/bin
RUN coredns --version

FROM scratch as coredns
COPY --from=coredns-builder /usr/local/bin/coredns /coredns
ENTRYPOINT ["/coredns"]
