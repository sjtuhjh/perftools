SET client_min_messages TO error;
-- Upgrade pgstatspack schema tables.	
--
-- By uwe.bartels@gmail.com
--

insert into pgstatspack_version values('2.3');

CREATE TABLE pgstatspack_functions
(
  snapid bigint NOT NULL,
  function_name character varying(256) NOT NULL,
  funcid oid NOT NULL,
  calls bigint,
  total_time bigint,
  self_time bigint,
  CONSTRAINT pgstatspack_functions_pkey PRIMARY KEY (snapid, function_name, funcid)
);

CREATE TABLE pgstatspack_bgwriter(
  snapid bigint not null,
  checkpoints_timed bigint,
  checkpoints_req bigint,
  buffers_checkpoint bigint,
  buffers_clean bigint,
  maxwritten_clean bigint,
  buffers_backend bigint,
  buffers_alloc bigint,
  CONSTRAINT pgstatspack_bgwriter_pkey PRIMARY KEY(snapid)
);

CREATE SEQUENCE pgstatspacknameid
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 2147483647
  START 1
  CACHE 1;

CREATE TABLE pgstatspack_names(
  nameid integer not null default nextval('pgstatspacknameid'::text),
  name text,
  CONSTRAINT pgstatspack_names_pkey PRIMARY KEY (nameid)
);
create unique index idx_pgstatspack_names_name on pgstatspack_names(name);

-- databases
alter table pgstatspack_database add column dbnameid integer;

insert into pgstatspack_names (name) 
select distinct(datname)
from pgstatspack_database
where
 datname not in 
 (select name from pgstatspack_names);

update pgstatspack_database
set dbnameid=n.nameid
from pgstatspack_names n
where datname=n.name;

alter table pgstatspack_database drop column datname;

CREATE OR REPLACE VIEW pgstatspack_database_v AS 
 SELECT snapid, datid, name AS datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit
   FROM pgstatspack_database
   JOIN pgstatspack_names ON nameid = dbnameid;

-- tables
alter table pgstatspack_tables add column table_name_id integer;

insert into pgstatspack_names (name) 
select distinct(table_name)
from pgstatspack_tables
where
 table_name not in 
 (select name from pgstatspack_names);

update pgstatspack_tables
set table_name_id=n.nameid
from pgstatspack_names n
where table_name=n.name;

alter table pgstatspack_tables drop column table_name;

create view pgstatspack_tables_v as
SELECT snapid, name as table_name, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, 
       n_tup_upd, n_tup_del, heap_blks_read, heap_blks_hit, idx_blks_read, 
       idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, 
       tidx_blks_hit, tbl_size, idx_size
FROM pgstatspack_tables
JOIN pgstatspack_names on nameid=table_name_id;

-- indexes
alter table pgstatspack_indexes add column index_name_id integer;
alter table pgstatspack_indexes add column table_name_id integer;

insert into pgstatspack_names (name) 
select distinct(index_name)
from pgstatspack_indexes  
where
 index_name not in 
 (select name from pgstatspack_names);

insert into pgstatspack_names (name) 
select distinct(table_name)
from pgstatspack_indexes  
where
 table_name not in 
 (select name from pgstatspack_names);

update pgstatspack_indexes
set index_name_id=n.nameid
from pgstatspack_names n
where index_name=n.name;

update pgstatspack_indexes
set table_name_id=n.nameid
from pgstatspack_names n
where table_name=n.name;

alter table pgstatspack_indexes drop column index_name;
alter table pgstatspack_indexes drop column table_name;

create view pgstatspack_indexes_v as
SELECT snapid, n1.name as index_name, n2.name as table_name, idx_scan, idx_tup_read, 
       idx_tup_fetch, idx_blks_read, idx_blks_hit
FROM pgstatspack_indexes
JOIN pgstatspack_names n1 on n1.nameid=index_name_id
JOIN pgstatspack_names n2 on n2.nameid=table_name_id;

-- sequences
alter table pgstatspack_sequences add column sequence_name_id integer;

