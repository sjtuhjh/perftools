#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
KERNEL_REL="$(uname -r)"

download_and_build_lttng() {
    mkdir builddir
    pushd builddir > /dev/null

    if [ -d "userspace-rcu" ] ; then
        cd userspace-rcu
        git pull
    else 
        git clone git://git.liburcu.org/userspace-rcu.git
        cd userspace-rcu
    fi
    ./bootstrap
    ./configure --disable-man-pages
    make
    ${SUDO_PREFIX} make install
    ${SUDO_PREFIX} ldconfig
    
    SOURCE_DIR=""
    for filename in `ls /usr/src` 
    do 
        if [[ ${filename} =~ "linux-source" ]] &&  [[ "$(uname -r)" =~ ${filename:13} ]] ; then 
            SOURCE_DIR="/usr/src/${filename}"
            break
        fi
    done
   
    cd ../
    if [ -d "lttng-modules" ] ; then
        cd lttng-modules
        git pull
    else 
        git clone https://github.com/lttng/lttng-modules.git
        cd lttng-modules
    fi
    if [ -z "${SOURCE_DIR}" ] ; then  
        make
        ${SUDO_PREFIX} make modules_install
    else 
        make KERNELDIR=${SOURCE_DIR}
        ${SUDO_PREFIX} make modules_install KERNELDIR=${SOURCE_DIR} modules_install
    fi
    ${SUDO_PREFIX} depmod -a
    cd ../

    if [ -d "lttng-ust" ] ; then
        cd lttng-ust
        git pull
    else 
        git clone https://github.com/lttng/lttng-ust.git
        cd lttng-ust
    fi
    ./bootstrap
    ./configure --disable-man-pages
    make
    ${SUDO_PREFIX} make install
    ${SUDO_PREFIX} ldconfig
    cd ../

    if [ -d "lttng-tools" ] ; then
        cd lttng-tools
        git pull
    else 
        git clone https://github.com/lttng/lttng-tools.git
        cd lttng-tools
    fi
    ./bootstrap
    ./configure --disable-man-pages
    make
    ${SUDO_PREFIX} make install
    ${SUDO_PREFIX} ldconfig
    cd ../
    popd > /dev/null
}

if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
fi

${SUDO_PREFIX} ${INSTALL_CMD} install -yq openssl
${SUDO_PREFIX} ${INSTALL_CMD} install -yq libssl-dev
${SUDO_PREFIX} ${INSTALL_CMD} install -yq libpopt-dev
#${SUDO_PREFIX} ${INSTALL_CMD} install -yq liburcu
${SUDO_PREFIX} ${INSTALL_CMD} install -yq libxml2
${SUDO_PREFIX} ${INSTALL_CMD} install -yq libxml2-dev 
${SUDO_PREFIX} ${INSTALL_CMD} install -yq uuid-dev
${SUDO_PREFIX} ${INSTALL_CMD} install -yq linux-headers-$(uname -r) 
${SUDO_PREFIX} ${INSTALL_CMD} install -yq linux-source
#./utils/get-dbgsym.sh
download_and_build_lttng

echo "*******************************************************"
echo "********** Verify lttng has been installed *************"
echo "*******************************************************"


