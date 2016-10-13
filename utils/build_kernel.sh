#!/bin/bash

if [ $# -lt 1 ] ; then
    echo "Please input kernel source directory"
    exit 0
fi

KERNEL_SRC=${1}

CROSS_CMD="CROSS_COMPILE=aarch64-linux-gnu-"
if [ "$(uname -m)" == "aarch64" ] ; then
    CROSS_CMD=""
fi

pushd ${KERNEL_SRC} > /dev/null

./scripts/kconfig/merge_config.sh -m arch/arm64/configs/defconfig arch/arm64/configs/distro.config arch/arm64/configs/estuary_defconfig
#make ARCH=arm64 menuconfig
mv -f .config .merged.config
make ARCH=arm64 ${CROSS_CMD} KCONFIG_ALLCONFIG=.merged.config alldefconfig
make ARCH=arm64 ${CROSS_CMD} Image -j40

make ARCH=arm64 ${CROSS_CMD} modules -j40

#if [ "$(uname -m)" == "aarch64" ] ; then
#make ARCH=arm64 ${CROSS_CMD} modules_install
#make ARCH=arm64 install
#fi

popd > /dev/null

