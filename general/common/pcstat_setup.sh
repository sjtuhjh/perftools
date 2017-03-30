#!/bin/bash

#git clone https://github.com/sjtuhjh/pcstat.git

export GOPATH=`pwd`/pcstat

go get golang.org/x/sys/unix
go get github.com/sjtuhjh/pcstat/pcstat
sudo cp ${GOPATH}/bin/pcstat /usr/local/bin/

