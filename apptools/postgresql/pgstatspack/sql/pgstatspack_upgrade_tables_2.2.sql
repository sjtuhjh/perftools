-- Upgrade pgstatspack schema tables.	
--
-- By uwe.bartels@gmail.com
--

ALTER TABLE pgstatspack_tables
  ADD tbl_size bigint, ADD idx_size bigint;

alter table pgstatspack_database add CONSTRAINT pgstatspack_database_pk primary key (snapid, datid);
alter table pgstatspack_indexes add CONSTRAINT pgstatspack_indexes_pk PRIMARY KEY (snapid, index_name, table_name);
alter table pgstatspack_sequences add CONSTRAINT pgstatspack_sequences_pk PRIMARY KEY (snapid, sequence_schema, sequence_name);
alter table pgstatspack_settings add CONSTRAINT pgstatspack_settings_pk PRIMARY KEY (snapid, name);
alter table pgstatspack_tables add CONSTRAINT pgstatspack_tables_pk PRIMARY KEY (snapid, table_name);

CREATE TABLE pgstatspack_statements
(
  snapid bigint NOT NULL,
  userid oid,
  dbid oid,
  query text,
  calls bigint,
  total_time double precision,
  "rows" bigint
);

CREATE INDEX idx_pgstatspack_statements_snapid ON pgstatspack_statements USING btree (snapid);

CREATE TABLE pgstatspack_version
(
  version varchar(10)
);
insert into pgstatspack_version values('2.2');


