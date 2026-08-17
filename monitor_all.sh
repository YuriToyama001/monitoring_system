#!/bin/bash

# 監視スクリプトをまとめて実行する統合ランチャー
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
source "${SCRIPT_DIR}/monitor_common.sh"

export INTERFACE
export INTERFACE_1
export INTERFACE_2
export CPU_THRESHOLD
export MEMORY_THRESHOLD
export NETWORK_TRAFFIC_THRESHOLD
export POEYE_HOST
export INTERVAL
export REDIS_HOST
export REDIS_PORT
export NOTIFY_SCRIPT
export LOG_OUTPUT_SCRIPT
export ENABLE_GATEWAY_CHECK
export ENABLE_GATEWAY_CHECK_1
export ENABLE_GATEWAY_CHECK_2

# Run all monitoring scripts
run_script_check "${SCRIPT_DIR}/cpu/monitor_cpu.sh"
run_script_check "${SCRIPT_DIR}/memory/monitor_memory.sh"
run_script_check "${SCRIPT_DIR}/external_node/monitor_external_node.sh"
run_script_check "${SCRIPT_DIR}/network/monitor_network.sh"
