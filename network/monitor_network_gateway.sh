#!/bin/bash

# デフォルトゲートウェイへの疎通を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

INTERFACE="${1:-eth0}"
BASE="/sys/class/net/${INTERFACE}"

notify_and_log() {
    local status="$1"
    local message="$2"

    #OKなら通知しない
    if [ "${status}" = "OK" ]; then return; fi

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway "${status}" "${message}"
}

main() {
    local gateway

    if [ ! -d "${BASE}" ]; then
        notify_and_log "FAITAL" "IF_NOT_FOUND IF=${INTERFACE}"
        exit 1
    fi

    gateway=$(ip route show default dev "${INTERFACE}" | awk '/default/ {print $3; exit}')

    if [ -z "${gateway}" ]; then
        notify_and_log "FAITAL" "GATEWAY_NOT_FOUND IF=${INTERFACE}"
        exit 1
    fi

    if ping -c 1 -W 1 "${gateway}" >/dev/null 2>&1; then
        notify_and_log "OK" "GATEWAY=${gateway} IF=${INTERFACE}"
        return
    else
        notify_and_log "ERROR" "PING_FAILED:GATEWAY=${gateway} IF=${INTERFACE}"
        return
    fi
}

main
