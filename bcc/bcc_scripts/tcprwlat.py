#!/usr/bin/python
# @lint-avoid-python-3-compatibility-imports
#
# tcprwlat    Trace TCP active connection and read/write latency (connect).
#               For Linux, uses BCC, eBPF. Embedded C.
#
# USAGE: tcprwlat [-h] [-t] [-p PID]
#
# This uses dynamic tracing of kernel functions, and will need to be updated
# to match kernel changes.
#
# Copyright 2016 Netflix, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")
#
# 19-Feb-2016   Brendan Gregg   Created this.
# 22-Sep-2017   Huang Jinhua  Update previous script to support TCP read/write latency 

from __future__ import print_function
from bcc import BPF
from socket import inet_ntop, AF_INET, AF_INET6
from struct import pack
import argparse
import ctypes as ct
from time import sleep

# arguments
examples = """examples:
    ./tcprwlat                     # trace all TCP latency between read and write pair operations
    ./tcprwlat -p 181              # only trace PID 181
    ./tcprwlat -s                  # trace all TCP latency on server side (default to client side)
    ./tcprwlat -port 8983 -c -i 10 # trace both TCP connection latency and TCP latency between read and write pair operations
                                   # on client side for only port 8983 every 10 seconds
    ./tcprwlat -t 10               # trace last for 10 seconds and exit
"""
parser = argparse.ArgumentParser(
    description="Trace TCP connection and read/write latency",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-pid", "--pid",
    help="trace this PID only")
parser.add_argument("-s", "--server",
    help="trace server side", action="store_true")
parser.add_argument("-port", "--port",
    help="trace server side")
parser.add_argument("-i", "--interval",
    help="trace time interval")
parser.add_argument("-c", "--conn",
    help="trace tcp connection latency", action="store_true")
parser.add_argument("-t", "--time",
    help="trace time interval")

args = parser.parse_args()
debug = 0

# define BPF program
bpf_text = """
#include <uapi/linux/ptrace.h>
#include <net/sock.h>
#include <net/tcp_states.h>
#include <bcc/proto.h>

BPF_HASH(start, struct socket *);
BPF_HASH(conn_start, struct sock *);
BPF_HISTOGRAM(rw_hist);
BPF_HISTOGRAM(conn_hist);

static int filter_port(struct sock *sk, u16 is_server)
{
    u16 dport = 0, sport = 0;
    
    dport = sk->__sk_common.skc_dport;
    dport = ntohs(dport);

    sport = sk->__sk_common.skc_num;

    u16 filter_port = 0;
    if (is_server)
    {   
        filter_port = sport;    
    }   
    else 
    {
        filter_port = dport;
    }

    if (filter_port != FILTER_PORT && FILTER_PORT != 0)
    {
        return 1;
    }

    return 0;
}

static int trace_entry(struct pt_regs *ctx, struct socket *sock, u16 is_server)
{
    if (filter_port(sock->sk, is_server))
    {
        return 0;
    } 

    FILTER_PID

    u64 ts = bpf_ktime_get_ns();
    start.update(&sock, &ts);
    return 0;
};

int trace_exit(struct pt_regs *ctx, struct socket *sock)
{
    // will be in TCP_SYN_SENT for handshake
    if (sock->sk->__sk_common.skc_state == TCP_SYN_SENT)
        return 0;

    // check start and calculate delta
    u64 *infop = start.lookup(&sock);
    if (infop == 0) {
        return 0;   // missed entry or filtered
    }

    u64 old = *infop;
    u64 now = bpf_ktime_get_ns();

    rw_hist.increment(bpf_log2l((now - old)/1000));
    start.delete(&sock);

    return 0;
}

int trace_entry_client(struct pt_regs *ctx, struct socket *sock)
{
    return trace_entry(ctx, sock, 0);
}

int trace_entry_server(struct pt_regs *ctx, struct socket *sock)
{
    return trace_entry(ctx, sock, 1);
}

int trace_connect_entry(struct pt_regs *ctx, struct sock *sk)
{
    u64 now = bpf_ktime_get_ns();

    FILTER_PID

    conn_start.update(&sk, &now);
    return 0;
}

int trace_connect_exit(struct pt_regs *ctx, struct sock *sk)
{
    if (sk->__sk_common.skc_state != TCP_SYN_SENT)
    {
        return 0;
    }

    if (filter_port(sk, 0))
    {
        conn_start.delete(&sk);
        return 0;
    }

    u64 *old_time = conn_start.lookup(&sk);
    if (0 == old_time)
    {
        return 0;
    }

    u64 now = bpf_ktime_get_ns();
    conn_hist.increment(bpf_log2l((now - *old_time)/1000));
    conn_start.delete(&sk);
    return 0;
}
"""

# code substitutions
if args.pid:
    bpf_text = bpf_text.replace('FILTER_PID',
        'if (pid != %s) { return 0; }' % args.pid)
else:
    bpf_text = bpf_text.replace('FILTER_PID', '')

if args.port:
    bpf_text = bpf_text.replace('FILTER_PORT', args.port);
else:
    bpf_text = bpf_text.replace('FILTER_PORT', '0')

if debug:
    print(bpf_text)

# initialize BPF
b = BPF(text=bpf_text)

if args.server:
    b.attach_kprobe(event="sock_recvmsg",fn_name="trace_entry_server")
    b.attach_kprobe(event="sock_sendmsg", fn_name="trace_exit")
else :
    b.attach_kprobe(event="sock_sendmsg",fn_name="trace_entry_client")
    b.attach_kprobe(event="sock_recvmsg", fn_name="trace_exit")

if args.conn:
    b.attach_kprobe(event="tcp_v4_connect", fn_name="trace_connect_entry")
    b.attach_kprobe(event="tcp_v6_connect", fn_name="trace_connect_entry")
    b.attach_kprobe(event="tcp_rcv_state_process", fn_name="trace_connect_exit")

interval=1
if args.interval:
    interval = int(args.interval)

total_time = 0xffff
if args.time:
   total_time = args.time
goto_exit = 0

while True:
    if total_time > 0 and not args.interval:
        sleep(interval)
        goto_exit = 1
    else :
        sleep(interval)
        if args.time:
            total_time = float(total_time) - int(interval)
        if total_time <= 0:
            goto_exit = 1

    print("")
    print("===================================================================================")

    if args.conn:
        print("First Historygram: TCP Connection Lantency")
        b["conn_hist"].print_log2_hist("TCP connection establishment latency in us")
        b["conn_hist"].clear()

    if args.server:
        print("Historygram: Latency between receiving TCP and sending TCP after establishing connection")
    else :
        print("Second Historygram: Latency between sending TCP and receiving TCP after establishing connection")

    b["rw_hist"].print_log2_hist("TCP latency in ms(interval=" + str(int(interval)) +" seconds)")
    b["rw_hist"].clear()
    if goto_exit:
        break
