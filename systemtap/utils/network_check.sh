#!/bin/bash

interval=10

#Step 1
sar -n DEV,EDEV 1 ${interval}

#Step 2
sar -n TCP,ETCP 1 ${interval}

#Step 3
cat /etc/resolv.conf

#Step 4
mpstat -P ALL 1 ${interval}

#Step 5
tcpretrans

#Step 6
tcpconnect

#Step 7
tcpaccept

#Step 8
netstat -rnv

#Step 9
check firewall config

#Step 10
netstat -s 
