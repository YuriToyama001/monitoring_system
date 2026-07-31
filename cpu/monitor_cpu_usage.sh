#!/bin/bash

# CPU 使用率を監視して閾値を超えたか確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# CPU 使用率の閾値。環境変数で上書き可能
THRESHOLD=${CPU_THRESHOLD:-80}
# CPU 使用率の測定間隔
INTERVAL=${INTERVAL:-1}

# /proc/stat から CPU 時間を読み取る
read_cpu_times() {
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    echo "$((user + nice + system + idle + iowait + irq + softirq + steal)) $((idle + iowait))"
}

calculate_cpu_usage() {
    local total1 idle1 total2 idle2 total_diff idle_diff
    read -r total1 idle1 < <(read_cpu_times)
    sleep "${INTERVAL}"
    read -r total2 idle2 < <(read_cpu_times)

    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))

    if [ "$total_diff" -le 0 ]; then
        echo 0
        return
    fi

    echo $((100 * (total_diff - idle_diff) / total_diff))
}

CPU_USAGE=$(calculate_cpu_usage)
STATUS=OK

if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
    STATUS=ERROR
fi

"${SCRIPT_DIR}/../notify/notify.sh" cpu_usage "${STATUS}" "CPU=${CPU_USAGE}%"
"${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" cpu_usage "${STATUS}" "CPU=${CPU_USAGE}%"
