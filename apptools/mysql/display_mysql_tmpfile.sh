#!/bin/bash

#One tool to display MySql tmp file size every one second 

max_mysql_inst=1
base_tmp_dir="/u01"

if [ $# -gt 0 ] ; then
    max_mysql_inst=${1}
fi

if [ $# -gt 1 ] ; then
    base_tmp_dir=${2}
fi

index=0

echo "Check MySql Tempoary File Size under ${base_tmp_dir} directory ..."

echo "Index  FileSize"
while [[ 1 ]] 
do
    cur_inst=0
    total_size=0
    while [[ ${cur_inst} -lt ${max_mysql_inst} ]]
    do
        tmp_dir="${base_tmp_dir}/u${cur_inst}/my3306/tmp"
        cur_size=($(du -b ${tmp_dir}))
         
        let "total_size += cur_size"
        let "cur_inst++"
    done

    let "total_size=total_size/1024"
    echo "${index}    ${total_size}K"
    sleep 1
    let "index++"
done

