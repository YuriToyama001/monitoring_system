#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

source "${ROOT_DIR}/network/monitor_network_common.sh"

network_common_resolve_interfaces "eth0"
if [ "${#INTERFACES[@]}" -ne 1 ] || [ "${INTERFACES[0]}" != "eth0" ]; then
    echo "Expected single interface from argument" >&2
    exit 1
fi

INTERFACE_1="eth0"
INTERFACE_2="wlan0"
network_common_resolve_interfaces ""
if [ "${#INTERFACES[@]}" -ne 2 ] || [ "${INTERFACES[0]}" != "eth0" ] || [ "${INTERFACES[1]}" != "wlan0" ]; then
    echo "Expected two interfaces from config" >&2
    exit 1
fi

echo "interface resolution ok"
