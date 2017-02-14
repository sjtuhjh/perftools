#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
if [ "$(which apt-get 2>/dev/null)" ] ; then
    INSTALL_CMD="apt-get"
fi

${SUDO_PREFIX} ${INSTALL_CMD} install -y -q linux-tools-common
