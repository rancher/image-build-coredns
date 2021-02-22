ARG UBI_IMAGE=registry.access.redhat.com/ubi7/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.15.8b5
FROM ${UBI_IMAGE} as ubi
FROM ${GO_IMAGE} as builder
# setup required packages
RUN set -x \
 && apk --no-cache add \
    file \
    gcc \
    git \
    make
# setup the build
ARG SRC=github.com/coredns/coredns
ARG PKG=github.com/coredns/coredns
ARG TAG="v1.6.9"
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN GO_LDFLAGS="-linkmode=external -X ${PKG}/coremain.GitCommit=$(git rev-parse --short HEAD)" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o bin/coredns .
RUN go-assert-static.sh bin/*
RUN go-assert-boring.sh bin/*
RUN install -s bin/* /usr/local/bin
RUN coredns --version

FROM ubi
RUN microdnf update -y && \
    rm -rf /var/cache/yum
COPY --from=builder /usr/local/bin/coredns /coredns
ENTRYPOINT ["/coredns"]
