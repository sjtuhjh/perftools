select count(tablename)
from pg_tables 
where tablename in
(values('pgstatspack_snap'),('pgstatspack_database'),('pgstatspack_tables'),
('pgstatspack_indexes'),('pgstatspack_sequences'),('pgstatspack_settings'),
('pgstatspack_version'),('pgstatspack_statements'));
