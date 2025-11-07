#!/usr/bin/env bash
# Configuración global para los scripts de PikaOS Gaming Tools
# Define LOG_DIR y funciones de ayuda mínimas (log_message)

set -euo pipefail

LOG_DIR="${LOG_DIR:-$HOME/.local/share/pikaos-gaming-scripts/logs}"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# Nivel de verbosidad (0 = mínimo, 1 = info, 2 = debug)
VERBOSE="${VERBOSE:-1}"

log_message() {
    # log_message LEVEL MESSAGE [LOGFILE]
    local level="$1"
    local message="$2"
    local logfile="${3:-$LOG_DIR/combined.log}"
    local ts
    ts="$(date +"%Y-%m-%d %H:%M:%S")"
    printf "%s [%s] %s\n" "$ts" "$level" "$message" >> "$logfile"
    if [ "$VERBOSE" -ge 1 ]; then
        printf "%s [%s] %s\n" "$ts" "$level" "$message"
    fi
}

# Información mínima sobre entorno
PKG_MANAGER_DETECTED=""

pkg_manager_info() {
    # This function is overridden by pkg_manager.sh when sourced after this file.
    echo "LOG_DIR=$LOG_DIR"
}
