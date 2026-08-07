#!/bin/bash

# メモリ使用率を監視して閾値を超えたか確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# メモリ使用率の閾値。環境変数で上書き可能
THRESHOLD=${MEMORY_THRESHOLD:-90}

notify_and_log() {
    local status="$1"
    local value="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" memory_usage "${status}" "${value}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" memory_usage "${status}" "${value}"
}

# /proc/meminfo からメモリ使用率を計算する
get_memory_usage() {
    local total available used

    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if [ "${total}" -le 0 ]; then
        echo 0
        return
    fi

    used=$((total - available))
    echo $((used * 100 / total))
}

usage_percent=$(get_memory_usage)
status="OK"

if [ "${usage_percent}" -ge "${THRESHOLD}" ]; then
    status="ERROR"
fi

notify_and_log "${status}" "${usage_percent}"
