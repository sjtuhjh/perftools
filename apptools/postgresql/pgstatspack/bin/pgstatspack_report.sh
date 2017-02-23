#!/bin/bash

#set -x
# pgstatspack report
# version 2.3
# initially by frits hoogland
# enhanced by keith pierno
# 	added help message, error handling, improved input methods
#	added object reports for inserts, deletes, updates, and table to index read
#	fixed divide by zero problem in the reports when objects are recreated
# enhanced by uwe bartels
#	added stats for contrib module pg_stat_statements
#	added stats for bgwriter with formulas by greg smith

# begin enhancements

CUR_DIR=$(cd `dirname $0`; pwd)
. ${CUR_DIR}/../psql_user.sh

PSQL="psql ""${PSQL_USER}"

pushd `dirname $0`

# functions
help_msg (){
	echo ""
	echo "Usage:"
	echo "	pgstatspack_report.sh [-u username] [-d database] [-f filename] [-h]"
	echo "	Generates a statspack style report for a given postgres database"
	echo ""
	echo "	-u username	specifies the database user to connect to the database with"
	echo "	-d database	specifies the database to connect to"
	echo "	-f filename	specifies the filename where the report will be written"
	echo "	-h 		prints this help message"
	echo ""
	exit 0
}

install_stats (){
	$PSQL -U $1 -d $2 -c "\i ../sql/pgstatspack_create_tables.sql"
	$PSQL -U $1 -d $2 -c "\i ../sql/pgstatspack_create_snap.sql"
	echo ""
	echo "Statistics package install for database $2"
	echo "You need to create at least 2 snapshots before running this report."
	exit
}
# end functions

while getopts "u:d:f:h" flag
do
	case $flag in
		u) PGUSER=$OPTARG
			;;
		d) PGDB=$OPTARG
			;;
		f) FILENAME=$OPTARG
			;;
		\?|h) help_msg
			;;
	esac
done

# if no user specified ask operator for username echo "$flag" $OPTIND $OPTARG

if [ $PGUSER"x" == "x" ]
then
	echo "Please specify a username: "
	read username
	PGUSER=$username
fi

# if no db specified present list

if [ $PGDB"x" == "x" ]
then
	array_index=1
	valid_selection=0
	for i in `$PSQL -t -U $PGUSER -c "\i ../sql/db_name.sql"`
	do
		db_array[$array_index]=$i
		array_index=`expr $array_index + 1`
	done
	while [ $valid_selection -eq "0" ]
	do	
		counter=1
		echo "List of available databases:"
		echo ""
		while [ $counter -lt $array_index ]
		do
			echo $counter ".  "${db_array[$counter]}
			counter=`expr $counter + 1`
		done
		echo ""
		echo "Please select a number from the above list [ 1 - " `expr $counter - 1 `" ] "
		read db_selection
		if [ -z "$db_selection" ] ;then
			echo "Please choose the database."
			exit 1
		elif [ `echo "$db_selection"|egrep -c '[^0-9]'` -gt 0 ];then
			echo "Please enter a number for the database."
			exit 1
		elif [ "$db_selection" -lt '1' ] || [ "$db_selection" -ge $counter ];then
			echo "Please enter a valid number from the list."
			exit 1
		else
			valid_selection=1
			PGDB=${db_array[$db_selection]}
		fi
	done
fi

# validate that statspack tables exist for the given database and the user can login
x=`$PSQL -t -U $PGUSER -d $PGDB -c "\i ../sql/pgstats_exist.sql"`
if [ $x -eq "0" ]
then
	echo "The statistics gathering package does not exist for the database: $PGDB"
	echo ""
	echo "Would you like to install the statistics package for $PGDB ? [y|n] "
	read install_answer
	case $install_answer in 
		y|Y) install_stats "$PGUSER" "$PGDB"
			;;
		n|N) echo "Cancelling report"
			exit;;
		*) echo "Invalid answer cancelling report"
			exit;;
	esac
