#!/bin/bash

#One tool to display mysql performance schema informations

user=root
password="123456"
mysql="/u01/my3306/bin/mysql"
port="3306"
ipaddr="192.168.1.233"
mysql_sys_dir="./mysql_sys"


execute_mysql_cmd() {
${mysql} -h ${ipaddr} -u ${user} -p'123456' -P${2} << EOF
${1}
exit
EOF
}

max_inst=200
cur_inst=0

cmd_str="set global innodb_spin_wait_delay=6; set global innodb_sync_spin_loops=20;"

while [[ ${cur_inst} -lt ${max_inst} ]] 
do
    let "port=3306+cur_inst"
    execute_mysql_cmd  "${cmd_str}" ${port}
    let "cur_inst++"
done

