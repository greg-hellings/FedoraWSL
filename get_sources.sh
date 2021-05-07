#!/bin/bash
pkg="$(readlink -f "$(dirname "${0}")")"
version=$(cat DistroLauncher-Appx/FedoraWSL.appxmanifest | grep 'Name="FedoraWSL" Version=' | sed -E -e 's/^.*Version="([.0-9]*)".*$/\1/' | cut -d. -f1)

sed -E -e "s/latest/${version}/" Containerfile.in > Containerfile
podman build -t fedwsl:${version} "${pkg}"
podman run --name fedwsl fedwsl:${version} /bin/bash
podman export -o install.tar fedwsl
gzip install.tar
