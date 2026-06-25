#!/bin/bash
set -euo pipefail

# Unified monitoring launcher for existing monitoring scripts.
# Configuration values are loaded from monitor_all.conf.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONF_FILE="${SCRIPT_DIR}/monitor_all.conf"

if [ ! -f "${CONF_FILE}" ]; then
    echo "Config file not found: ${CONF_FILE}" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "${CONF_FILE}"

export INTERFACE
export CPU_THRESHOLD
export MEMORY_THRESHOLD
export NETWORK_TRAFFIC_THRESHOLD
export NODE_HOST
export INTERVAL
export REDIS_HOST
export REDIS_PORT

# Function to run a monitoring script and handle errors
run_check() {
    local script="$1"

    if [ ! -f "${script}" ]; then
        echo "Missing script: ${script}" >&2
        return 1
    fi

    "${script}" || echo "Warning: ${script} exited with status $?" >&2
}

run_check "${SCRIPT_DIR}/monitor_cpu.sh"
run_check "${SCRIPT_DIR}/monitor_memory.sh"
run_check "${SCRIPT_DIR}/monitor_external_node.sh"
run_check "${SCRIPT_DIR}/monitor_network.sh"
run_check "${SCRIPT_DIR}/monitor_network_traffic.sh"
