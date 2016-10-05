#!/bin/bash

stap -p2 -e 'probe kernel.function("*") {} ' 2>&1 | grep ^kernel.fun

