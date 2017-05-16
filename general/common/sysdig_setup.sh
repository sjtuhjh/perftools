#!/bin/bash

git clone https://github.com/sjtuhjh/sysdig

cd sysdig
git branch master
git checkout master
git branch --set-upstream-to=origin/master master
git pull
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=release ..
make -j 32
make install

insmod ./driver/*.ko


