#!/bin/bash

# CPU 使用率を監視して閾値を超えたか確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# CPU 使用率の閾値。環境変数で上書き可能
THRESHOLD=${CPU_THRESHOLD:-80}
# CPU 使用率の測定間隔
INTERVAL=${INTERVAL:-1}

notify_and_log() {
    local status="$1"
    local message="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_usage "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" cpu_usage "${status}" "${message}"
}

# /proc/stat から CPU 時間を読み取る
read_cpu_times() {
    local cpu user nice system idle iowait irq softirq steal guest guest_nice

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    echo "$((user + nice + system + idle + iowait + irq + softirq + steal)) $((idle + iowait))"
}

calculate_cpu_usage() {
    local total_before idle_before total_after idle_after total_diff idle_diff

    read -r total_before idle_before < <(read_cpu_times)
    sleep "${INTERVAL}"
    read -r total_after idle_after < <(read_cpu_times)

    total_diff=$((total_after - total_before))
    idle_diff=$((idle_after - idle_before))

    if [ "${total_diff}" -le 0 ]; then
        echo 0
        return
    fi

    echo $((100 * (total_diff - idle_diff) / total_diff))
}

main() {
    local cpu_usage
    local status

    cpu_usage=$(calculate_cpu_usage)
    status="OK"

    if [ "${cpu_usage}" -ge "${THRESHOLD}" ]; then
        status="ERROR"
    fi

    notify_and_log "${status}" "CPU=${cpu_usage}%"
}

main
