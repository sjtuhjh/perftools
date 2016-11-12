#!/bin/bash

#One tool to show slow logs

user="root"
password="123456"
mysql="/u01/my3306/bin/mysql"
socket="/u01/u0/my3306/run/mysql.sock"
slowlog="/u01/u0/my3306/log/slow.log"
ipaddr="127.0.0.1"
default_log_time="1.0"
sleep_time=10
cur_slow_log="./tmp/cur_slow_log"

if [[ $# -lt 1 ]] ; then
    echo "Usage: show_mysql_slowlog.sh <my_output_file> {time_interval} {password}"
    exit 0
fi

if [[ $# -gt 1 ]] ; then
    sleep_time=${2}
fi

if [ ! -d "./tmp" ] ; then
    mkdir "./tmp"
fi

mysql_slow_output=${1}
if [ "${mysql_ps_output:0:1}" != "\/" ] ; then
    mysql_slow_output="$(pwd)/"${mysql_slow_output}
fi

echo "Make sure current slow log and socket is correct:"
echo "socket:${socket}"
echo "slowlog:${slowlog}"

#Enabled slow logs for all querys
echo "Begin to enable slow logs for all query ......"
${mysql} -h ${ipaddr} -u ${user} -p${password} --socket=${socket} << EOF
set global slow_query_log_use_global_control = all;
set global log_slow_verbosity=profiling;
set global log_slow_rate_type=session;
set global long_query_time=0;
EOF

echo "Capture logs for ${sleep_time} seconds ......"
sleep ${sleep_time}
cp ${slowlog} ${cur_slow_log}

echo "Disable slow logs for all query ......"
#Set long_query_time to default value
${mysql} -h ${ipaddr} -u ${user} -p${password} --socket=${socket} << EOF
set global long_query_time=${default_log_time};
exit
EOF

echo "Begin to call pt-query-digest to analysis slow logs"
../../perconatoolkit/percona-toolkit-2.2.19/bin/pt-query-digest ${cur_slow_log} >  ${mysql_slow_output}
