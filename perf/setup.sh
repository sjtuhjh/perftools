#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

INSTALL_CMD="yum"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
fi

${SUDO_PREFIX} ${INSTALL_CMD} -yq linux-tools-common
