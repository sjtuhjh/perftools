#!/bin/bash

perf stat -e task-clock,cycles,instructions,cache-references,cache-misses,cs,migrations $@
