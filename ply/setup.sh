#!/bin/bash

BUILD_DIR="/tmp/ply_build"
if [ ! -d "${BUILD_DIR}" ] ; then
    mkdir -p "${BUILD_DIR}"
fi

pushd ${BUILD_DIR} >/dev/null
git clone https://github.com/iovisor/ply.git
cd ply
./autogen.sh
./configure
make
make install

popd > /dev/null

