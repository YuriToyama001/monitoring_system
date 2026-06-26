#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
THRESHOLD=${MEMORY_THRESHOLD:-90}

get_memory_usage() {
    local total available used
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if [ "$total" -le 0 ]; then
        echo 0
        return
    fi

    used=$((total - available))
    echo $((used * 100 / total))
}

PERCENT=$(get_memory_usage)
STATUS=OK

if [ "$PERCENT" -ge "$THRESHOLD" ]; then
    STATUS=ERROR
fi

"${SCRIPT_DIR}/../notify/notify_redis.sh" memory "${STATUS}" "${PERCENT}"
