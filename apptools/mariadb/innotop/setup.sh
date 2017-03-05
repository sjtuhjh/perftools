#!/bin/bash

yum install -y perl-DBI 
yum install -y perl-DBD-MySQL perl-DBD-Pg

perl Makefile.PL
make
make install
