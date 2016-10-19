#!/bin/bash

INSTALL_CMD="yum"
if [ "$(which apt-get)" ] ; then
    INSTALL_CMD="apt-get"
fi

#pstack
${INSTALL_CMD} install -y  pstack

#pidstat:
${INSTALL_CMD} install -y  sysstat


