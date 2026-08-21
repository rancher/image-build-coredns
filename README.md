# rancher/hardened-coredns

This repo builds hardened, statically-linked Go binaries from
[coredns/coredns](https://github.com/coredns/coredns) and packages them in a minimal
SLE BCI ([bci-nano](https://registry.suse.com/repositories/bci-bci-nano-16-0)) based image.

The resulting image is published to [rancher/hardened-coredns](https://hub.docker.com/r/rancher/hardened-coredns).

Binaries are compiled against [`rancher/hardened-build-base`](https://github.com/rancher/image-build-base),
which provides the latest supported Go toolchain (FIPS/BoringCrypto-enabled on amd64).

## Build

```sh
TAG=v1.14.7 make
```
