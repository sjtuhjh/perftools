select datname from pg_database where datname not like 'template%' and datname != 'postgres';
