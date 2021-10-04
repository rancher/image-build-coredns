ARG UBI_IMAGE=registry.access.redhat.com/ubi7/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.16.7b7
ARG TAG="v1.8.3"
ARG ARCH="amd64"
FROM ${UBI_IMAGE} as ubi
FROM ${GO_IMAGE} as base-builder
# setup required packages
RUN set -x \
 && apk --no-cache add \
    file \
    gcc \
    git \
    make

# setup the coredns build
FROM base-builder as coredns-builder
ARG SRC=github.com/coredns/coredns
ARG PKG=github.com/coredns/coredns
ARG TAG
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

# setup the autoscaler build
FROM base-builder as autoscaler-builder
ARG SRC=github.com/kubernetes-sigs/cluster-proportional-autoscaler
ARG PKG=github.com/kubernetes-sigs/cluster-proportional-autoscaler
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
ARG TAG
ARG ARCH
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN GOARCH=${ARCH} GO_LDFLAGS="-linkmode=external -X ${PKG}/pkg/version.VERSION=${TAG}" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o . ./...
RUN go-assert-static.sh cluster-proportional-autoscaler
RUN go-assert-boring.sh cluster-proportional-autoscaler
RUN install -s cluster-proportional-autoscaler /usr/local/bin

FROM ubi as coredns
RUN microdnf update -y && \
    rm -rf /var/cache/yum
COPY --from=coredns-builder /usr/local/bin/coredns /coredns
ENTRYPOINT ["/coredns"]

FROM ubi as autoscaler
RUN microdnf update -y && \
    rm -rf /var/cache/yum
COPY --from=autoscaler-builder /usr/local/bin/cluster-proportional-autoscaler /cluster-proportional-autoscaler
ENTRYPOINT ["/cluster-proportional-autoscaler"]
