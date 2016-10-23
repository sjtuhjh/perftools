#!/bin/bash

declare -a event_array
event_num=0
pid=0
pname=""
list_flag=0

#Default 10 seconds
duration=10  

### parse options
while [ -n "$1" ] 
do
    case $1 in
        -e)	event_array[${event_num}]=$2; let "event_num++";  shift 2 ;;
        -pid)	pid=$2;       shift 2 ;;
        -pname) pname=$2;     shift 2 ;;
        ls)     list_flag=1;  shift 1 ;;
        -d)     duration=$2;  shift 2 ;;
        -h|*)	cat <<-END >&2
            USAGE: syscallcount {-e event_id} {-pid PID} {-d seconds} { -pname ProcessName}
                   syscallcount              # count by process name
                         -e               # strace event
                         -pid PID         # trace this PID only
                         -pname name      # trace this process named "name" 
                         -d seconds       # duration time in seconds(default to 10 seconds)
                         ls               # list all trace events
                   eg,
                   syscallcount                       # trace all syscalls for all process 
                   syscallcount -e event              # trace specific event for all process
                   syscallcount -e event -p 123 -d 60 # trace specific event for PID 923 about 60 seconds
                   syscallcount ls                    # list all trace events
	END
        exit 1
    esac
done

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

#Step 1: Mount debugfs for ftrace firstly
MOUNT_DIR="$(pwd)/sysdebug"
UTIL_DIR="$(pwd)/utils"
mkdir -p "${MOUNT_DIR}"
${SUDO_PREFIX} mount -t debugfs nodev ${MOUNT_DIR}

#Step 2: Trace syscall
pushd ${MOUNT_DIR}
cd tracing

if [ ${list_flag} -gt 0 ] ; then
    cat available_events
    exit 0
fi

if [ ${#event_array[@]} -eq 0 ] ; then
    echo "syscalls:*" >> set_event
else 
    for event in ${event_array[@]};
    do
        echo "Tracing event:${event}"
        echo ${event} >> set_event
    done
fi

if [ ${pid} -gt 0 ] ; then
    echo "Tracing pid:${pid}"
    echo "${pid}" >> set_event_pid
fi

#echo function_graph > current_tracer
echo nop > current_tracer

echo > trace
echo 1 > tracing_on
echo "wait for ${duration} seconds ......"
sleep ${duration}
echo 0 > tracing_on

echo "Results:"
python ${UTIL_DIR}/syscallscount.py ./trace ${pname}
popd 

