--
-- PostgreSQL database dump: examples.sql
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

CREATE SCHEMA example;

SET search_path = example;

SET default_tablespace = '';

SET default_with_oids = false;

DROP TABLE IF EXISTS cust;
CREATE TABLE cust (
    customerid integer,
    firstname character varying(50),
    lastname character varying(50),
    age smallint
);

DROP TABLE IF EXISTS ord;
CREATE TABLE ord (
    orderid integer,
    customerid integer,
    amt numeric(12,2)
);


COPY cust (customerid, firstname, lastname, age) FROM stdin;
1	VKUUXF	ITHOMQJNYX	55
2	HQNMZH	UNUKXHJVXB	80
3	JTNRNB	LYYSHTQJRE	47
4	XMFYXD	WQLQHUHLFE	47
5	PGDTDU	ETBYBNEGUT	21
\.


COPY ord (orderid, customerid, amt) FROM stdin;
10677	2	5.50
5019	3	277.44
9748	3	77.17
\.

--
-- PostgreSQL database dump complete
--

