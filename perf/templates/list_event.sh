#!/bin/bash

#list sting all currently known events:
perf list

# Listing sched tracepoints:
perf list 'sched:*'

# Listing sched tracepoints (older syntax):
perf list -e 'sched:*'

