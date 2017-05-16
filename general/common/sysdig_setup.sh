#!/bin/bash

git clone https://github.com/sjtuhjh/sysdig

cd sysdig
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=release ..
make -j 32
make install

insmod ./driver/*.ko


