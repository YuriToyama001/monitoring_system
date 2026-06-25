#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# External node host can be configured via NODE_HOST in monitor_all.conf.
HOST=${NODE_HOST:-172.16.1.151}

if ! ping -c 1 -W 1 "${HOST}" >/dev/null
then
    "${SCRIPT_DIR}/../notify/notify_redis.sh" nodeA ERROR "PING_FAIL"
    exit 1
fi

# if ! curl -fs http://${HOST}:8080/health >/dev/null
# then
#     ${SCRIPT_DIR}/../notify/notify_redis.sh nodeA ERROR "SERVICE_FAIL"
#     exit 1
# fi

${SCRIPT_DIR}/../notify/notify_redis.sh nodeA OK "NORMAL"