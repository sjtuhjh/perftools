#!/bin/bash

if [ ! -f ./iftop-0.17.tar.gz ] ; then
    wget http://www.ex-parrot.com/pdw/iftop/download/iftop-0.17.tar.gz
fi

if [ ! -d ./iftop-0.17 ] ; then
    tar -zxvf iftop-0.17.tar.gz
fi

yum -y install libpcap libpcap-devel ncurses ncurses-devel

cd iftop-0.17
./configure --build=aarch64-unknown-linux-gnu
make
make install

