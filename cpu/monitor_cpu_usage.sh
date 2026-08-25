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

    #OKなら通知しない
    if [ "${status}" = "OK" ]; then return; fi

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_usage "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" cpu_usage "${status}" "${message}"
}

# /proc/stat から全 CPU の時間を読み取る
read_cpu_times_all() {
    local line cpu user nice system idle iowait irq softirq steal guest guest_nice
    local tmpfile
    tmpfile=$(mktemp)

    while IFS= read -r line; do
        if [[ $line =~ ^cpu ]]; then
            read cpu user nice system idle iowait irq softirq steal guest guest_nice <<< "$line"
            local total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
            local idle_time=$((idle + iowait))
            echo "$cpu $total $idle_time" >> "$tmpfile"
        else
            break
        fi
    done < /proc/stat

    cat "$tmpfile"
    rm "$tmpfile"
}

# CPU 利用率を計算（全体とコア毎）
calculate_cpu_usage_per_core() {
    local tmpfile_before tmpfile_after
    tmpfile_before=$(mktemp)
    tmpfile_after=$(mktemp)

    read_cpu_times_all > "$tmpfile_before"
    sleep "${INTERVAL}"
    read_cpu_times_all > "$tmpfile_after"

    local total_usage=0
    local core_count=0
    local overall_cpu_usage=0

    # コア毎の利用率を計算
    while IFS= read -r core_before; do
        local core_name=$(echo "$core_before" | awk '{print $1}')
        local total_before=$(echo "$core_before" | awk '{print $2}')
        local idle_before=$(echo "$core_before" | awk '{print $3}')

        local core_after=$(grep "^${core_name} " "$tmpfile_after")
        if [ -z "$core_after" ]; then
            continue
        fi

        local total_after=$(echo "$core_after" | awk '{print $2}')
        local idle_after=$(echo "$core_after" | awk '{print $3}')

        local total_diff=$((total_after - total_before))
        local idle_diff=$((idle_after - idle_before))

        local cpu_usage
        if [ "${total_diff}" -le 0 ]; then
            cpu_usage=0
        else
            cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
        fi

        if [ "$core_name" = "cpu" ]; then
            overall_cpu_usage=$cpu_usage
        else
            echo "$core_name: ${cpu_usage}%"
            total_usage=$((total_usage + cpu_usage))
            core_count=$((core_count + 1))
        fi
    done < "$tmpfile_before"

    # 平均利用率を出力
    if [ $core_count -gt 0 ]; then
        local avg_usage=$((total_usage / core_count))
        echo "Average: ${avg_usage}%"
    fi

    # 全体（cpu行）の利用率も出力
    echo "Overall: ${overall_cpu_usage}%"

    rm "$tmpfile_before" "$tmpfile_after"
}

main() {
    local core_status
    local overall_status
    local output

    output=$(calculate_cpu_usage_per_core)

    # コア毎の利用率を抽出して閾値を超えているか確認
    local core_usage
    core_usage=$(echo "$output" | grep -E "^cpu[0-9]+:" | awk '{print $1 "=" $2}' | paste -sd "," -)

    core_status="OK"
    if [ -n "$core_usage" ]; then
        for usage in $(echo "$core_usage" | tr ',' ' '); do
            local core_name=$(echo "$usage" | cut -d'=' -f1)
            local core_value=$(echo "$usage" | cut -d'=' -f2 | sed 's/%//')
            if [ "${core_value}" -ge "${THRESHOLD}" ]; then
                core_status="WARNING"
                break
            fi
        done
    fi

    notify_and_log "${core_status}" "Core Usage=${core_usage}"
    
    # 出力から全体の利用率を抽出
    local overall_usage
    overall_usage=$(echo "$output" | grep "^Overall:" | awk '{print $2}' | sed 's/%//')
    
    overall_status="OK"
    if [ "${overall_usage}" -ge "${THRESHOLD}" ]; then
        overall_status="ERROR"
    fi

    notify_and_log "${overall_status}" "Overall Usage=${overall_usage}%"
}

main
