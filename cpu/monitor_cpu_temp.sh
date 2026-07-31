#!/bin/bash

# CPU 温度を監視して、閾値を超えたら通知するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# CPU 温度の閾値。環境変数で上書き可能
CPU_TEMP_THRESHOLD=${CPU_TEMP_THRESHOLD:-85}

# /sys から CPU 温度の生値を取得する
get_cpu_temp_raw() {
    local zone type temp

    for zone in /sys/class/thermal/thermal_zone*; do
        [ -f "${zone}/temp" ] || continue

        if [ -f "${zone}/type" ]; then
            type=$(<"${zone}/type" 2>/dev/null || true)
            case "${type}" in
                *cpu*|*package*|*x86_pkg*|*soc*|*core*|*thermal*)
                    temp=$(<"${zone}/temp" 2>/dev/null || true)
                    [ -n "${temp}" ] && break
                    ;;
            esac
        fi
    done

    if [ -z "${temp:-}" ] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(< /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true)
    fi

    echo "${temp:-}"
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

CPU_TEMP_RAW=$(get_cpu_temp_raw)
CPU_TEMP=$(normalize_temp "${CPU_TEMP_RAW}")
LOG_STATUS=UNKNOWN

if [ -n "${CPU_TEMP}" ]; then
    if [ "${CPU_TEMP}" -ge "${CPU_TEMP_THRESHOLD}" ]; then
        LOG_STATUS=ERROR
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_temp ERROR "TEMP=${CPU_TEMP}C"
    else
        LOG_STATUS=OK
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_temp OK "TEMP=${CPU_TEMP}C"
    fi
else
    LOG_STATUS=WARNING
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" cpu_temp WARNING "TEMP=UNKNOWN"
fi

"${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" cpu_temp "${LOG_STATUS}" "TEMP=${CPU_TEMP:-UNKNOWN}"
