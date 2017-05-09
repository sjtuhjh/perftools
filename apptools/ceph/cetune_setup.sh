#!/bin/bash

role=$1


git clone https://github.com/01org/CeTune
cd CeTune/deploy

if [ x"${role}" == x"controlloer" ] ; then
    python controller_dependencies_install.py
else
    python worker_dependencies_install.py
fi


