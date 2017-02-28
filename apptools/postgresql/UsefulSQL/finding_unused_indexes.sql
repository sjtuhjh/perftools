SELECT
    relid::regclass AS table, 
    indexrelid::regclass AS index, 
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size, 
    idx_tup_read, 
    idx_tup_fetch, 
    idx_scan
FROM pg_stat_user_indexes 
JOIN pg_index USING (indexrelid) 
WHERE idx_scan = 0 
AND indisunique IS FALSE;

SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS size,(array_agg(idx))[1] AS idx1, (array_agg(idx))[2] AS idx2,(array_agg(idx))[3] AS idx3, (array_agg(idx))[4] AS idx4
FROM (SELECT indexrelid::regclass AS idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'|| coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) AS KEY
FROM pg_index) sub
GROUP BY KEY HAVING count(*)>1
ORDER BY sum(pg_relation_size(idx)) DESC;
