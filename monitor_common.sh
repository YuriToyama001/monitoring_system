#!/bin/bash

# Shared helpers for monitoring scripts.

run_monitor_check() {
    local script_path="$1"
    shift || true

    if [ ! -f "${script_path}" ]; then
        echo "Missing script: ${script_path}" >&2
        return 1
    fi

    "${script_path}" "$@" || {
        local exit_code=$?
        echo "Warning: ${script_path} exited with status ${exit_code}" >&2
        return 0
    }
}

run_monitor_script() {
    run_monitor_check "$@"
}

run_check() {
    run_monitor_check "$@"
}
