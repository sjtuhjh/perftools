select count(tablename)
from pg_tables 
where tablename in
(values('pgstatspack_version'));
