#!/bin/bash

# PLCノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# PLCノードのホスト名。monitor_all.conf で設定可能
PLC_HOST=${PLC_HOST:-}
PLC_PORT=${PLC_PORT:-}

notify_and_log() {
    local status="$1"
    local message="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" PLC "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" PLC "${status}" "${message}"
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

port_check() {
    local host=$1
    local port=$2
    if ! nc -z -w 1 "${host}" "${port}" >/dev/null
    then
        notify_and_log "ERROR" "PORT_FAIL HOST=${host} PORT=${port}"
        exit 1
    fi

    notify_and_log "OK" "PORT_OK HOST=${host} PORT=${port}"
}

main() {
    ping_check "${PLC_HOST}"
    port_check "${PLC_HOST}" "${PLC_PORT}"
}

main