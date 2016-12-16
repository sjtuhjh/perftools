#!/bin/bash

seconds=30
output_file="perf.svg"
if [ ! -z "${1}" ] ; then
    output_file=${1}
fi

/usr/local/bcc/tools/profile.py  -dF 99  ${seconds} | ./flamegraph.pl > ${output_file}

