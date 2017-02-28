select datname, age(datfrozenxid) from pg_database order 
by age(datfrozenxid) desc limit 20;
