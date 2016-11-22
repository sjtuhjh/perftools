#!/bin/bash

#One tool to display mysql performance schema informations

user=root
password="123456"
mysql="/u01/my3306/bin/mysql"
socket="/u01/u0/my3306/run/mysql.sock"
ipaddr="127.0.0.1"
mysql_sys_dir="./mysql_sys"
mysql_version="5.7"

if [[ $# -lt 1 ]] ; then
    echo "Usage: enable_mysql_ps.sh <enable | disable | reset> { all | specific parts}"
    exit 0
fi

if [ "x${1}" != "xenable" ] && [ "x${1}" != "xdisable" ] && [ "x${1}" != "xreset" ] ; then
    echo "The first command should be enable or disable"
fi

part_cmd=""
if [ -z "${2}" ] ; then
    part_cmd=""
else 
    part_cmd="${2}"
fi

pushd ${mysql_sys_dir} > /dev/null
if [ "${mysql_version}" == "5.6" ] ; then
    sql_version="./sys_56.sql"
else 
    sql_version="./sys_57.sql"
fi

enable_ps_stats() {
${mysql} -h ${ipaddr} -u ${user} -p --socket=${socket} << EOF
SOURCE ${sql_version}; 
CALL sys.ps_setup_${1}_instrument("${2}")
CALL sys.ps_setup_${1}_consumer("${2}")
exit
EOF
}

reset_ps_stats() {
${mysql} -h ${ipaddr} -u ${user} -p --socket=${socket} << EOF
CALL sys.ps_setup_reset_to_default(true) \G
exit
EOF
}

if [ "${1}" == "enable" ] || [ "${1}" == "disable" ] ; then
    enable_ps_stats ${1} ${part_cmd}
elif [ "${1}" == "reset" ]; then
    reset_ps_stats
else 
    echo "Unknown command:${1}"
fi
popd > /dev/null

