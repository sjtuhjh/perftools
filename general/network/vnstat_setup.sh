#!/bin/bash

wget http://humdi.net/vnstat/vnstat-1.17.tar.gz

tar -zxvf vnstat-1.17.tar.gz
cd vnstat-1.17

./autogen.sh
./configure
make
make install

