#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 外部ノードのホスト名。monitor_all.conf で設定可能
MTCH_SERVER_HOST=${MATCHING_SERVER_HOST:-}
MTCH_SERVER_PORT=${MATCHING_SERVER_PORT:-}

notify_and_log() {
    local status="$1"
    local message="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" MATCHING-SERVER "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" MATCHING-SERVER "${status}" "${message}"
}

ping_check() {
    local host=$1
    if ! ping -c 1 -W 1 "${host}" >/dev/null
    then
        notify_and_log "ERROR" "PING_FAIL HOST=${host}"
        return
    fi

    notify_and_log "OK" "PING_OK HOST=${host}"
    return
}

port_check() {
    local host=$1
    local port=$2
    if ! nc -z -w 1 "${host}" "${port}" >/dev/null
    then
        notify_and_log "ERROR" "PORT_FAIL HOST=${host} PORT=${port}"
        return
    fi

    notify_and_log "OK" "PORT_OK HOST=${host} PORT=${port}"
    return
}

main() {
    # ping_check "${MTCH_SERVER_HOST}"
    port_check "${MTCH_SERVER_HOST}" "${MTCH_SERVER_PORT}"
}

main