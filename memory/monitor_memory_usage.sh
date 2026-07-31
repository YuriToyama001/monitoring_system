#!/bin/bash

# メモリ使用率を監視して閾値を超えたか確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# メモリ使用率の閾値。環境変数で上書き可能
THRESHOLD=${MEMORY_THRESHOLD:-90}

# /proc/meminfo からメモリ使用率を計算する
get_memory_usage() {
    local total available used
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

    if [ "$total" -le 0 ]; then
        echo 0
        return
    fi

    used=$((total - available))
    echo $((used * 100 / total))
}

PERCENT=$(get_memory_usage)
STATUS=OK

if [ "$PERCENT" -ge "$THRESHOLD" ]; then
    STATUS=ERROR
fi

"${SCRIPT_DIR}/../notify/notify_dispatch.sh" memory "${STATUS}" "${PERCENT}"
"${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" memory "${STATUS}" "${PERCENT}"
