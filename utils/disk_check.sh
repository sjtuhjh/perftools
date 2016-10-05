#!/bin/bash

SUDO_PRFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum install"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get install"
fi

#Prepare to install some tools firstly
${SUDO_PREFIX} ${INSTALL_CMD} -y -q sysstat

if [ -z "$(which smartmontools)" ] ; then
echo "#########################################################################"
mkdir ../builddir
pushd ../builddir > /dev/null

${SUDO_PREFIX} apt-get -y install bison build-essential cmake flex git libedit-dev \
  libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev

git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make 
${SUDO_PREFIX} make install
popd > /dev/null
echo "#########################################################################"
fi

#${SUDO_PREFIX} ${INSTALL_CMD} -y -q ext4slower
#${SUDO_PREFIX} ${INSTALL_CMD} -y -q bioslower
#${SUDO_PREFIX} ${INSTALL_CMD} -y -q ext4dist
#${SUDO_PREFIX} ${INSTALL_CMD} -y -q biolatency
${SUDO_PREFIX} ${INSTALL_CMD} -y -q smartmontools

interval=10
#Step 1 
echo "step 1: iostat"
iostat -xz 1 ${interval}

#Step 2: "swapping? or high sys time"
echo "Step2: swapping or high sys time"
vmstat 1 ${interval}

#Step 3: "Are file system full?"
echo "Step3: file system full?"
df -h

#Step 4: "(zfs*, xfs*, etc.) slow file system I/O?
echo "slow file system IO"
ext4slower.py 10 ${interval}

#Step 5: "check disks"
bioslower 10 ${inteval}

#Step 6: "check distribution and rate"
echo "Distribution and rate"
ext4dist 1 ${interval}

#Step 7: "check disks"
biolatency.py 1

#Step 8: "check error"
for filename in `find /sys/devices/ -name ioerr_cnt`
do  
    echo ${filename}
    cat filename
done

smartctl -l error /dev/sda1

