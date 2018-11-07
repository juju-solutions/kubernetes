#!/usr/bin/env bash

set -eux

CNI_VERSION="${CNI_VERSION:-v0.7.1}"
ARCH="${ARCH:-amd64 arm64 s390x}"

temp_dir="$(readlink -f build-cni-resources.tmp)"
rm -rf "$temp_dir"
mkdir "$temp_dir"
(cd "$temp_dir"
  git clone https://github.com/containernetworking/plugins.git cni-plugins \
    --branch "$CNI_VERSION" \
    --depth 1

  # Grab the user id and group id of this current user.
  GROUP_ID=$(id -g)
  USER_ID=$(id -u)

  for arch in $ARCH; do
    echo "Building cni $CNI_VERSION for $arch"
    docker run \
      --rm \
      -e GOOS=linux \
      -e GOARCH="$arch" \
      -v "$temp_dir"/cni-plugins:/cni \
      golang \
      /bin/bash -c "cd /cni && ./build.sh && chown -R ${USER_ID}:${GROUP_ID} /cni"

    (cd cni-plugins/bin
      tar -caf "$temp_dir/cni-$arch-$CNI_VERSION.tar.gz" .
    )
  done
)
mv "$temp_dir"/cni-*.tar.gz .
rm -rf "$temp_dir"