elif [ $x -lt "6" ]
then
	echo "Previous install of statisics package was for database $PGDB is incomplete!"
	echo ""
	echo "Would you like to reinstall the statistics package for $PGDB ? [y|n] "
	read install_answer
	case install_answer in 
		y|Y) install_stats "$PGUSER" "$PGDB"
			;;
		n|N) echo "Cancelling report"
			exit;;
		*) echo "Invalid answer cancelling report"
			exit;;
	esac
fi


# end input enhancements

# generate stats report

$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
select * from pgstatspack_snap order by snapid desc; 
"

printf "Enter start snapshot id : "
read STARTSNAP
printf "Enter stop snapshot id  : "
read STOPSNAP

if [ $FILENAME"x" == "x" ]
then
	FILENAME=/tmp/pgstatreport_${PGDB}_${STARTSNAP}_${STOPSNAP}.txt
fi
echo "Using file name: $FILENAME"

# heading
printf "###########################################################################################################" | tee $FILENAME
printf "\nPGStatspack version 2.3 by uwe.bartels@gmail.com\n" | tee -a $FILENAME
printf "###########################################################################################################\n\n" | tee -a $FILENAME

printf "Snapshot information\n" | tee -a $FILENAME
printf "Begin snapshot : \n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
select b.snapid, b.ts, b.description from pgstatspack_snap b where b.snapid=$STARTSNAP;
" | tee -a $FILENAME
printf "End snapshot   :\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
select e.snapid, e.ts, e.description from pgstatspack_snap e where e.snapid=$STOPSNAP;
" | tee -a $FILENAME
printf "Seconds in snapshot: " | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --tuples-only --command "
select EXTRACT(EPOCH FROM (e.ts-b.ts)) from pgstatspack_snap b, pgstatspack_snap e where b.snapid=$STARTSNAP and e.snapid=$STOPSNAP;
" | tee -a $FILENAME

printf "\nDatabase version\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
select version();
" | tee -a $FILENAME

printf "Database information\n"
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
select current_database(), pg_size_pretty(pg_database_size(current_database())) as dbsize;
" | tee -a $FILENAME

printf "\nDatabase statistics\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.datname as database,
	round(CAST ( ((b.xact_commit-a.xact_commit)/(select EXTRACT(EPOCH FROM (d.ts-c.ts)) from pgstatspack_snap c, pgstatspack_snap d where c.snapid=$STARTSNAP and d.snapid=$STOPSNAP)) AS numeric) ,2) as tps,
	round(CAST ( (100*(b.blks_hit-a.blks_hit)/((b.blks_read-a.blks_read)+(b.blks_hit-a.blks_hit+1))) AS numeric) ,2) as hitrate,
	round(CAST ( (((b.blks_read-a.blks_read)+(b.blks_hit-a.blks_hit))/(select EXTRACT(EPOCH FROM (d.ts-c.ts)) from pgstatspack_snap c, pgstatspack_snap d where c.snapid=$STARTSNAP and d.snapid=$STOPSNAP)) AS numeric) ,2) as lio_ps,
	round(CAST ( ((b.blks_read-a.blks_read)/(select EXTRACT(EPOCH FROM (d.ts-c.ts)) from pgstatspack_snap c, pgstatspack_snap d where c.snapid=$STARTSNAP and d.snapid=$STOPSNAP)) as numeric),2) as pio_ps,
	round(CAST ( ((b.xact_rollback-a.xact_rollback)/(select EXTRACT(EPOCH FROM (d.ts-c.ts)) from pgstatspack_snap c, pgstatspack_snap d where c.snapid=$STARTSNAP and d.snapid=$STOPSNAP)) as numeric) ,2) as rollbk_ps
FROM
	pgstatspack_database_v a,
	pgstatspack_database_v b
WHERE
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	a.datname=b.datname
ORDER BY
	tps desc;
" | tee -a $FILENAME

