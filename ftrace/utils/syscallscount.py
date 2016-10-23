#!/usr/bin/python
#-*-encoding:utf-8-*-

import os
import sys
import collections
import string

"""
    One tool to count the number of syscalls 
    Usage: syscallscount.py <ftrace log> 
"""

def syscallcount(tracelog_name):
    filehandle = open(tracelog_name)
    
    syscall_dict = collections.defaultdict(dict)
     
    for line in filehandle:
        if line[0] == '#':
            continue
        
        elems = line.strip().split(' ')
        while elems[1][0:1] != "[":
            elems[1]=elems[0].strip()+elems[1].strip()
            del elems[0]
                  
        for index in range(len(elems)) :
            elems[index] = elems[index].strip()

        strindex = elems[0].rfind('-')
        taskname = elems[0][:strindex]
        pid = elems[0][strindex+1:]
        
        syscall_dict[pid]["name"] = taskname

        cpuid = elems[1].strip()[1:-2]
        timestamp = string.atof(elems[3][:-2])
        
        name_index = elems[4].strip().find('(')
        input_output=""
        if name_index >= 0 :
            syscall_name = elems[4][:name_index]
            syscall_input = elems[4][name_index+1:-2]
            input_output="input"
        elif len(elems) >= 7 and elems[5] == "->":
            syscall_name = elems[4]
            syscall_output = elems[6]
            input_output="output"
        else :
            print("Ignore invalid:%s"%line)
            continue
         
        if not syscall_dict[pid].has_key(syscall_name):
            syscall_dict[pid][syscall_name] = collections.defaultdict(dict)
        
        if not syscall_dict[pid][syscall_name].has_key(input_output):
            syscall_dict[pid][syscall_name][input_output] = collections.defaultdict(dict)
        
        syscall_dict[pid][syscall_name][input_output]["num"] = syscall_dict[pid][syscall_name][input_output].get("num", 0) + 1
        
        if not syscall_dict[pid][syscall_name][input_output].has_key("timestamp") : 
            syscall_dict[pid][syscall_name][input_output]["timestamp"] = []

        if input_output == "input" :
            syscall_dict[pid][syscall_name][input_output]["timestamp"].append(timestamp)
        else :
            if not syscall_dict[pid][syscall_name]["input"].has_key("timestamp") :

                #print("ignore error:%s"%line.strip())
                continue
            
            if len(syscall_dict[pid][syscall_name]["input"]["timestamp"]) == 0:
                continue

            old_input_time = syscall_dict[pid][syscall_name]["input"]["timestamp"].pop(0)
            
            #convert second to ms
            timediff = (float(timestamp) - float(old_input_time)) * 1000

            if not syscall_dict[pid][syscall_name].has_key("delay") : 
                syscall_dict[pid][syscall_name]["delay"] = []

            syscall_dict[pid][syscall_name]["delay"].append(timediff)
   
    print("%12s %10s %18s %12s %12s %12s %12s"%("TASK".ljust(12), "PID/TID".ljust(10), "SyscallName".ljust(18), "Enter Num".ljust(12), "Exit Num".ljust(12), "AvgDelay(ms)".ljust(12), "MaxDelay(ms)".ljust(12)))    
    for pidkey in syscall_dict.keys():
        for syscall_key in syscall_dict[pidkey].keys():
            total_delay = 0.0
            max_delay = 0.0

            if syscall_key == "name" :
                continue            

            if not syscall_dict[pidkey][syscall_key].has_key("input") :
                continue
            
            if not syscall_dict[pidkey][syscall_key]["input"].has_key("num") :
                continue

            delay_len = len(syscall_dict[pidkey][syscall_key]["delay"]) 
            for index in range(delay_len) :
                cur_delay = syscall_dict[pidkey][syscall_key]["delay"][index]
                total_delay += float(cur_delay)
                if float(cur_delay) > max_delay:
                    max_delay = cur_delay
            avg_delay = -1.0
            if delay_len != 0:
                avg_delay = total_delay / delay_len
            
            input_num = syscall_dict[pidkey][syscall_key]["input"].get("num", 0)
            output_num = syscall_dict[pidkey][syscall_key]["output"].get("num", 0)
          
            input_num = str(input_num)
            output_num = str(output_num)
            avg_delay = str(float('%.6f'%avg_delay))
            max_delay = str(float("%.6f"%max_delay))

            print("%12s %10s %18s %12s %12s %12s %12s"%(syscall_dict[pidkey]["name"][0:12].ljust(12), pidkey.ljust(10), syscall_key.ljust(18), input_num.ljust(12), output_num.ljust(12), avg_delay.ljust(12), max_delay.ljust(12)))  


if __name__ == "__main__":
    if len(sys.argv) < 2 :
        print("Usage:syscallcount.py <ftrace log>")
    else : 
        tracelog_name = sys.argv[1]
        syscallcount(tracelog_name)

