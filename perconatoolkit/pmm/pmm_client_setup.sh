#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

CUR_DIR=$(cd `dirname $0`; pwd)

echo "Begin to install Percona PMM Client......"
export GOPATH=$CUR_DIR
PMM_CLIENT_DIR="${GOPATH}"'/src/github.com/percona/'

if [ -z "$(which govendor 2>/dev/null)" ] ; then
   go get -u github.com/kardianos/govendor   
   cp ${GOPATH}/bin/govendor /usr/sbin/
fi 

if [ ! -d $GOPATH/src/github.com/Percona-Lab ] ; then
    mkdir -p $GOPATH/src/github.com/Percona-Lab
fi

go get github.com/mattn/go-colorable
go get github.com/mattn/go-isatty
go get gopkg.in/mgo.v2/bson
go get github.com/percona/mongodb_exporter/collector
VERSION="v1.0.7"
if [ ! -d ${PMM_CLIENT_DIR} ] ; then
    mkdir -p  ${PMM_CLIENT_DIR}
fi

pushd ${PMM_CLIENT_DIR} > /dev/null
cd ../Percona-Lab
git clone https://github.com/Percona-Lab/prometheus_mongodb_exporter

cd ${PMM_CLIENT_DIR}
git clone https://github.com/percona/pmm-client
git clone https://github.com/percona/qan-agent
git clone https://github.com/percona/node_exporter
git clone https://github.com/percona/mysqld_exporter
git clone https://github.com/percona/proxysql_exporter

cd pmm-client
git pull
git checkout ${VERSION}

#To support ARM64 platform
sed -i 's/x86_64/aarch64/g' scripts/*
sed -i 's/amd64/aarch64/g' scripts/*

./scripts/build

cd distro
../scripts/install

popd > /dev/null
echo "Enjoy Percona-toolkit right now!"

