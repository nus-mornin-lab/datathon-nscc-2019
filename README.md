# Dockerfile for [NUS-NUHS-MIT Healthcare AI Datathon 2019](http://www.nus-datathon.com/) setup @ nscc

Build the image using [Buildkit](https://github.com/moby/buildkit) to speed up builds with caching. For more information see [here](https://docs.docker.com/develop/develop-images/build_enhancements) and [here](https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md).

```sh
DOCKER_BUILDKIT=1 docker build . -t <image>
```
or
```sh
DOCKER_BUILDKIT=1 docker build . -t <image> --progress="plain"
```
to see outputs from containers.
