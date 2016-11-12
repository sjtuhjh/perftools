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
    echo "Usage: show_mysql_ps.sh <my_output_file>"
    exit 0
fi

mysql_ps_output=${1}
if [ "${mysql_ps_output:0:1}" != "\/" ] ; then
    mysql_ps_output="$(pwd)/"${mysql_ps_output}
fi

pushd ${mysql_sys_dir} > /dev/null

if [ "${mysql_version}" == "5.6" ] ; then
    sql_version="./sys_56.sql"
else 
    sql_version="./sys_57.sql"
fi

exec_mysql_cmd() {
    ${mysql} -h ${ipaddr} -u ${user} -p${password} --socket=${socket}  -e "${1}" >> ${2}
}

collect_ps_stats() {
${mysql} -h ${ipaddr} -u ${user} -p --socket=${socket} << EOF
SOURCE ${sql_version}; 
select * from sys.version;
select * from innodb_buffer_stats_by_schema;
select * from innodb_buffer_stats_by_table;
select * from innodb_lock_waits \G
select * from schema_object_overview;
select * from schema_auto_increment_columns limit 5;
select * from sys.schema_redundant_indexes\G
select * from ps_check_lost_instrumentation;
select * from latest_file_io;
select * from io_by_thread_by_latency;
select * from io_global_by_file_by_latency;
select * from io_global_by_wait_by_bytes;
select * from memory_by_user_by_current_bytes;
select * from memory_by_host_by_current_bytes;
select * from sys.memory_by_thread_by_current_bytes;
select * from memory_global_by_current_bytes;
select * from memory_global_total;
select * from schema_index_statistics;
select * from schema_table_statistics_with_buffer\G
select * from schema_tables_with_full_table_scans;
select * from schema_unused_indexes;
select * from sys.schema_table_lock_waits\G
select * from statement_analysis\G
select * from statements_with_errors_or_warnings\G
select * from statements_with_full_table_scans\G
select * from statements_with_runtimes_in_95th_percentile;
select * from statements_with_sorting\G
select * from statements_with_temp_tables\G
select * from user_summary_by_file_io_type;
select * from user_summary_by_file_io;
select * from user_summary_by_statement_type;
select * from user_summary_by_statement_latency;
select * from user_summary_by_stages;
select * from user_summary;
select * from host_summary_by_file_io_type;
select * from host_summary_by_file_io;
select * from host_summary_by_statement_type;
select * from host_summary_by_stages;
select * from host_summary;
select * from wait_classes_global_by_avg_latency where event_class != 'idle';
select * from wait_classes_global_by_latency;
select * from waits_by_user_by_latency;
select * from waits_by_host_by_latency;
select * from waits_global_by_latency;
select * from sys.waits_by_host_by_latency where host != 'background';
select * from sys.processlist where conn_id is not null and command != 'daemon' and conn_id != connection_id()\G
select * from sys.session;
select * from session_ssl_status;
exit
EOF
}

collect_ps_stats > ${mysql_ps_output}
popd > /dev/null

