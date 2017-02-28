logging_collector = on
log_directory = 'pg_log'
log_min_duration_statement = 100

pg_ctl -D $PGDATA restart
