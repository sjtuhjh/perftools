#!/bin/bash

# Purpose: This tool is to build estuary kernel in order to setup kernel source for some tools such as systemtap

#Possible is Ubuntu, CentOS, OpenSue

if [ $# -lt 1 ] ; then
    echo "Usage: estuary_build_kernel.sh <DISTROS> <PLATFORM> <Source Tag>"
    exit 0
fi

if [ ! -d "/lib/modules/$(uname -r)" ] ; then
    echo "The /lib/modules/$(uname -r)/ does not exist"
    echo "Please install kernel modules firstly"
    exit 0
fi

DISTROS=$1
PLATFORM="d03"
if [ $# -gt 1 ] ; then
    PLATFORM=${2}
fi

TAG_VERSION="master"
if [ $# -gt 2 ] ; then
    TAG_VERSIOiN="${3}"
fi

ADD_SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    ADD_SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
fi

SOURCE_DIR="$(cd ~; pwd)/open-estuary"
BUILD_DIR="${SOURCE_DIR}"/workspace

mkdir -p ~/bin
${ADD_SUDO_PREFIX} ${INSTALL_CMD} install -y -q wget git
wget -c http://download.open-estuary.org/AllDownloads/DownloadsEstuary/utils/repo -O ~/bin/repo
chmod a+x ~/bin/repo; echo 'export PATH=~/bin:$PATH' >> ~/.bashrc; export PATH=~/bin:$PATH; mkdir -p ~/open-estuary; cd ~/open-estuary
#repo abandon master
#repo forall -c git reset --hard

if [ "${TAG_VERSION}" != "master" ] ; then
    TAG_VERSION=refs/tags/${TAG_VERSION}
fi

if [ ! -d "${SOURCE_DIR}/.repo}" ] ; then
    repo init -u "https://github.com/open-estuary/estuary.git" -b ${TAG_VERSION} --no-repo-verify --repo-url=git://android.git.linaro.org/tools/repo 
fi

cp -f ~/open-estuary/.repo/repo/repo ~/bin/repo

false; while [ $? -ne 0 ]; do repo sync; done

#${ADD_SUDO_PREFIX} ./estuary/build.sh --builddir=${BUILD_DIR} --platform=${PLATFORM} --distro=${DISTRIOS}

#Update Kernel Source links
${ADD_SUDO_PREFIX} rm -r /lib/modules/$(uname -r)/build
${ADD_SUDO_PREFIX} rm -r /lib/modules/$(uname -r)/source

${ADD_SUDO_PREFIX} ln -s /usr/src/kernels/$(uname -r) /lib/modules/$(uname -r)/build 
${ADD_SUDO_PREFIX} ln -s /usr/src/kernels/$(uname -r) /lib/modules/$(uname -r)/source


