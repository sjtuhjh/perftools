#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
KERNEL_REL="$(uname -r)"

add_ubuntu_source() {
   if [ -z "$(grep "http://ddebs.ubuntu.com" /etc/apt/sources.list.d/*)" ] ; then

   ${SUDO_PREFIX} echo "deb http://ddebs.ubuntu.com $(lsb_release -cs) main restricted universe multiverse
   deb http://ddebs.ubuntu.com $(lsb_release -cs)-updates main restricted universe multiverse
   deb http://ddebs.ubuntu.com $(lsb_release -cs)-security main restricted universe multiverse
   deb http://ddebs.ubuntu.com $(lsb_release -cs)-proposed main restricted universe multiverse" | \
   ${SUDO_PREFIX} tee -a /etc/apt/sources.list.d/ddebs.list

   ${SUDO_PREFIX} apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 428D7C01 C8CAB6595FDFF622
   
   ${SUDO_PREFIX} apt-get update
   
   fi
}

download_and_build_systamp() {
    mkdir builddir
    pushd builddir > /dev/null

    STAP_VER="3.0"

    ${SUDO_PREFIX} ${INSTALL_CMD} install -y -q libdw-dev 
    ${SUDO_PREFIX} ${INSTALL_CMD} install -y -q elfutils 
    ${SUDO_PREFIX} ${INSTALL_CMD} install -y -q elfutils-dev 
    ${SUDO_PREFIX} ${INSTALL_CMD} install -y -q libebl-dev 
    ${SUDO_PREFIX} ${INSTALL_CMD} install -y -q gettext

    if [ ! -f systemtap-${STAP_VER}.tar.gz ] ; then
        wget https://sourceware.org/systemtap/ftp/releases/systemtap-${STAP_VER}.tar.gz
    fi

    tar -zxvf systemtap-${STAP_VER}.tar.gz
    cd systemtap-${STAP_VER}    
    ${SUDO_PREFIX} ./configure -prefix=/opt/systemtap -disable-docs -disable-publican -disable-refdocs
    ${SUDO_PREFIX} make 
    ${SUDO_PREFIX} make install
   
    ${SUDO_PREFIX} ln -s /opt/systemtap/bin/stap /usr/sbin/stap

    popd > /dev/null
}


if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
    add_ubuntu_source
fi

${SUDO_PREFIX} ${INSTALL_CMD} install -y -q linux-source
${SUDO_PREFIX} ${INSTALL_CMD} install -y -q linux-image-${KERNEL_REL}-dbgsym
#./utils/get-dbgsym.sh
download_and_build_systamp
#${SUDO_PREFIX} ${INSTALL_CMD} install -y -q systemtap
#${SUDO_PREFIX} ${INSTALL_CMD} install -y -q systemtap-dbgsym
${SUDO_PREFIX} ${INSTALL_CMD} install -y -q elfutils
./utils/config_elfutils.sh

echo "*******************************************************"
echo "********** Verify stap has been installed *************"
echo "*******************************************************"
${SUDO_PREFIX} stap -e 'probe begin { printf("OK\n"); exit();}'


