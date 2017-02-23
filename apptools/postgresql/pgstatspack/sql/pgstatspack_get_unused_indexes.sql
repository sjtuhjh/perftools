SET client_min_messages TO error;
-- Function: get_unused_indexes(interval)

DROP FUNCTION if exists get_unused_indexes(interval);

CREATE OR REPLACE FUNCTION get_unused_indexes(IN p_timespan interval)
  RETURNS TABLE(table_name text, index_name text, size text, indexdef text) AS
$BODY$
DECLARE
 l_max_ts timestamp;
 l_snapid_start integer;
 l_snapid_stop integer;
 l_timespan interval := '1 week'; -- default
BEGIN
 -- this function returns the name of the unused indexes and their corresponding table name.
 -- author: ubartels
 -- date: 26/10/2010
 --
 -- prerequsites: pgstatspack
 
 if p_timespan is not null then
  l_timespan = p_timespan;
 end if;
 
 l_max_ts := max(ts) from pgstatspack_snap;
 l_snapid_stop  := snapid from pgstatspack_snap where ts=l_max_ts;
 l_snapid_start := snapid from pgstatspack_snap where ts > l_max_ts - l_timespan order by ts asc limit 1;

 -- check if there is any data
 if l_snapid_start is null or l_snapid_stop is null then
  raise info 'no data found for the timespan of %.',l_timespan;
  return;
 end if;

 -- check if the stats are active or stale
 if l_max_ts < now()-'1 day'::interval then
  raise info 'pgstatspack data is stale (older than 1 day). please get it up and running first.';
  return;
 end if;

 return query
 select a.table_name::text, a.index_name::text ,pg_size_pretty(pg_relation_size(c.oid))::text, pg_get_indexdef(c.oid)::text
 from pg_class c, pg_namespace n, pg_index i, pgstatspack_indexes a, pgstatspack_indexes b
where
 a.snapid=l_snapid_start and 
 b.snapid=l_snapid_stop and
 a.index_name=b.index_name and
 a.table_name=b.table_name and
 (b.idx_scan-a.idx_scan) = 0 and
 (b.idx_tup_read-a.idx_tup_read) = 0 and
 (b.idx_tup_fetch-a.idx_tup_fetch) = 0 and
 a.index_name=n.nspname||'.'||c.relname and
 n.oid=c.relnamespace and
 c.oid=i.indexrelid and
 i.indisprimary is false and
 i.indisunique is false and
 i.indisclustered is false and
 a.index_name not in (select n.nspname||'.'||conname from pg_constraint where contype='f')
order by pg_relation_size(c.oid) desc;

END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE SECURITY DEFINER
  COST 100
  ROWS 1000;
