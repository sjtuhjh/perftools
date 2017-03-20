#!/bin/bash

export GOPATH=$(cd `dirname $0`; pwd)

#Install glide firstly
if [ -z "$(which glide 2>/dev/null)" ] ; then
    if [ -d ${GOPATH}/go/bin ] ; then
        mkdir -p ${GOPATH}/go/bin
    fi
    curl https://glide.sh/get | sh
    cp ${GOPATH}/go/bin/glide /usr/local/bin/
fi

cd src/github.com/percona/percona-toolkit/src/go

if [ ! -d ./vendor ] ; then
    glide update
fi

sed -i 's/arm/arm\ arm64/g' ../../vendor/go4.org/reflectutil/asm_b.s

if [ ! -f ${GOPATH}/pt-mongodb-summary ] ; then
    OS=linux GOARCH=arm64 go build -o ${GOPATH}/pt-mongodb-summary ./pt-mongodb-summary/main.go
    cp ./pt-mongodb-summary /usr/sbin/
fi

if [ ! -f ${GOPATH}/pt-mongodb-query-digest ] ; then
    OS=linux GOARCH=arm64 go build -o ${GOPATH}/pt-mongodb-query-digest ./pt-mongodb-query-digest/main.go
    cp ./pt-mongodb-query-digest /usr/sbin/
fi

