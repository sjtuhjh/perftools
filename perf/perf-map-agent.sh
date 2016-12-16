#!/bin/bash

#This tool is to install perf-map-agent which provides map for java profiling

if [ -z "${JAVA_HOME}" ] ; then
    echo "JAVA_HOME need to be specified firstly"
    exit 0
fi

pushd /usr/lib/jvm/ > /dev/null
git clone --depth=1 https://github.com/jrudolph/perf-map-agent
cd perf-map-agent
cmake .
make
popd > /dev/null


