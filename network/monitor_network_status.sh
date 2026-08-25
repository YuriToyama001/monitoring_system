#!/bin/bash

# ネットワークインターフェースの状態を確認するスクリプト
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

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_status "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_status "${status}" "${message}"
}

main() {
    local carrier
    local operstate

    if [ ! -d "${BASE}" ]; then
        notify_and_log "FAITAL" "IF_NOT_FOUND IF=${INTERFACE}"
        # インターフェースがない場合、実行エラーとして落とす
        exit 1
    fi

    carrier=$(cat "${BASE}/carrier" 2>/dev/null)
    operstate=$(cat "${BASE}/operstate" 2>/dev/null)

    if [ "${carrier}" = "0" ]; then
        notify_and_log "ERROR" "LINK_DOWN IF=${INTERFACE}"
        return
    fi

    case "${operstate}" in
        up)
            notify_and_log "OK" "LINK_UP IF=${INTERFACE}"
            return
            ;;
        down)
            notify_and_log "ERROR" "IF_DOWN IF=${INTERFACE}"
            return
            ;;
        dormant)
            notify_and_log "ERROR" "IF_DORMANT IF=${INTERFACE}"
            return
            ;;
        lowerlayerdown)
            notify_and_log "ERROR" "LOWER_LAYER_DOWN IF=${INTERFACE}"
            return
            ;;
        testing)
            notify_and_log "ERROR" "TESTING IF=${INTERFACE}"
            return
            ;;
        unknown)
            notify_and_log "WARNING" "STATE_UNKNOWN IF=${INTERFACE}"
            return
            ;;
        *)
            notify_and_log "WARNING" "STATE_${operstate} IF=${INTERFACE}"
            return
            ;;
    esac
}

main

