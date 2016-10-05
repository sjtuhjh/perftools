#!/bin/bash

##########################################################################
# To collect/analysis basic system information before performance analysis
##########################################################################

#10 seconds
interval=10

#Step 1: Load Averages
#
echo "Step1: Print load averages"
uptime

#Step 2: Kernel Errors
echo "Step2: Kernel Errors"
dmesg -T | tail 

#Step 3: overall stats by time
echo "Step3: overall stats by time"
vmstat 1 ${interval}

#Step 4: CPU balance
echo "Step4: CPU balance"
mpstat -P ALL 1 ${interval}

#Step 5: Process usage
echo "Step5: Process uage"
pidstat 1 ${interval}

#Step 6: disk I/O
echo "Step6: disk I/O"
iostat -xz 1 ${interval}

#Step 7: Memory usage
echo "Step7: memory usage"
free -m

#Step 8: network I/O
echo "Step8: network I/O" 
sar -n DEV 1 ${interval}

#Step 9: TCP stats
echo "Step9: TCP stats"
sar -n TCP,ETCP 1 ${interval}

#Step 10: Overview
echo "Step10: Overview"
top -n ${interval}

#Step 11: Collect basic informations
w
last
history
pstree -a 
ps aux
netstat -ntlp
netstat -nulp
netstat -nxlp
htop -n 5

echo "================Hardware==============================================="
lspci
dmidecode
ethtool

echo "================IO ===================================================="
iostat -kx 2  ${interval}
vmstat 2 ${interval}
mpstat 2 ${interval}
dstat --top-io --top-bio 1 ${interval}

echo "================Mount and fs==========================================="
mount
cat /etc/fstab
vgs
pvs
lvs
df -h
lsof +D

echo "=================Kernel, interrupts and network========================"
sysctl -a
cat /proc/interrupts
cat /proc/net/ip_conntrack/*
netstat 1 ${interval}
ss -s

echo "====================System logs ======================================="
dmesg
less /var/log/messages
less /var/log/secure
less /var/log/auth

echo "====================Cron jobs ========================================="
ls /etc/cron* + cat
for user in $(cat /etc/passwd | cut -f1 -d:); do crontab -l -u $user; done