# get total tuples
TUPLES_TOTAL=$( $PSQL --user $PGUSER --dbname $PGDB --tuples-only --quiet --command "
SELECT
	'aaa',SUM(((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))) as tup,
	SUM(((b.n_tup_ins-a.n_tup_ins)+(b.n_tup_ins-a.n_tup_ins))) as tup_ins,
	SUM(((b.n_tup_upd-a.n_tup_upd)+(b.n_tup_upd-a.n_tup_upd))) as tup_upd,
	SUM(((b.n_tup_del-a.n_tup_del)+(b.n_tup_del-a.n_tup_del))) as n_tup_del
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b on a.table_name=b.table_name
WHERE	a.snapid=$STARTSNAP
AND 	b.snapid=$STOPSNAP
AND	((b.seq_tup_read is not null) and (b.idx_tup_fetch is not null))
AND NOT	( (((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))=0) );
" | grep aaa | awk '{ printf "%d", $3 }' )

# report for table + index size changes
printf "\nTop 20 tables ordered by table size changes\n"| tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
        b.tbl_size-a.tbl_size as table_growth,
        b.idx_size-a.idx_size as index_growth
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
ORDER BY
	abs(b.tbl_size-a.tbl_size) desc
limit 20;
" | tee -a $FILENAME

# new report metric to find tables that are not using or are missing indexes
printf "\nTop 20 tables ordered by high table to index read ratio\n"| tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
	100*((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))/$TUPLES_TOTAL as system_read_pct,
	100*(b.seq_tup_read-a.seq_tup_read)/((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch)) as table_read_pct,
	100*(b.idx_tup_fetch-a.idx_tup_fetch)/((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch)) as index_read_pct
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b  on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	b.seq_tup_read >= a.seq_tup_read
AND	b.idx_tup_fetch >= a.idx_tup_fetch
AND	((b.seq_tup_read is not null) and (b.idx_tup_fetch is not null))
AND NOT	( (((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))<=0) )
ORDER BY
	system_read_pct DESC, table_read_pct DESC
limit 20;
" | tee -a $FILENAME

# added top 20 tables by insert
printf "\nTop 20 tables ordered by inserts\n"| tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
	(b.n_tup_ins-a.n_tup_ins) as table_inserts
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b  on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	b.n_tup_ins >= a.n_tup_ins
ORDER BY
	table_inserts DESC
limit 20;
" | tee -a $FILENAME

# added top 20 tables by update
printf "\nTop 20 tables ordered by updates\n"| tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
	(b.n_tup_upd-a.n_tup_upd) as table_updates
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b  on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	b.n_tup_upd >= a.n_tup_upd
--group by table_updates, a.table_name
ORDER BY
	table_updates DESC
limit 20;
" | tee -a $FILENAME

# added top 20 tables by deletes
printf "\nTop 20 tables ordered by deletes\n"| tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
	(b.n_tup_del-a.n_tup_del) as table_deletes
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b  on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	b.n_tup_del >= a.n_tup_del
--group by table_deletes, a.table_name
ORDER BY
	table_deletes DESC
limit 20;
" | tee -a $FILENAME

printf "\nTables ordered by percentage of tuples scanned\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.table_name as table,
	100*((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))/$TUPLES_TOTAL as rows_read_pct,
	100*(b.heap_blks_hit-a.heap_blks_hit)/((b.heap_blks_hit-a.heap_blks_hit)+((b.heap_blks_read-a.heap_blks_read))+1) as tab_hitrate,
	100*(b.idx_blks_hit-a.idx_blks_hit)/((b.idx_blks_hit-a.idx_blks_hit)+((b.idx_blks_read-a.idx_blks_read))+1) as idx_hitrate,
	(b.heap_blks_read-a.heap_blks_read) as tab_read,
	(b.heap_blks_hit-a.heap_blks_hit) as tab_hit,
	(b.idx_blks_read-a.idx_blks_read) as idx_read,
	(b.idx_blks_hit-a.idx_blks_hit) as idx_hit
FROM
	pgstatspack_tables_v a
	join pgstatspack_tables_v b  on a.table_name=b.table_name
WHERE 
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND	b.heap_blks_hit >= a.heap_blks_hit
AND	b.idx_blks_hit >= a.idx_blks_hit
AND	b.heap_blks_read >= a.heap_blks_read
AND	b.idx_blks_read >= a.idx_blks_read
AND	((b.seq_tup_read is not null) and (b.idx_tup_fetch is not null))
AND NOT	( (((b.seq_tup_read-a.seq_tup_read)+(b.idx_tup_fetch-a.idx_tup_fetch))<=0) )
ORDER BY
	rows_read_pct DESC;
" | tee -a $FILENAME

printf "\nIndexes ordered by scans\n"  | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	a.index_name as index,
	a.table_name as table,
	(b.idx_scan-a.idx_scan) as scans,
	(b.idx_tup_read-a.idx_tup_read) as tup_read,
	(b.idx_tup_fetch-a.idx_tup_fetch) as tup_fetch,
	(b.idx_blks_read-a.idx_blks_read) as idx_blks_read,
	(b.idx_blks_hit-a.idx_blks_hit) as idx_blks_hit
FROM
	pgstatspack_indexes_v a
	join pgstatspack_indexes_v b on a.index_name=b.index_name and a.table_name=b.table_name
WHERE
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND NOT(
	((b.idx_blks_read-a.idx_blks_read)<=0)     and ((b.idx_blks_hit-a.idx_blks_hit)<=0)  and
	((b.idx_tup_read-a.idx_tup_read)<=0) and ((b.idx_tup_fetch-a.idx_tup_fetch)<=0) )
ORDER BY
	scans DESC;
" | tee -a $FILENAME

printf "\nSequences ordered by blks_read\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT 
	a.sequence_name as sequence,
	(b.seq_blks_read-a.seq_blks_read) as blks_read,
        (b.seq_blks_hit-a.seq_blks_hit) as blks_hit
FROM
	pgstatspack_sequences_v a
	join pgstatspack_sequences_v b on a.sequence_name=b.sequence_name
WHERE
	a.snapid=$STARTSNAP
AND	b.snapid=$STOPSNAP
AND NOT (
	((b.seq_blks_read-a.seq_blks_read)=0) and ((b.seq_blks_hit-a.seq_blks_hit)=0))
ORDER BY
	blks_read DESC;
" | tee -a $FILENAME

printf "\nTop 20 SQL statements ordered by total_time\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	b.calls-coalesce(a.calls,0) as calls,
	(b.total_time-coalesce(a.total_time,0))::numeric(10,3) as total_time,
	((b.total_time-coalesce(a.total_time,0))*100/sum.total_time)::numeric(10,2) as total_time_percent,
	b.rows-coalesce(a.rows,0) as rows,
	b.user_name as user,
	b.query as query
FROM
	pgstatspack_statements_v a
	right join pgstatspack_statements_v b on a.user_name=b.user_name and a.query=b.query,
	(
	 select
	  sum(sb.calls-sa.calls) as calls,
	  sum(sb.total_time-sa.total_time) as total_time,
	  sum(sb.rows-sa.rows) as rows 
	 from pgstatspack_statements sa
	 right join pgstatspack_statements sb on sa.user_name_id=sb.user_name_id and sa.query_id=sb.query_id
	) as sum
WHERE
	a.snapid = $STARTSNAP and
	b.snapid = $STOPSNAP
ORDER BY total_time desc
LIMIT 20;
" | tee -a $FILENAME

printf "\nTop 20 user functions ordered by total_time\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	b.funcid,
	b.function_name,
	b.calls-coalesce(a.calls,0) as calls,
	(b.total_time-coalesce(a.total_time,0))::numeric(10,3) as total_time,
	(b.self_time-coalesce(a.self_time,0))::numeric(10,3) as self_time
FROM
	pgstatspack_functions_v a
	right join pgstatspack_functions_v b on a.funcid=b.funcid
WHERE
	a.snapid = $STARTSNAP and
	b.snapid = $STOPSNAP
ORDER BY self_time desc
LIMIT 20;
" | tee -a $FILENAME

printf "\nbackground writer stats\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	b.checkpoints_timed-a.checkpoints_timed as checkpoints_timed,
	b.checkpoints_req-a.checkpoints_req as checkpoints_req,
	b.buffers_checkpoint-a.buffers_checkpoint as buffers_checkpoint,
	b.buffers_clean-a.buffers_clean as buffers_clean,
	b.maxwritten_clean-a.maxwritten_clean as maxwritten_clean,
	b.buffers_backend-a.buffers_backend as buffers_backend,
	b.buffers_alloc-a.buffers_alloc as buffers_alloc
FROM
	pgstatspack_bgwriter a,
	pgstatspack_bgwriter b
WHERE
	a.snapid=$STARTSNAP
AND     b.snapid=$STOPSNAP;
" | tee -a $FILENAME

printf "\nbackground writer relative stats\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
    (b.checkpoints_timed-a.checkpoints_timed)*100/nullif(b.checkpoints_timed-a.checkpoints_timed+b.checkpoints_req-a.checkpoints_req,0)||'%' as checkpoints_timed,
    (extract(epoch from (sb.ts-sa.ts))/nullif(b.checkpoints_timed-a.checkpoints_timed+b.checkpoints_req-a.checkpoints_req,0)/60)::integer as minutes_between_checkpoint,
    (100*(b.buffers_checkpoint-a.buffers_checkpoint)/nullif((b.buffers_checkpoint-a.buffers_checkpoint)+(b.buffers_clean-a.buffers_clean)+(b.buffers_backend-a.buffers_backend),0))||'%' as buffers_checkpoint,
    (100*(b.buffers_clean-a.buffers_clean)/nullif((b.buffers_checkpoint-a.buffers_checkpoint)+(b.buffers_clean-a.buffers_clean)+(b.buffers_backend-a.buffers_backend),0))||'%' as buffers_clean,
    (100*(b.buffers_backend-a.buffers_backend)/nullif((b.buffers_checkpoint-a.buffers_checkpoint)+(b.buffers_clean-a.buffers_clean)+(b.buffers_backend-a.buffers_backend),0))||'%' as buffers_backend,
    ((((b.buffers_checkpoint-a.buffers_checkpoint)+(b.buffers_clean-a.buffers_clean)+(b.buffers_backend-a.buffers_backend))/nullif(extract(epoch from (sb.ts-sa.ts)),0))*8/1024)::numeric(10,3)||' MB/s' as total_writes,
    (((b.buffers_checkpoint-a.buffers_checkpoint)/nullif((b.checkpoints_timed-a.checkpoints_timed)+(b.checkpoints_req-a.checkpoints_req),0)*8/1024)::numeric(10,3))||' MB' as avg_checkpoint_write
FROM
        pgstatspack_bgwriter a,
        pgstatspack_bgwriter b,
        pgstatspack_snap sa,
        pgstatspack_snap sb
WHERE
        a.snapid=$STARTSNAP
AND     b.snapid=$STOPSNAP
AND     a.snapid=sa.snapid
AND     b.snapid=sb.snapid;
" | tee -a $FILENAME

printf "\nParameters\n" | tee -a $FILENAME
$PSQL --user $PGUSER --dbname $PGDB --quiet --command "
SELECT
	so.name as name,
	sa.setting as start_setting,
	so.setting as stop_setting,
	sa.source as source
FROM
	pgstatspack_settings_v so
LEFT OUTER JOIN 
	pgstatspack_settings_v sa ON ( so.name=sa.name )
WHERE
	sa.snapid=$STARTSNAP
AND	so.snapid=$STOPSNAP;
" | tee -a $FILENAME

printf "\nThis report is saved as $FILENAME\n\n"

popd
