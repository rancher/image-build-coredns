ARG GO_IMAGE=rancher/hardened-build-base:v1.20.7b3
ARG TAG="v1.10.1"
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
ARG TAG
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

# setup the autoscaler build
FROM base-builder as autoscaler-builder
ARG SRC=github.com/kubernetes-sigs/cluster-proportional-autoscaler
ARG PKG=github.com/kubernetes-sigs/cluster-proportional-autoscaler
RUN git clone --depth=1 https://${SRC}.git $GOPATH/src/${PKG}
ARG TAG="1.8.6"
ARG ARCH="amd64"
WORKDIR $GOPATH/src/${PKG}
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
RUN GOARCH=${ARCH} GO_LDFLAGS="-linkmode=external -X ${PKG}/pkg/version.VERSION=${TAG}" \
    go-build-static.sh -gcflags=-trimpath=${GOPATH}/src -o . ./...
RUN go-assert-static.sh cluster-proportional-autoscaler
RUN if [ "${ARCH}" = "amd64" ]; then \
    	go-assert-boring.sh cluster-proportional-autoscaler; \
    fi
RUN install -s cluster-proportional-autoscaler /usr/local/bin

FROM scratch as coredns
COPY --from=coredns-builder /usr/local/bin/coredns /coredns
ENTRYPOINT ["/coredns"]

FROM scratch as autoscaler
COPY --from=autoscaler-builder /usr/local/bin/cluster-proportional-autoscaler /cluster-proportional-autoscaler
ENTRYPOINT ["/cluster-proportional-autoscaler"]
