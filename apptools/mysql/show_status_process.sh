#!/bin/bash

#To show 

if [ -z "$(which mysql)" ] ; then
    MYSQL="/u01/my3306/bin/mysql"
else  
    MYSQL="mysql"

STATUS_DIR=status-`date +%F-%H:%M`
mkdir ${STATUS_DIR}
${MYSQL} -uroot -p -e "show full processlist" $@ > ./${STATUS_DIR}/processlist.log
${MYSQL} -uroot -p -e "show variables" $@ > ./${STATUS_DIR}/variables.log
${MYSQL} -uroot -p -e "show global status" $@ > ./${STATUS_DIR}/globalstatus.log
${MYSQL} -uroot -p -e "show engine innodb status \G" $@ > ./${STATUS_DIR}/innodb.log


