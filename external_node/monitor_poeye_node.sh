#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 外部ノードのホスト名。monitor_all.conf で設定可能
STRM_SERVER_HOST=${STREAMING_SERVER_HOST:-}
STRM_UNIT_HOST=${STREAMING_UNIT_HOST:-}

notify_and_log() {
    local status="$1"
    local message="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" PO-EYE "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" PO-EYE "${status}" "${message}"
}

ping_check() {
    local host=$1
    if ! ping -c 1 -W 1 "${host}" >/dev/null
    then
        notify_and_log "ERROR" "PING_FAIL HOST=${host}"
        exit 1
    fi

    notify_and_log "OK" "PING_OK HOST=${host}"
}

main() {
    ping_check "${STRM_SERVER_HOST}"
    ping_check "${STRM_UNIT_HOST}"
}

main