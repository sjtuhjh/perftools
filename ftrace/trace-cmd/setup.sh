#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
fi

${SUDO_PREFIX} ${INSTALL_CMD} install -y -q trace-cmd kernelshark

if [ -z "$(which trace-cmd)" ] ; then
    mkdir ../builddir
    pushd ../builddir
    git clone git://git.kernel.org/pub/scm/linux/kernel/git/rostedt/trace-cmd.git
    cd trace-cmd
    git checkout trace-cmd-v2.6 -b trace-v2.6
    make 
    make gui
    ${SUDO_PREFIX} make install
    make clean

    git checkout kernelshark-v0.2 -b kernelshark-v0.2
    make
fi

