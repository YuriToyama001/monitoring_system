#!/bin/bash

# CPU 温度を監視して、閾値を超えたら通知するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# CPU 温度の閾値。環境変数で上書き可能
CPU_TEMP_THRESHOLD=${CPU_TEMP_THRESHOLD:-85}

notify_and_log() {
    local status="$1"
    local message="$2"

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_temp "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" cpu_temp "${status}" "${message}"
}

# /sys から CPU 温度の生値を取得する
get_cpu_temp_raw() {
    local zone type zone_temp

    for zone in /sys/class/thermal/thermal_zone*; do
        [ -r "${zone}/temp" ] || continue
        zone_temp=$(tr -d '\r\n\t ' < "${zone}/temp" 2>/dev/null || true)
        [ -n "${zone_temp}" ] && {
            printf '%s\n' "${zone_temp}"
            return 0
        }
    done

    for zone in /sys/class/hwmon/hwmon*/temp*_input /sys/class/hwmon/hwmon*/temp_input; do
        [ -r "${zone}" ] || continue
        zone_temp=$(tr -d '\r\n\t ' < "${zone}" 2>/dev/null || true)
        [ -n "${zone_temp}" ] && {
            printf '%s\n' "${zone_temp}"
            return 0
        }
    done

    printf '%s\n' ""
}

normalize_temp() {
    local raw_temp=${1:-}
    raw_temp=${raw_temp//[$'\r\n\t ']}

    if [[ "${raw_temp}" =~ ^[0-9]+$ ]]; then
        if [ "${raw_temp}" -ge 1000 ]; then
            echo $((raw_temp / 1000))
        else
            echo "${raw_temp}"
        fi
    else
        echo ""
    fi
}

main() {
    local cpu_temp_raw
    local cpu_temp

    cpu_temp_raw=$(get_cpu_temp_raw)

    cpu_temp=$(normalize_temp "${cpu_temp_raw}")

    if [ -n "${cpu_temp}" ]; then
        if [ "${cpu_temp}" -ge "${CPU_TEMP_THRESHOLD}" ]; then
            notify_and_log "ERROR" "TEMP=${cpu_temp}C"
            return
        else
            notify_and_log "OK" "TEMP=${cpu_temp}C"
            return
        fi
    else
        notify_and_log "WARNING" "TEMP=UNKNOWN"
        return
    fi
}

main
