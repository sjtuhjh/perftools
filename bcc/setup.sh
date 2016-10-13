#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum install"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get install"
fi

${SUDO_PREFIX} ${INSTALL_CMD} -y -q bison build-essential cmake flex git libedit-dev \
  libllvm3.7 llvm-3.7-dev libclang-3.7-dev python zlib1g-dev libelf-dev

# For Lua support
${SUDO_PREFIX} ${INSTALL_CMD} -y -q luajit luajit-5.1-dev

#Build and install
git clone https://github.com/iovisor/bcc.git
mkdir bcc/build; cd bcc/build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make
${SUDO_PREFIX} make install


