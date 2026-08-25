#!/bin/bash

# ネットワークトラフィックの増加量を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

INTERFACE="${1:-eth0}"
INTERVAL="${NETWORK_TRAFFIC_INTERVAL:-1}"
THRESHOLD_PERCENT="${NETWORK_TRAFFIC_THRESHOLD:-80}"

BASE="/sys/class/net/${INTERFACE}"

notify_and_log() {
    local status="$1"
    local message="$2"

    #OKなら通知しない
    if [ "${status}" = "OK" ]; then return; fi

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_traffic "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_traffic "${status}" "${message}"
}

main() {
    local rx_before tx_before rx_after tx_after
    local rx_bytes tx_bytes rx_mbps tx_mbps
    local rx_percent tx_percent max_percent value
    local SPEED

    if [ ! -d "${BASE}" ]; then
        notify_and_log "FAITAL" "IF_NOT_FOUND IF=${INTERFACE}"
        # インターフェースがない場合、実行エラーとして落とす
        exit 1
    fi

    SPEED=$(cat "${BASE}/speed" 2>/dev/null)

    if ! [[ "${SPEED}" =~ ^[0-9]+$ ]]; then
        notify_and_log "FAITAL" "SPEED_UNKNOWN IF=${INTERFACE}"
        # インターフェースの速度が取得できない場合、実行エラーとして落とす
        exit 1
    fi

    rx_before=$(cat "${BASE}/statistics/rx_bytes")
    tx_before=$(cat "${BASE}/statistics/tx_bytes")

    sleep "${INTERVAL}"

    rx_after=$(cat "${BASE}/statistics/rx_bytes")
    tx_after=$(cat "${BASE}/statistics/tx_bytes")

    rx_bytes=$((rx_after - rx_before))
    tx_bytes=$((tx_after - tx_before))

    rx_mbps=$((rx_bytes * 8 / 1000 / 1000))
    tx_mbps=$((tx_bytes * 8 / 1000 / 1000))

    rx_percent=$((rx_mbps * 100 / SPEED))
    tx_percent=$((tx_mbps * 100 / SPEED))

    max_percent=$(( rx_percent > tx_percent ? rx_percent : tx_percent ))
    value="RX=${rx_mbps}Mbps,TX=${tx_mbps}Mbps IF=${INTERFACE}"

    if [ "${max_percent}" -ge "${THRESHOLD_PERCENT}" ]; then
        notify_and_log "ERROR" "${value}"
        return
    else
        notify_and_log "OK" "${value}"
        return
    fi
}

main
