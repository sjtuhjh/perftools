 SELECT numbackends as CONN, xact_commit as TX_COMM,
xact_rollback as
TX_RLBCK, blks_read + blks_hit as READ_TOTAL,
blks_hit * 100 / (blks_read + blks_hit)
as BUFFER FROM pg_stat_database WHERE datname = 'dvdrental';

 SELECT pg_stat_reset();
