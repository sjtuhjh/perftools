#!/bin/bash

git clone https://github.com/vgropp/bwm-ng.git
cd bwm-ng

./autogen.sh
./configure
make
make install

