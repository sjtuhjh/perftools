#!/bin/bash

yum install -y psycopg2
yum install -y curses

git clone https://github.com/zalando/pg_view.git 

pushd pg_view > /dev/null

sudo python setup.py install

popd > /dev/null
