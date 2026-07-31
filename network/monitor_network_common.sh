#!/bin/bash

# ネットワーク監視スクリプトで共通して使う関数を定義する
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 通知を行う共通ラッパー
notify_redis() {
    local resource="$1"
    local status="$2"
    local value="$3"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" "${resource}" "${status}" "${value}"
}

network_common_init() {
    INTERFACE=${INTERFACE:-eth0}
    BASE="/sys/class/net/${INTERFACE}"
}

network_common_validate() {
    [ -d "${BASE}" ]
}

network_common_notify_missing() {
    local event="$1"
    notify_redis "${event}" ERROR "IF_NOT_FOUND"
}
