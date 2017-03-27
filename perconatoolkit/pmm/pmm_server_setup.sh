#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

echo "Begin to install Percona PMM server......"

VERSION="v1.1.1"
git clone https://github.com/percona/pmm-server

cd pmm-server
git pull
git checkout ${VERSION}

echo "Warning: By default, the base image in Dockerfile is based on X86 platform."
echo "         So please change them if you want to build ARM64 platform"

docker build .

echo "Enjoy Percona-PMM server right now!"

