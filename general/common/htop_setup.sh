#!/bin/bash

git clone https://github.com/hishamhm/htop
cd htop
./autogen.sh 
./configure --prefix=/usr/local/htop
make
make install

