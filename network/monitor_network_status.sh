#!/bin/bash

# ネットワークインターフェースの状態を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

INTERFACE="${1:-eth0}"

BASE="/sys/class/net/${INTERFACE}"

if [ ! -d "${BASE}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status FAITAL "IF_NOT_FOUND:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status FAITAL "IF_NOT_FOUND:${INTERFACE}"
    exit 1
fi

# Physical link status
CARRIER=$(cat "${BASE}/carrier" 2>/dev/null)
# Operational state of the network interface
OPERSTATE=$(cat "${BASE}/operstate" 2>/dev/null)

# Check if the carrier is down (no link)
# If the carrier is down, it indicates that the physical link is not established, which could be due to a disconnected cable or a disabled interface. In this case, we notify Redis with an ERROR status and exit the script.
if [ "${CARRIER}" = "0" ]; then
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status ERROR "LINK_DOWN:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status ERROR "LINK_DOWN:${INTERFACE}"
fi

# Check the operational state of the network interface
# The operational state can be one of several values, such as "up", "down", "dormant", "lowerlayerdown", "testing", or "unknown". We use a case statement to handle each possible state and notify Redis accordingly.
case "${OPERSTATE}" in
    up)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status OK "LINK_UP:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status OK "LINK_UP:${INTERFACE}"
        ;;
    down)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status ERROR "IF_DOWN:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status ERROR "IF_DOWN:${INTERFACE}"
        ;;
    dormant)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status ERROR "IF_DORMANT:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status ERROR "IF_DORMANT:${INTERFACE}"
        ;;
    lowerlayerdown)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status ERROR "LOWER_LAYER_DOWN:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status ERROR "LOWER_LAYER_DOWN:${INTERFACE}"
        ;;
    testing)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status ERROR "TESTING:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status ERROR "TESTING:${INTERFACE}"
        ;;
    unknown)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status WARNING "STATE_UNKNOWN:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status WARNING "STATE_UNKNOWN:${INTERFACE}"
        ;;
    *)
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status WARNING "STATE_${OPERSTATE}:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status WARNING "STATE_${OPERSTATE}:${INTERFACE}"
        ;;
esac

