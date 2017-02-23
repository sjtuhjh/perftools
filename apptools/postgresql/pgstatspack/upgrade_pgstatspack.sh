#!/bin/bash

#db call to get database name

CUR_DIR=$(cd `dirname $0`; pwd)
. ${CUR_DIR}/psql_user.sh

PSQL="psql -q --set ON_ERROR_STOP=on ""${PSQL_USER}"

install_stats () {
	set -e
	$PSQL -d "${dbname}" -f "sql/pgstatspack_create_tables.sql"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_create_snap.sql"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_delete_old_stats.sql"
	set +e
}

update_stats_2_2 () {
	set -e
	echo "Upgrading to version 2.2 for database: ${dbname}"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_upgrade_tables_2.2.sql"
	set +e
}

update_stats_2_3 () {
	set -e
	echo "Upgrading to version 2.3 for database: ${dbname}"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_upgrade_tables_2.3.sql"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_create_snap.sql"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_get_unused_indexes.sql"
	set +e
}

update_stats_2_3_1 () {
	set -e
	echo "Upgading to version 2.3 for database: ${dbname}"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_create_snap.sql"
	$PSQL -d "${dbname}" -f "sql/pgstatspack_upgrade_tables_2.3.1.sql"
	set +e
}

for dbname in `$PSQL -t -f "sql/db_name_install.sql"`; do
	echo "Results for database ${dbname}"
	if [ `$PSQL -d "${dbname}" -A -t -c "select count(lanname) from pg_language where lanname='plpgsql';"` -lt 1 ];then 
		echo "Installing language plpgsql for database ${dbname}"
		set -e
		$PSQL -d "${dbname}" -c "create language plpgsql;"	
		set +e
	fi

	x=`$PSQL -A -t -d "${dbname}" -f "sql/pgstats_exist.sql"`
	if [ $x -eq "0" ]; then
		echo "Installing Statistics Package for database ${dbname}"
		install_stats
		continue
	fi

	if [ $x -lt "6" ]; then
		echo "Previous install of statisics package was incomplete. Reinstalling Stats for database ${dbname}"
		install_stats
	fi

	if [ $x -eq "6" ]; then
		update_stats_2_2
	fi

	x=`$PSQL -A -t -d "${dbname}" -f "sql/pgstats_exist_2.2.sql"`
	if [ $x -eq "1" ]; then
		version=`$PSQL -A -t -d "${dbname}" -f "sql/pgstats_version.sql"`
		case ${version} in
			"2.2") update_stats_2_3;;
			"2.3") update_stats_2_3_1;;
			"2.3.1") echo "the current version is already installed in ${dbname}.";;
			*) echo "Unknown version string in table pgstatspack_version for database: ${dbname}";;
		esac
	fi

	x=0
	version=""

	echo ""
done 
