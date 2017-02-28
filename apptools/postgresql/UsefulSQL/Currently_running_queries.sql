RECIPE: Finding out what queries users are currently running

track_activities = on

pg_ctl -D $PGDATA reload

SELECT datname, pid, usename, query_start, state, query
FROM pg_stat_activity
