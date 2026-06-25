#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/monitor_network_common.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    network_common_init
    "${SCRIPT_DIR}/monitor_network_status.sh"
    "${SCRIPT_DIR}/monitor_network_traffic.sh"
fi
