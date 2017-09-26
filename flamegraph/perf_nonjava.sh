#!/bin/bash

CUR_DIR=$(cd `dirname $0`; pwd)
OUTPUT_FILE=${1:-perf_nonjava.svg}

echo "Wait for perf record about 60 seconds ..."
perf record -F 99 -a -g -- sleep 60; 
perf script | ${CUR_DIR}/FlameGraph/stackcollapse-perf.pl > out.perf-folded
${CUR_DIR}/FlameGraph/flamegraph.pl out.perf-folded > ${OUTPUT_FILE}

