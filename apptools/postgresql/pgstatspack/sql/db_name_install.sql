SET client_min_messages TO error;
select datname from pg_database where datname not like 'template0' and datname != 'postgres';
