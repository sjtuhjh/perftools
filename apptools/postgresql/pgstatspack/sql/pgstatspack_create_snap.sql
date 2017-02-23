SET client_min_messages TO error;
-- Create pgstatspack_snap procedure.
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

CREATE OR REPLACE FUNCTION pgstatspack_snap ( description varchar(256) ) RETURNS bigint AS $$
DECLARE
  now_dts TIMESTAMP;
  spid BIGINT;
  version_major int;
  version_minor int;
BEGIN
SELECT current_timestamp INTO now_dts; 
  SELECT nextval('pgstatspackid') INTO spid;
  INSERT INTO pgstatspack_snap values (spid, now_dts, description);

insert into pgstatspack_names (name)
select distinct datname
from pg_database
left join pgstatspack_names on datname=name
where
 name is null;

INSERT INTO pgstatspack_database
(snapid, datid, numbackends, xact_commit, xact_rollback, blks_read, blks_hit, dbnameid)
SELECT
  spid               as snapid,
  d.datid            as datid,
  d.numbackends     as numbackends,
  d.xact_commit         as xact_commit,
  d.xact_rollback    as xact_rollback,
  d.blks_read        as blks_read,
  d.blks_hit        as blks_hit,
  n.nameid
FROM
  pg_stat_database d
JOIN pgstatspack_names n on d.datname=n.name
;

insert into pgstatspack_names (name)
select distinct schemaname||'.'||relname
from pg_stat_all_tables
left join pgstatspack_names on schemaname||'.'||relname=name
where
 name is null;

INSERT INTO pgstatspack_tables
( snapid, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, 
  n_tup_upd, n_tup_del, heap_blks_read, heap_blks_hit, idx_blks_read, 
  idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, 
  tidx_blks_hit, tbl_size, idx_size, table_name_id)
SELECT
  spid               as snapid,
  t.seq_scan         as seq_scan,
  t.seq_tup_read     as seq_tup_read,
  t.idx_scan         as idx_scan,
  t.idx_tup_fetch    as idx_tup_fetch,
  t.n_tup_ins        as n_tup_ins,
  t.n_tup_upd        as n_tup_upd,
  t.n_tup_del        as n_tup_del,
  it.heap_blks_read  as heap_blks_read,
  it.heap_blks_hit   as heap_blks_hit,
  it.idx_blks_read   as idx_blks_read,
  it.idx_blks_hit    as idx_blks_hit,
  it.toast_blks_read as toast_blks_read,
  it.toast_blks_hit  as toast_blks_hit,
  it.tidx_blks_read  as tidx_blks_read,
  it.tidx_blks_hit   as tidx_blks_hit,
  pg_relation_size(t.relid)+pg_relation_size(s.relid) as tbl_size,
  sum(pg_relation_size(i.indexrelid)) as idx_size,
  n.nameid
FROM
  pg_statio_all_tables it,
  pg_stat_all_tables t
  JOIN pg_class c on t.relid=c.oid
  LEFT JOIN pg_stat_sys_tables s on c.reltoastrelid=s.relid 
  LEFT JOIN pg_index i on i.indrelid=t.relid
  LEFT JOIN pg_locks l on c.oid=l.relation and locktype='relation' and mode in ('AccessExclusiveLock','ShareRowExclusiveLock','ShareLock','ShareUpdateExclusiveLock')
  JOIN pgstatspack_names n on t.schemaname ||'.'|| t.relname=n.name
WHERE
  l.relation is null and
  (t.relid = it.relid)
GROUP BY
  n.nameid,t.seq_scan,t.seq_tup_read,t.idx_scan,t.idx_tup_fetch,t.n_tup_ins,t.n_tup_upd,t.n_tup_del,it.heap_blks_read,it.heap_blks_hit,it.idx_blks_read,it.idx_blks_hit,it.toast_blks_read,it.toast_blks_hit,it.tidx_blks_read,it.tidx_blks_hit,t.relid,s.relid
;

insert into pgstatspack_names (name)
select distinct i.schemaname ||'.'|| i.indexrelname
from pg_stat_all_indexes i
left join pgstatspack_names on i.schemaname ||'.'|| i.indexrelname=name
where
 name is null;

INSERT INTO pgstatspack_indexes
( snapid, idx_scan, idx_tup_read, idx_tup_fetch, idx_blks_read, 
  idx_blks_hit, index_name_id, table_name_id)
SELECT
  spid               as snapid,
  i.idx_scan         as idx_scan,
  i.idx_tup_read     as idx_tup_read,
  i.idx_tup_fetch    as idx_tup_fetch,
  ii.idx_blks_read   as idx_blks_read,
  ii.idx_blks_hit    as idx_blks_hit,
  n1.nameid,
  n2.nameid
