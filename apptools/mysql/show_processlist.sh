#!/bin/bash

if [ -z "$(which mysql)" ] ; then
    MYSQL="/u01/my3306/bin/mysql"
else 
    MYSQL="mysql"
fi

PROCESS_LOG="processlist-`date +%F-%H:%M`.log"

${MYSQL} -uroot -p -e "show full processlist" > ./${PROCESS_LOG}
grep State: ./${PROCESS_LOG} | sort | uniq -c | sort -rn

