#!/bin/bash
# lib/logger.sh
# Unified logger for journald (stdout/stderr)
set -u

_now() { date '+%Y-%m-%d %H:%M:%S'; }

_log() {
  local level="$1"
  local message="$2"
  echo "[$(_now)] [$level] $message"
}

log_info()  { _log "INFO"  "$1"; }
log_warn()  { _log "WARN"  "$1"; }
log_error() { _log "ERROR" "$1"; }

