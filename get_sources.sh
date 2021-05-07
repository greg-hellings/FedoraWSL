#!/bin/bash
pkg="$(readlink -f "$(dirname "${0}")")"
version=34

podman build -t fedwsl:${version} "${pkg}"
podman run --name fedwsl fedwsl:${version} /bin/bash
podman export -o install.tar fedwsl
gzip install.tar
