#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${SCRIPT_DIR}/monitor_cpu_usage.sh"
    "${SCRIPT_DIR}/monitor_cpu_temp.sh"
fi
