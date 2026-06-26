#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${SCRIPT_DIR}/monitor_memory_usage.sh"
fi