FROM
  pg_stat_all_indexes i
  join pg_statio_all_indexes ii on i.indexrelid = ii.indexrelid
  join pgstatspack_names n1 on i.schemaname ||'.'|| i.indexrelname=n1.name
  join pgstatspack_names n2 on i.schemaname ||'.'|| i.relname=n2.name
;

insert into pgstatspack_names (name)
select distinct s.schemaname ||'.'|| s.relname
from pg_statio_all_sequences s
left join pgstatspack_names on s.schemaname ||'.'|| s.relname=name
where
 name is null;

INSERT INTO pgstatspack_sequences
( snapid, seq_blks_read, seq_blks_hit, sequence_name_id)
SELECT
  spid               as snapid,
  s.blks_read        as seq_blks_read,
  s.blks_hit         as seq_blks_hit,
  n.nameid
FROM
  pg_statio_all_sequences s
  join pgstatspack_names n on s.schemaname ||'.'|| s.relname=n.name
;

insert into pgstatspack_names (name)
select distinct s.name
from pg_settings s
left join pgstatspack_names n on n.name=s.name
where source!='default' and n.name is null;

insert into pgstatspack_names (name)
select distinct s.setting
from pg_settings s
left join pgstatspack_names n on n.name=s.setting
where source!='default' and n.name is null;

insert into pgstatspack_names (name)
select distinct s.source
from pg_settings s
left join pgstatspack_names n on n.name=s.source
where source!='default' and n.name is null;

INSERT INTO pgstatspack_settings
( snapid, name_id, setting_id, source_id)
SELECT
  spid			as snapid,
  n1.nameid,
  n2.nameid,
  n3.nameid
FROM
  pg_settings s
  join pgstatspack_names n1 on s.name=n1.name
  join pgstatspack_names n2 on s.setting=n2.name
  join pgstatspack_names n3 on s.source=n3.name
WHERE
  (s.source != 'default')
;

select cast(substring(version(), 'PostgreSQL ([0-9]*).') as int) into version_major;
select cast(substring(version(), 'PostgreSQL [0-9]*.([0-9]*).') as int) into version_minor;

IF ((version_major = 8 AND version_minor >= 4 ) OR version_major > 8 ) THEN
 BEGIN
  perform relname from pg_class where relname='pg_stat_statements';
  if found then
    begin

      insert into pgstatspack_names (name)
      select distinct query
      from pg_stat_statements
      left join pgstatspack_names on query=name
      where
       dbid=(select oid from pg_database where datname=current_database()) and
       name is null;

      insert into pgstatspack_names (name)
      select pg_get_userbyid(userid)
      from pg_stat_statements
      left join pgstatspack_names on pg_get_userbyid(userid)=name
      where
       dbid=(select oid from pg_database where datname=current_database()) and
       name is null;

    INSERT INTO pgstatspack_statements
    ( snapid, calls, total_time, "rows", query_id, user_name_id)
    SELECT
      spid as snapid,
      s.calls as calls,
      s.total_time as total_time,
      s.rows as rows,
      n1.nameid,
      n2.nameid
    FROM pg_stat_statements s
    join pgstatspack_names n1 on s.query=n.name
    join pgstatspack_names n2 on s.pg_get_userbyid(s.userid)=n2.name
    WHERE dbid=(select oid from pg_database where datname=current_database())
    ORDER BY total_time;

    EXCEPTION WHEN object_not_in_prerequisite_state THEN raise warning '%', SQLERRM;
    end;
  end if;

 END; 
END IF;

IF ((version_major = 8 AND version_minor >= 4 ) OR version_major > 8 ) THEN
 BEGIN

  insert into pgstatspack_names (name)
  select schemaname||'.'||funcname
  from pg_stat_user_functions
  left join pgstatspack_names on schemaname||'.'||funcname=name
  where
   name is null;

  insert into pgstatspack_functions
  ( snapid, funcid, calls, total_time, self_time, function_name_id)
   select
   spid as snapid,
   funcid as funcid,
   calls as calls,
   total_time as total_time,
   self_time as self_time,
   n.nameid
  from
   pg_stat_user_functions
   join pgstatspack_names n on schemaname||'.'||funcname=n.name
  order by total_time
  limit 100;
 END;
END IF;

IF ((version_major = 8 AND version_minor >= 3 ) OR version_major > 8 ) THEN
	insert into pgstatspack_bgwriter select
	spid as snapid,
	checkpoints_timed,
	checkpoints_req,
	buffers_checkpoint,
	buffers_clean,
	maxwritten_clean,
	buffers_backend,
	buffers_alloc
	from pg_stat_bgwriter;
END IF;

RETURN spid;
END;
$$ LANGUAGE plpgsql;

