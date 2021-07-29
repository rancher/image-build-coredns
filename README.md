# rancher/hardened-coredns

## Build coredns

```sh
TAG=v1.8.3 make image-build-coredns
```

## Build autoscaler

```sh
TAG=v1.8.3 make image-build-autoscaler
```

## Build dns nodechar

```sh
NODECACHE_TAG=1.19.1 make image-build-dnsnodecache
```
