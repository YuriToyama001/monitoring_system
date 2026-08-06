#!/bin/bash

# ネットワークトラフィックの増加量を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

INTERFACE="${1:-eth0}"

INTERVAL=${NETWORK_TRAFFIC_INTERVAL:-1}
THRESHOLD_PERCENT=${NETWORK_TRAFFIC_THRESHOLD:-80}

BASE="/sys/class/net/${INTERFACE}"

if [ ! -d "${BASE}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic FAITAL "IF_NOT_FOUND:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic FAITAL "IF_NOT_FOUND:${INTERFACE}"
    exit 1  
fi

SPEED=$(cat "${BASE}/speed" 2>/dev/null)

if ! [[ "${SPEED}" =~ ^[0-9]+$ ]]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic FAITAL "SPEED_UNKNOWN:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic FAITAL "SPEED_UNKNOWN:${INTERFACE}"
    exit 1
fi

RX1=$(cat "${BASE}/statistics/rx_bytes")
TX1=$(cat "${BASE}/statistics/tx_bytes")

sleep ${INTERVAL}

RX2=$(cat "${BASE}/statistics/rx_bytes")
TX2=$(cat "${BASE}/statistics/tx_bytes")

RX_BYTES=$((RX2 - RX1))
TX_BYTES=$((TX2 - TX1))

RX_MBPS=$((RX_BYTES * 8 / 1000 / 1000))
TX_MBPS=$((TX_BYTES * 8 / 1000 / 1000))

RX_PERCENT=$((RX_MBPS * 100 / SPEED))
TX_PERCENT=$((TX_MBPS * 100 / SPEED))

MAX_PERCENT=$(( RX_PERCENT > TX_PERCENT ? RX_PERCENT : TX_PERCENT ))
VALUE="RX=${RX_MBPS}Mbps,TX=${TX_MBPS}Mbps:${INTERFACE}"

if [ "${MAX_PERCENT}" -ge "${THRESHOLD_PERCENT}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic ERROR "${VALUE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic ERROR "${VALUE}"
else
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic OK "${VALUE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic OK "${VALUE}"
fi
