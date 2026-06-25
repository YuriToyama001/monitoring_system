#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/monitor_network_common.sh"

network_common_init
if ! network_common_validate; then
    network_common_notify_missing network_status
    exit 1
fi

# Physical link status
CARRIER=$(cat "${BASE}/carrier" 2>/dev/null)
# Operational state of the network interface
OPERSTATE=$(cat ${BASE}/operstate 2>/dev/null)

# Check if the carrier is down (no link)
# If the carrier is down, it indicates that the physical link is not established, which could be due to a disconnected cable or a disabled interface. In this case, we notify Redis with an ERROR status and exit the script.
if [ "${CARRIER}" = "0" ]; then
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status ERROR "LINK_DOWN"
fi

# Check the operational state of the network interface
# The operational state can be one of several values, such as "up", "down", "dormant", "lowerlayerdown", "testing", or "unknown". We use a case statement to handle each possible state and notify Redis accordingly.
case "${OPERSTATE}" in
    up)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status OK "LINK_UP"
        ;;
    down)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status ERROR "IF_DOWN"
        ;;
    dormant)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status ERROR "IF_DORMANT"
        ;;
    lowerlayerdown)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status ERROR "LOWER_LAYER_DOWN"
        ;;
    testing)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status ERROR "TESTING"
        ;;
    unknown)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status WARNING "STATE_UNKNOWN"
        ;;
    *)
        "${SCRIPT_DIR}/../notify/notify_redis.sh" network_status WARNING "STATE_${OPERSTATE}"
        ;;
esac
