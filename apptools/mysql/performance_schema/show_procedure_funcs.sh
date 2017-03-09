#!/bin/bash

#One tool to display mysql performance schema informations

user=mysql
password="Estuary12#$"
mysql="/u01/my3306/bin/mysql"
ipaddr="192.168.1.86"
port="3306"
mysql_sys_dir="./mysql_sys"
mysql_version="5.6"

echo "Try to get performance schema data from ${mysql_version} ......"
echo "Make sure mysql_version has been set correctly !"

pushd ${mysql_sys_dir} > /dev/null

if [ "${mysql_version}" == "5.6" ] ; then
    sql_version="./sys_56.sql"
else 
    sql_version="./sys_57.sql"
fi

exec_mysql_cmd() {
${mysql} -h ${ipaddr} -u ${user} -p${password} -P${port} << EOF
USE sys;
${1}
EOF
}

exec_mysql_cmd "select name, type from mysql.proc where db='sys';"

popd > /dev/null
