#!/bin/bash

VERSION="1.1.7"

if [ ! -f "percona-monitoring-plugins-${VERSION}.tar.gz" ] ; then
    wget https://www.percona.com/downloads/percona-monitoring-plugins/percona-monitoring-plugins-${VERSION}/source/tarball/percona-monitoring-plugins-${VERSION}.tar.gz
fi

if [ ! -d "percona-monitoring-plugins-${VERSION}" ] ; then
    tar -zxvf "percona-monitoring-plugins-${VERSION}.tar.gz"
fi

yum install -y perl-Digest-MD5 PyYAML python-sphinx

pushd ./percona-monitoring-plugins-${VERSION} > /dev/null
./make.sh nopdf

popd > /dev/null
