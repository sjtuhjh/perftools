#!/bin/bash

function get_thread_list() {
    local cur_proc=${1}
    local thread_list=($(ps -Lf ${cur_proc} | awk '{print $4}' | grep -v LWP))
    local thread_num=${#thread_list[@]}
    local sub_index=0
    local total_index=${thread_num}
    
    if [ ${1} -eq 14286 ] ; then
        echo "subprocess:${1},child:${thread_list[@]}"
    fi

    #echo "thread_list,input=${1},outpu:${thread_list}"

    while [ ${sub_index} -lt ${thread_num} ]
    do
        local thread_id=${thread_list[${sub_index}]}
        let 'sub_index++'

        if [ ${thread_id} -ne ${cur_proc} ] ;  then
            #Thread may also create child threads            
            local child_thread_list=($(get_thread_list ${thread_id}))

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


thread_list=($(get_thread_list $1))

echo ${thread_list[@]}
echo "num=${#thread_list[@]}"

num=${#thread_list[@]}
index=0
while [ ${index} -lt ${num} ] ;
do
    echo "thread:${thread_list[${index}]}"
    let 'index++'

done
