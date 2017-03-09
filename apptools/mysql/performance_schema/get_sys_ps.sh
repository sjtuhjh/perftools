#!/bin/bash

#One tool to display mysql performance schema informations

user=mysql
password="Estuary12#$"
mysql="/u01/my3306/bin/mysql"
ipaddr="192.168.1.86"
port="3306"
mysql_sys_dir="./mysql_sys"
mysql_version="5.6"

if [[ $# -lt 1 ]] ; then
    echo "Usage: show_mysql_ps.sh <show | cmd_index | all> <my_output_file>"
fi

echo "Try to get performance schema data from ${mysql_version} ......"
echo "Make sure mysql_version has been set correctly !"

mysql_ps_output=${2}
if [ ! -z "${2}" ] && [ x"${1}" != x"show" ]  ; then
    cur_dir=$(cd dirname `$0`; pwd)
    mysql_ps_output=${cur_dir}/${mysql_pos_output}
fi

cmd_index=${1}
if [ -z "${1}" ] ; then
    cmd_index="all"
fi

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

cmd[0]="select * from performance_schema.setup_instruments;"
cmd[1]="select * from sys.version;"
cmd[2]="select * from innodb_buffer_stats_by_schema;"
cmd[3]="select * from innodb_buffer_stats_by_table;"
cmd[4]="select * from innodb_lock_waits \G"
cmd[5]="select * from schema_object_overview;"
cmd[6]="select * from schema_auto_increment_columns limit 5;"
cmd[7]="select * from sys.schema_redundant_indexes\G"
cmd[8]="select * from ps_check_lost_instrumentation;"
cmd[9]="select * from latest_file_io;"
cmd[10]="select * from io_by_thread_by_latency;"
cmd[11]="select * from io_global_by_file_by_latency;"
cmd[12]="select * from io_global_by_wait_by_bytes;"
cmd[13]="select * from schema_index_statistics;"
cmd[14]="select * from schema_table_statistics_with_buffer\G"
cmd[15]="select * from schema_tables_with_full_table_scans;"
cmd[16]="select * from schema_unused_indexes;"
cmd[17]="select * from statement_analysis\G"
cmd[18]="select * from statements_with_errors_or_warnings\G"
cmd[19]="select * from statements_with_full_table_scans\G"
cmd[20]="select * from statements_with_runtimes_in_95th_percentile;"
cmd[21]="select * from statements_with_sorting\G"
cmd[22]="select * from statements_with_temp_tables\G"
cmd[23]="select * from user_summary_by_file_io_type;"
cmd[24]="select * from user_summary_by_file_io;"
cmd[25]="select * from user_summary_by_statement_type;"
cmd[26]="select * from user_summary_by_statement_latency;"
cmd[27]="select * from user_summary_by_stages;"
cmd[28]="select * from user_summary;"
cmd[29]="select * from host_summary_by_file_io_type;"
cmd[30]="select * from host_summary_by_file_io;"
cmd[31]="select * from host_summary_by_statement_type;"
cmd[32]="select * from host_summary_by_stages;"
cmd[33]="select * from host_summary;"
cmd[34]="select * from wait_classes_global_by_avg_latency where event_class != 'idle';"
cmd[35]="select * from wait_classes_global_by_latency;"
cmd[36]="select * from waits_by_user_by_latency;"
cmd[37]="select * from waits_by_host_by_latency;"
cmd[38]="select * from waits_global_by_latency;"
cmd[39]="select * from sys.waits_by_host_by_latency where host != 'background';"
cmd[40]="select * from sys.processlist where conn_id is not null and command != 'daemon' and conn_id != connection_id()\G"
cmd[41]="select * from sys.session;"

cmd[100]="select * from memory_by_user_by_current_bytes;"
cmd[101]="select * from memory_by_host_by_current_bytes;"
cmd[102]="select * from memory_global_by_current_bytes;"
cmd[103]="select * from memory_global_total;"
cmd[104]="select * from sys.memory_by_thread_by_current_bytes;"
cmd[105]="select * from sys.schema_table_lock_waits\G"


#${mysql} -h ${ipaddr} -u ${user} -p${password} -P${port} << EOF
#SOURCE ${sql_version};
#EOF

collect_ps_stats() {
    if [ -z "${cmd_index}" ]  || [ "${cmd_index}" == "all" ] ; then
        index=1
        while [[ ${index} -lt 42 ]] ; 
        do
            exec_mysql_cmd "${cmd[${index}]}"  
            let "index++"
        done    
    else 
        exec_mysql_cmd "${cmd[$cmd_index]}" 
    fi
}


collect_my57_stats() {
    if [ -z "${cmd_index}" ]  || [ "${cmd_index}" == "all" ] ; then
        index=100
        while [[ ${index} -lt 106 ]] ; 
        do
            exec_mysql_cmd "${cmd[${index}]}" 
            let "index++"
        done    
    else 
        exec_mysql_cmd "${cmd[$cmd_index]}" 
    fi
}

if [ x"${cmd_index}" == x"show" ] ; then
   if [ x"${2}" == x"tables" ] ; then
       echo "Display tables in sys database"
       exec_mysql_cmd "show tables"
   elif [ x"${2}" == x"view" ] || [ -z "${2}" ] ; then
       index=0
       while [[ ${index} -lt 42 ]] ; 
       do
          echo "${index}:  ${cmd[$index]}"
          let "index++"
       done              
   else 
       exec_mysql_cmd "${2}"
   fi
   exit 0
fi

echo "Test..."

if [ -z "${mysql_ps_output}" ] ; then
    collect_ps_stats
else
    if [ -f "${mysql_ps_output}" ] ; then
        touch ${mysql_ps_output}
    fi
    collect_ps_stats > "${mysql_ps_output}"
fi

if [ "${mysql_version}" == "5.7" ] ; then
    if [ -z "${mysql_ps_output}" ] ; then
        collect_my57_stats
    else 
        collect_my57_stats >> ${mysql_ps_output}
    fi
fi 

popd > /dev/null

