#!/bin/bash

# ネットワークトラフィックの増加量を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
# 共通関数を読み込む
source "${SCRIPT_DIR}/monitor_network_common.sh"

network_common_init

INTERVAL=${INTERVAL:-1}
THRESHOLD_PERCENT=${NETWORK_TRAFFIC_THRESHOLD:-80}

for target_interface in "${INTERFACES[@]}"; do
    INTERFACE="${target_interface}"
    BASE="/sys/class/net/${INTERFACE}"

    if ! network_common_validate "${INTERFACE}"; then
        network_common_notify_missing network_traffic
        continue
    fi

    SPEED=$(cat "${BASE}/speed" 2>/dev/null)

    if ! [[ "${SPEED}" =~ ^[0-9]+$ ]]; then
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic ERROR "SPEED_UNKNOWN:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic ERROR "SPEED_UNKNOWN:${INTERFACE}"
        continue
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
done
