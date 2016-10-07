#!/bin/bash

SUDO_PREFIX="sudo"
if [ "$(whoami)" == "root" ] ; then
    SUDO_PREFIX=""
fi

MOUNT_DIR="$(cd ~; pwd)/sysdebug"
mkdir -p "${MOUNT_DIR}"

${SUDO_PREFIX} mount -t debugfs nodev ${MOUNT_DIR}

echo "cd ${MOUNT_DIR}/tracing directory and begin to enjoy ftrace"
