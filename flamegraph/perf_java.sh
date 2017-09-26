#!/bin/bash

export AGENT_HOME="/usr/lib/jvm/perf-map-agent"

if [ -z "$JAVA_HOME" ] ; then
    echo "Please set JAVA_HOME firstly"
    exit 0
fi

CUR_DIR=$(cd `dirname $0`; pwd)
AGENT_DIR="/usr/lib/jvm"

if [ ! -d "${AGENT_DIR}/perf-map-agent" ] ; then
    mkdir -p ${AGENT_DIR}
    cp -fr ${CUR_DIR}/perf-map-agent ${AGENT_DIR}/

    pushd ${AGENT_DIR}/perf-map-agent > /dev/null
    cmake .
    make
    popd > /dev/null
fi

OUTPUT_FILE=${1:-perf_output.svg}

echo "Wait for perf record 60 seconds ..."
perf record -F 99 -a -g -- sleep 60; ${CUR_DIR}/FlameGraph/jmaps
perf script > out.stacks01
cat out.stacks01 | ${CUR_DIR}/FlameGraph/stackcollapse-perf.pl | grep -v cpu_idle | ${CUR_DIR}/FlameGraph/flamegraph.pl --color=java --hash > ${OUTPUT_FILE}

