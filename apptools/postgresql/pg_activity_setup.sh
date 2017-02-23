#!/bin/bash

if [ -f "./pg_activity/pg_activity" ] ; then
    echo "pg_activity has been installed before"
    exit 0
fi

sudo yum install -y python-psycopg2

git clone https://github.com/julmon/pg_activity.git
pushd pg_activity > /dev/null
sudo python setup.py install
popd > /dev/null

