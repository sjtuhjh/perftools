SET client_min_messages TO error;
-- Create pgstatspack schema tables.	
--
-- By frits.hoogland@interaccess.nl
-- Based on Glenn.Fawcett@Sun.com's snap procedure
--

DROP TABLE if exists pgstatspack_snap cascade;

DROP TABLE if exists pgstatspack_database cascade;

DROP TABLE if exists pgstatspack_tables cascade;

DROP TABLE if exists pgstatspack_indexes cascade;

DROP TABLE if exists pgstatspack_sequences cascade;

DROP TABLE if exists pgstatspack_settings cascade;

DROP TABLE if exists pgstatspack_statements cascade;

DROP TABLE if exists pgstatspack_bgwriter cascade;

DROP TABLE if exists pgstatspack_version cascade;

DROP TABLE if exists pgstatspack_functions cascade;

DROP TABLE if exists pgstatspack_names cascade;

DROP SEQUENCE if exists pgstatspackid cascade;

DROP SEQUENCE if exists pgstatspacknameid cascade;

DROP FUNCTION if exists pgstatspack_snap(varchar) cascade;

DROP FUNCTION if exists pgstatspack_delete_snap() cascade;

DROP FUNCTION if exists get_unused_indexes(interval) cascade;
