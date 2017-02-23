#!/bin/bash

#db call to get database name

CUR_DIR=$(cd `dirname $0`; pwd)
. ${CUR_DIR}/psql_user.sh

PSQL="psql -q --set ON_ERROR_STOP=on ""${PSQL_USER}"

remove_stats () {
	set -e
	$PSQL -d "${dbname}" -f "sql/pgstatspack_remove_tables.sql"
	set +e
}

for dbname in `$PSQL -t -f "sql/db_name_install.sql"`
do
	echo "Removing Statistics Package for database ${dbname}"
	remove_stats
done 
