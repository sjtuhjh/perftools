#!/bin/bash

LOCAL_REPO_DIR=$1
REMOTE_REPO_URL=$2

if [ -z "${1}" ] || [ -z "${2}" ] ; then
    echo "Usage: ./git_sync.sh <local repo dir> <remote repo url>"
    exit 1
fi

if [ ! -d "${LOCAL_REPO_DIR}" ] ; then
    echo "Local directory:${LOCAL_REPO_DIR} does not exist!"
    exit 1
fi

pushd ${LOCAL_REPO_DIR} > /dev/null
git remote -v
git remote add upstream ${REMOTE_REPO_URL}
git fetch upstream
git checkout master
git merget upstream/master
git push origin master
popd >/dev/null

