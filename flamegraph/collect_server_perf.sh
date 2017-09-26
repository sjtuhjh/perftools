#!/bin/bash

CUR_DIR=$(cd `dirname $0`; pwd)

OUT_DIR="${1}"
OUT_SUFFIX="${2}"

FILTER_PORT=""
if [ ! -z "${3}" ] ; then
    FILTER_PORT="-port ${3}"
fi

if [ -z "${OUT_DIR}" ] || [ -z "${OUT_SUFFIX}" ]; then
    echo "Please input <output directory> <outout_suffix>"
fi

if [ ! -d "${OUT_DIR}" ] ; then
    mkdir -p ${OUT_DIR}
fi

OUT_FILE="${OUT_DIR}/tcp_client_rw_latency_${OUT_SUFFIX}"

if [ -f ${OUT_FILE} ] ; then
    echo "The  ${OUT_FILE} does exist. Do you want to overwirte it?"
    exit 0
fi

${CUR_DIR}/../bcc/bcc_scripts/tcprwlat.py ${FILTER_PORT} -s -i 10 -t 30 > ${OUT_FILE}

OUT_FILE="${OUT_DIR}/perf_java_${OUT_SUFFIX}.svg"
${CUR_DIR}/perf_java.sh ${OUT_FILE}

OUT_FILE="${OUT_DIR}/perf_${OUT_SUFFIX}.svg"
${CUR_DIR}/perf_nonjava.sh ${OUT_FILE}