insert into pgstatspack_names (name) 
select distinct(sequence_schema||'.'||sequence_name)
from pgstatspack_sequences
where
 sequence_schema||'.'||sequence_name not in 
 (select name from pgstatspack_names);

update pgstatspack_sequences
set sequence_name_id=n.nameid
from pgstatspack_names n
where sequence_schema||'.'||sequence_name=n.name;

alter table pgstatspack_sequences drop column sequence_schema;
alter table pgstatspack_sequences drop column sequence_name;

create view pgstatspack_sequences_v as
SELECT snapid, name as sequence_name, seq_blks_read, seq_blks_hit
FROM pgstatspack_sequences
JOIN pgstatspack_names on nameid=sequence_name_id;

-- settings
alter table pgstatspack_settings add column name_id integer;
alter table pgstatspack_settings add column setting_id integer;
alter table pgstatspack_settings add column source_id integer;

insert into pgstatspack_names (name) 
select distinct(s."name")
from pgstatspack_settings s
left join pgstatspack_names n on n."name"=s."name"
where
 n."name" is null;

insert into pgstatspack_names (name) 
select distinct(setting)
from pgstatspack_settings s
left join pgstatspack_names n on n."name"=s.setting
where
 n."name" is null;

insert into pgstatspack_names (name) 
select distinct(source)
from pgstatspack_settings s
left join pgstatspack_names n on n."name"=s.source
where
 n."name" is null;

update pgstatspack_settings s
set name_id=n.nameid
from pgstatspack_names n
where s."name"=n."name";

update pgstatspack_settings s
set setting_id=n.nameid
from pgstatspack_names n
where s.setting=n."name";

update pgstatspack_settings s
set source_id=n.nameid
from pgstatspack_names n
where s.source=n."name";

alter table pgstatspack_settings drop column "name";
alter table pgstatspack_settings drop column setting;
alter table pgstatspack_settings drop column source;

create view pgstatspack_settings_v as
SELECT snapid, n1.name as name, n2.name as setting, n3.name as source
FROM pgstatspack_settings
JOIN pgstatspack_names n1 on n1.nameid=name_id
JOIN pgstatspack_names n2 on n2.nameid=setting_id
JOIN pgstatspack_names n3 on n3.nameid=source_id;

-- statements
alter table pgstatspack_statements add column query_id integer;
alter table pgstatspack_statements add column user_name_id integer;

insert into pgstatspack_names (name) 
select distinct(query)
from pgstatspack_statements
where
 query not in 
 (select name from pgstatspack_names);

update pgstatspack_statements
set query_id=n.nameid
from pgstatspack_names n
where query=n.name;

insert into pgstatspack_names (name) 
select distinct(rolname)
from pg_roles
where
 rolname not in 
 (select name from pgstatspack_names);

update pgstatspack_statements
set user_name_id=n.nameid
from pgstatspack_names n, pg_roles r
where userid=r.oid and rolname=n.name;


alter table pgstatspack_statements drop column query;
alter table pgstatspack_statements drop column userid;
alter table pgstatspack_statements drop column dbid;

create view pgstatspack_statements_v as
SELECT snapid, n1.name as user_name, n2.name as query, calls, total_time, "rows"
FROM pgstatspack_statements
JOIN pgstatspack_names n1 on n1.nameid=user_name_id
JOIN pgstatspack_names n2 on n2.nameid=query_id;

-- functions
alter table pgstatspack_functions add column function_name_id integer;

insert into pgstatspack_names (name) 
select distinct(function_name)
from pgstatspack_functions
where
 function_name not in 
 (select name from pgstatspack_names);

update pgstatspack_functions
set function_name_id=n.nameid
from pgstatspack_names n
where function_name=n.name;

alter table pgstatspack_functions drop column function_name;

create view pgstatspack_functions_v as
SELECT snapid, funcid, n1.name as function_name, calls, total_time, self_time
FROM pgstatspack_functions
JOIN pgstatspack_names n1 on n1.nameid=function_name_id;

