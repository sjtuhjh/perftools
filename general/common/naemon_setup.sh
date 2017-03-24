#!/bin/bash

git clone --recursive https://github.com/naemon/naemon.git
cd naemon
make update
./configure
make
make install

