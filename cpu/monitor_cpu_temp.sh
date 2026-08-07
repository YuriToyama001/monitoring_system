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
    local zone type temp zone_temp

    for zone in /sys/class/thermal/thermal_zone*; do
        [ -r "${zone}/temp" ] || continue

        zone_temp=$(<"${zone}/temp" 2>/dev/null || true)
        [ -z "${zone_temp}" ] && continue

        if [ -r "${zone}/type" ]; then
            type=$(<"${zone}/type" 2>/dev/null || true)
        else
            type=""
        fi

        case "${type}" in
            *cpu*|*package*|*x86_pkg*|*soc*|*core*|*thermal*)
                temp="${zone_temp}"
                break
                ;;
        esac
    done

    if [ -z "${temp:-}" ] && [ -r /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(< /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true)
    fi

    printf '%s\n' "${temp:-}"
}

normalize_temp() {
    local raw_temp=$1

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

cpu_temp_raw=$(get_cpu_temp_raw)
cpu_temp=$(normalize_temp "${cpu_temp_raw}")

if [ -n "${cpu_temp}" ]; then
    if [ "${cpu_temp}" -ge "${CPU_TEMP_THRESHOLD}" ]; then
        notify_and_log "ERROR" "TEMP=${cpu_temp}C"
    else
        notify_and_log "OK" "TEMP=${cpu_temp}C"
    fi
else
    notify_and_log "WARNING" "TEMP=UNKNOWN"
fi
