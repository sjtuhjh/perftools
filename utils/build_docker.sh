#!/bin/bash

ADD_SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    ADD_SUDO_PREFIX=""
fi

INSTALL_CMD="yum install -y"
PACKAGES='golang btrfs-progs sqlite-devel device-mapper device-mapper-devel '  
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get install -y"
    PACKAGES="golang-go git-core btrfs-tools libsqlite3-dev libdevmapper-dev build-essential"
else
    ${ADD_SUDO_PREFIX} yum install -y "Development Tools"
fi

${ADD_SUDO_PREFIX} ${INSTALL_CMD} docker
${ADD_SUDO_PREFIX} ${INSTALL_CMD} ${PACKAGES}

DOCKER_BUILD_DIR="/tmp/docker_source"
if [ -d "${DOCKER_BUILD_DIR}" ] ; then
    ${ADD_SUDO_PREFIX} rm -r ${DOCKER_BUILD_DIR}
fi

mkdir -p ${DOCKER_BUILD_DIR}
pushd ${DOCKER_BUILD_DIR} > /dev/nul

#Step 1: Start old docker
${ADD_SUDO_PREFIX} systemctl start docker

#Step 2: Build latest docker
git clone https://github.com/docker/docker
cd docker
make build

#Then docker-dev image will be built successfully
popd > /dev/null

