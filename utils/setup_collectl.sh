#!/bin/bash

wget https://downloads.sourceforge.net/project/collectl/collectl/collectl-4.1.2/collectl-4.1.2.src.tar.gz

tar -zxvf collectl-4.1.2.src.tar.gz
cd collectl-4.1.2.src
./configure
make
make install

