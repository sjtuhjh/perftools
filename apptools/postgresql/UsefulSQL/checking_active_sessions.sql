#RECIPE: Checking active sessions

SELECT pid , usename, application_name, client_addr, client_hostname, query, state FROM pg_stat_activity
WHERE datname='dvdrental';

SELECT datname , procpid, usename,application_name,client_addr, client_hostname,current_query FROM pg_stat_activity;
