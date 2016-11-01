#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

echo "Begin to install Percona Toolkit ......"

VERSION="2.2.19"
wget https://www.percona.com/downloads/percona-toolkit/${VERSION}/tarball/percona-toolkit-${VERSION}.tar.gz
tar -zxvf percona-toolkit-${VERSION}.tar.gz

echo "Enjoy Percona-toolkit right now!"

