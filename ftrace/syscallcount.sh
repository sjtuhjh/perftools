#!/bin/bash

declare -a event_array
event_num=0
pid=0
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
            USAGE: syscallcount {-e event_id} {-pid PID} {-d seconds}
                   syscallcount              # count by process name
                         -e               # strace event
                         -pid PID         # trace this PID only
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

#Function: to get all thread id which belong to the specified process id
get_thread_list() {
    local cur_proc=${1}
    local thread_list=($(ps -Lf ${cur_proc} | awk '{print $4}' | grep -v LWP))
    local thread_num=${#thread_list[@]}
    local sub_index=0
    local total_index=${thread_num}

    while [ ${sub_index} -lt ${thread_num} ]
    do
        local thread_id=${thread_list[${sub_index}]}
        let 'sub_index++'
        
        if [ ${thread_id} -ne ${cur_proc} ] ;  then
            #Thread may also create child threads            
            local child_thread_list=$(get_thread_list ${thread_id})
            
            for sub_thread_id in ${child_thread_list[@]} 
            do
                if [ ${sub_thread_id} -ne ${thread_id} ] ; then
                    thread_list[${total_index}]=${sub_thread_id}
                    let 'total_index++'          
                fi
            done
        fi
    done
    echo ${thread_list[@]}
}

#Step 1: Mount debugfs for ftrace firstly
MOUNT_DIR="$(pwd)/sysdebug"
UTIL_DIR="$(pwd)/utils"
mkdir -p "${MOUNT_DIR}"
${SUDO_PREFIX} mount -t debugfs nodev ${MOUNT_DIR}

#Step 2: Trace syscall
pushd ${MOUNT_DIR} > /dev/null
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

echo > set_ftrace_pid
if [ ${pid} -gt 0 ] ; then
    thread_list=($(get_thread_list ${pid}))
    for thread_id in ${thread_list[@]}
    do 
        echo "Tracing sub-thread:${thread_id}"
        echo "${thread_id}" >> set_ftrace_pid
    done
    
    echo "Tracing pid:${pid} including ${#thread_list[@]} threads"
fi

#echo function_graph > current_tracer
echo nop > current_tracer

echo > trace
echo 1 > tracing_on
echo "wait for ${duration} seconds ......"
sleep ${duration}
echo 0 > tracing_on

echo "Results:"
python ${UTIL_DIR}/syscallscount.py ./trace
popd > /dev/null 
echo "Trace log:${MOUNT_DIR}/tracing"
echo "====================================== Done ============================================="
