#!/bin/bash
#
# Copyright (C) 2017 MET Norway. widow-singleton.sh is licensed under GPL
# version 2 or (at your option) any later version.
#
# Avoid spawning too fast, but kill previous job and run if the previos job
# started more than KILL_PREV_AFTER_SECONDS.

LOCKFILE=$1
KILL_PREV_AFTER_SECONDS=$2
SCRIPT=$3

function usage {
    echo "Usage: $0 LOCKFILE KILL_PREV_AFTER_SECONDS SCRIPT" >> /dev/stderr
    echo "       LOCKFILE file to lock, e.g. /tmp/file.lock" >> /dev/stderr
    echo "       KILL_PREV_AFTER_SECONDS integer, e.g. 10 for 10 seconds" >> /dev/stderr
    echo "       SCRIPT path to script to run, or escaped command, e.g. \"sleep 10\"" >> /dev/stderr
}

if [[ -z "${LOCKFILE}" ]]; then
    echo "Missing LOCKFILE parameter. Don't know which file to lock..." >>/dev/stderr
    usage
    exit 1
fi

if [[ -z "${KILL_PREV_AFTER_SECONDS}" ]]; then
    echo "Missing KILL_PREV_AFTER_SECONDS parameter. Don't know if the previous run has been running for too long, or not..." >>/dev/stderr
    usage
    exit 1
fi
if [[ -z "${SCRIPT}" ]]; then
    echo "Missing SCRIPT parameter. Don't know what to run..." >>/dev/stderr
    usage
    exit 1
fi

if [ "${KILL_PREV_AFTER_SECONDS}" != "EXCL" ]; then
    re='^[0-9]+$'
    if ! [[ "${KILL_PREV_AFTER_SECONDS}" =~ $re ]] ; then
        echo "KILL_PREV_AFTER_SECONDS parameter is not integer." >>/dev/stderr
        usage
        exit 1
    fi

    touch -a "${LOCKFILE}"  # create if not existing, but do not change mtime
    LAST_MODIFIED=$(stat --format %Y "${LOCKFILE}" 2>/dev/null)
    if [ "$?" -ne "0" ]; then
        echo "Failed to stat ${LOCKFILE}" >>/dev/stderr
        exit 2
    fi
    NOW=$(date +%s)
    if [ $((${NOW} - ${LAST_MODIFIED})) -gt ${KILL_PREV_AFTER_SECONDS} ]; then
        lslocks --notruncate | awk "\$9==\"${LOCKFILE}\" {print \$2}" | xargs --no-run-if-empty pkill -g
    fi
    setsid flock --nonblock "${LOCKFILE}" $0 "${LOCKFILE}" EXCL "${SCRIPT}"
else
    touch "${LOCKFILE}"  # update mtime to indicate when the lock was aquired
    ${SCRIPT}
fi
