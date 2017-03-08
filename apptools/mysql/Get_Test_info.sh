#!/bin/bash
INTERVAL=5
TEST_DIR="/home/test"
PREFIX=${TEST_DIR}/benchmarks/$INTERVAL-sec-status
RUNFILE=${TEST_DIR}/benchmarks/running
echo "1" > $RUNFILE
MYSQL="/usr/local/mariadb/bin/mysql -p123456 -P3306 -h127.0.0.1 -umysql"

$MYSQL -e "show global variables" >> mysql-variables
while test -e $RUNFILE; do
	file=$(date +%F_%I)
	sleep=$(date +%s.%N | awk '{print 5 - ($1 % 5)}')
	sleep $sleep
	ts="$(date +"TS %s.%N %F %T")"
	loadavg="$(uptime)"
	echo "$ts $loadavg" >> $PREFIX-${file}-status
	$MYSQL -e "show global status" >> $PREFIX-${file}-status &
	echo "$ts $loadavg" >> $PREFIX-${file}-innodbstatus
	$MYSQL -e "show engine innodb status" >> $PREFIX-${file}-innodbstatus &
	echo "$ts $loadavg" >> $PREFIX-${file}-processlist
	$MYSQL -e "show full processlist\G" >> $PREFIX-${file}-processlist &
	echo $ts
done
echo Exiting because $RUNFILE does not exists
