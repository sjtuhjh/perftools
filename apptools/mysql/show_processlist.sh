#!/bin/bash

if [ -z "$(which mysql)" ] ; then
    MYSQL="/u01/my3306/bin/mysql"
else 
    MYSQL="mysql"
fi

#PROCESS_LOG="processlist-`date +%F-%H:%M`.log"

PROCESS_LOG="tmp_log"

while [[ 1 ]] 
do
${MYSQL} -uroot -p --socket=/u01/u0/my3306/run/mysql.sock -e "show full processlist" > ./${PROCESS_LOG}
grep State: ./${PROCESS_LOG} | sort | uniq -c | sort -rn
sleep

done

