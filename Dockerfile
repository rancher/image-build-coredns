ARG UBI_IMAGE=registry.access.redhat.com/ubi7/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.15.2b5
FROM ${UBI_IMAGE} as ubi
FROM ${GO_IMAGE} as builder
# setup required packages
RUN set -x \
 && apk --no-cache add \
    file \
    gcc \
    git \
    make
# setup containerd build
ARG TAG="v1.6.9"
RUN git clone --depth=1 https://github.com/coredns/coredns.git $GOPATH/src/github.com/coredns/coredns
WORKDIR $GOPATH/src/github.com/coredns/coredns
RUN git fetch --all --tags --prune
RUN git checkout tags/${TAG} -b ${TAG}
# build statically linked executables
RUN echo 'GO_BUILD_FLAGS=" \
        -gcflags=-trimpath=/go/src \
        -v"' \
    >> ./go-build-static
RUN echo 'GO_LDFLAGS=" \
         -X github.com/coredns/coredns/coremain.GitCommit=$(git rev-parse --short HEAD) \
         -linkmode=external -extldflags \"-static -Wl,--fatal-warnings\""' \
    >> ./go-build-static
RUN echo 'go build ${GO_BUILD_FLAGS} -ldflags "${GO_LDFLAGS}" "${@}"' \
    >> ./go-build-static
RUN sh -ex ./go-build-static -o bin/coredns .
# assert statically linked executables
RUN echo '[ -e $1 ] && (file $1 | grep -E "executable, x86-64, .*, statically linked")' >> ./assert-static
RUN sh -ex ./assert-static bin/coredns
# assert goboring symbols
RUN echo '[ -e $1 ] && (go tool nm $1 | grep Cfunc__goboring > .boring; if [ $(wc -l <.boring) -eq 0 ]; then exit 1; fi)' \
    >> ./assert-boring
RUN sh -ex ./assert-boring bin/coredns
# install (with strip) to /usr/local/bin
RUN install -s bin/coredns /usr/local/bin

FROM ubi
RUN microdnf update -y && \
    rm -rf /var/cache/yum
COPY --from=builder /usr/local/bin/coredns /usr/local/bin/
ENTRYPOINT ["coredns"]
