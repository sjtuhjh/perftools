#!/bin/bash

INTERFACE="eth0"
if [ ! -z "${1}" ] ; then
    INTERFACE=$1
fi

NUM=1000
if [ ! -z "${2}" ] ; then
   NUM=$2
fi

tcpdump -s 65535 -x -nn -q -tttt -i ${INTERFACE} -c ${NUM} port 3306 > mysql.tcp.txt
./percona-toolkit-3.0.1/bin/pt-query-digest --type tcpdump mysql.tcp.txt

