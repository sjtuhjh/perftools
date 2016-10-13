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

if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
    add_ubuntu_source
fi

${SUDO_PREFIX} ${INSTALL_CMD} install -y -q linux-source
${SUDO_PREFIX} ${INSTALL_CMD} install -y -q linux-image-${KERNEL_REL}-dbgsym
#./utils/get-dbgsym.sh
${SUDO_PREFIX} ${INSTALL_CMD} install -y -q systemtap
${SUDO_PREFIX} ${INSTALL_CMD} install -y -q elfutils
./utils/config_elfutils.sh

echo "*******************************************************"
echo "********** Verify stap has been installed *************"
echo "*******************************************************"
${SUDO_PREFIX} stap -e 'probe begin { printf("OK\n"); exit();}'


