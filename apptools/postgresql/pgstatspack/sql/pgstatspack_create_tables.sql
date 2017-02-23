SET client_min_messages TO error;
-- Create pgstatspack schema tables.	
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

DROP TABLE if exists pgstatspack_snap;
CREATE TABLE pgstatspack_snap
(
snapid bigint,
ts     timestamp,
description   varchar(255)
);

DROP TABLE if exists pgstatspack_database;
CREATE TABLE pgstatspack_database
(
  snapid bigint NOT NULL,
  datid oid NOT NULL,
  dbnameid int not null,
  numbackends integer,
  xact_commit bigint,
  xact_rollback bigint,
  blks_read bigint,
  blks_hit bigint,
  datname_id integer,
  CONSTRAINT pgstatspack_database_pk PRIMARY KEY (snapid, datid)
);

DROP TABLE if exists pgstatspack_tables;
CREATE TABLE pgstatspack_tables
(
  snapid bigint NOT NULL,
  table_name_id integer,
  seq_scan bigint,
  seq_tup_read bigint,
  idx_scan bigint,
  idx_tup_fetch bigint,
  n_tup_ins bigint,
  n_tup_upd bigint,
  n_tup_del bigint,
  heap_blks_read bigint,
  heap_blks_hit bigint,
  idx_blks_read bigint,
  idx_blks_hit bigint,
  toast_blks_read bigint,
  toast_blks_hit bigint,
  tidx_blks_read bigint,
  tidx_blks_hit bigint,
  tbl_size bigint,
  idx_size bigint,
  CONSTRAINT pgstatspack_tables_pk PRIMARY KEY (snapid, table_name_id)
);

DROP TABLE if exists pgstatspack_indexes;
CREATE TABLE pgstatspack_indexes
(
  snapid bigint NOT NULL,
  index_name_id integer,
  table_name_id integer,
  idx_scan bigint,
  idx_tup_read bigint,
  idx_tup_fetch bigint,
  idx_blks_read bigint,
  idx_blks_hit bigint,
  CONSTRAINT pgstatspack_indexes_pk PRIMARY KEY (snapid, index_name_id, table_name_id)
);

DROP TABLE if exists pgstatspack_sequences;
CREATE TABLE pgstatspack_sequences
(
  snapid bigint NOT NULL,
  sequence_name_id integer,
  seq_blks_read bigint,
  seq_blks_hit bigint,
  CONSTRAINT pgstatspack_sequences_pk PRIMARY KEY (snapid, sequence_name_id)
);

DROP TABLE if exists pgstatspack_settings;
CREATE TABLE pgstatspack_settings
(
  snapid bigint,
  name_id int,
  setting_id int,
  source_id int,
  CONSTRAINT pgstatspack_settings_pk PRIMARY KEY (snapid, name_id)
);

CREATE TABLE pgstatspack_statements
(
  snapid bigint NOT NULL,
  user_name_id integer,
  query_id integer,
  calls bigint,
  total_time double precision,
  "rows" bigint,
  CONSTRAINT pgstatspack_statements_pk PRIMARY KEY (snapid, user_name_id, query_id)
);

CREATE TABLE pgstatspack_functions
(
  snapid bigint NOT NULL,
  funcid oid NOT NULL,
  function_name_id integer,
  calls bigint,
  total_time bigint,
  self_time bigint,
  CONSTRAINT pgstatspack_functions_pk PRIMARY KEY (snapid, funcid)
);

create table pgstatspack_bgwriter
(
  snapid bigint not null,
  checkpoints_timed bigint,
  checkpoints_req bigint,
  buffers_checkpoint bigint,
  buffers_clean bigint,
  maxwritten_clean bigint,
  buffers_backend bigint,
  buffers_alloc bigint,
  CONSTRAINT pgstatspack_bgwriter_pk PRIMARY KEY (snapid)
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

CREATE TABLE pgstatspack_version
(
  version varchar(10)
);

DROP SEQUENCE if exists pgstatspackid;
CREATE SEQUENCE pgstatspackid;

CREATE OR REPLACE VIEW pgstatspack_database_v AS SELECT snapid, datid, name AS datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit
   FROM pgstatspack_database
   JOIN pgstatspack_names ON nameid = dbnameid;

create or replace view pgstatspack_tables_v as
SELECT snapid, name as table_name, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, 
       n_tup_upd, n_tup_del, heap_blks_read, heap_blks_hit, idx_blks_read, 
       idx_blks_hit, toast_blks_read, toast_blks_hit, tidx_blks_read, 
       tidx_blks_hit, tbl_size, idx_size
FROM pgstatspack_tables
JOIN pgstatspack_names on nameid=table_name_id;

create view pgstatspack_indexes_v as
SELECT snapid, n1.name as index_name, n2.name as table_name, idx_scan, idx_tup_read, 
       idx_tup_fetch, idx_blks_read, idx_blks_hit
FROM pgstatspack_indexes
JOIN pgstatspack_names n1 on n1.nameid=index_name_id
JOIN pgstatspack_names n2 on n2.nameid=table_name_id;

create view pgstatspack_sequences_v as
SELECT snapid, name as sequence_name, seq_blks_read, seq_blks_hit
FROM pgstatspack_sequences
JOIN pgstatspack_names on nameid=sequence_name_id;

create view pgstatspack_settings_v as
SELECT snapid, n1.name as name, n2.name as setting, n3.name as source
FROM pgstatspack_settings
JOIN pgstatspack_names n1 on n1.nameid=name_id
JOIN pgstatspack_names n2 on n2.nameid=setting_id
JOIN pgstatspack_names n3 on n3.nameid=source_id;

create view pgstatspack_statements_v as
SELECT snapid, n1.name as user_name, n2.name as query, calls, total_time, "rows"
FROM pgstatspack_statements
JOIN pgstatspack_names n1 on n1.nameid=user_name_id
JOIN pgstatspack_names n2 on n2.nameid=query_id;

create view pgstatspack_functions_v as
SELECT snapid, funcid, n1.name as function_name, calls, total_time, self_time
FROM pgstatspack_functions
JOIN pgstatspack_names n1 on n1.nameid=function_name_id;

insert into pgstatspack_version values('2.3.1');
