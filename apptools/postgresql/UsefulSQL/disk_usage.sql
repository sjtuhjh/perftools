  SELECT pg_size_pretty(pg_database_size('dvdrental')) As fulldbsize;

SELECT
   relname as "Table",
   pg_size_pretty(pg_relation_size(relid)) As " Table Size",
   pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as "Index Size"
   FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;
