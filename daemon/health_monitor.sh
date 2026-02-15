#!/bin/bash
# daemon/health_monitor.sh
# Main orchestrator: load modules, run checks, print results (journald will capture)

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# load env file when running manually (dev-friendly)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -z "${PING_TARGET:-}" && -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

# Load modules
source "$BASE_DIR/lib/logger.sh"
source "$BASE_DIR/scripts/network_check.sh"
source "$BASE_DIR/scripts/cpu_check.sh"
source "$BASE_DIR/scripts/memory_check.sh"
source "$BASE_DIR/scripts/disk_check.sh"
source "$BASE_DIR/scripts/cpu_temp_check.sh"

# Required env (provided by systemd EnvironmentFile)
: "${PING_TARGET:?PING_TARGET is required (env)}"
: "${CHECK_INTERVAL:?CHECK_INTERVAL is required (env)}"

cleanup() {
  log_info "Health monitor stopping"
  exit 0
}
trap cleanup SIGINT SIGTERM

log_info "Health monitor started"

while true; do
  # Crash simulation hook (for restart testing)
  if [[ "${FORCE_CRASH:-0}" == "1" ]]; then
    log_error "Simulating CRASH triggered by FORCE_CRASH env"
    exit 1
  fi

  # --- Network ---
  network_rc=0
  network_check || network_rc=$?
  latency=$(network_latency_ms)
  packet_loss=$(network_packet_loss_pct)

  case "$network_rc" in
    0) log_info  "Network OK (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
    1) log_warn  "Network WARN (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
    2) 
      # 使用 network_check 提供的錯誤類型函數
      error_type=$(network_error_type)
      case "$error_type" in
        "connection_failed")
          log_error "Network ERROR (target=$PING_TARGET connection failed)" ;;
        "high_latency")
          log_error "Network ERROR (target=$PING_TARGET high latency=${latency}ms)" ;;
        "high_packet_loss")
          log_error "Network ERROR (target=$PING_TARGET high packet loss=${packet_loss}%)" ;;
        *)
          log_error "Network ERROR (target=$PING_TARGET latency=${latency}ms loss=${packet_loss}%)" ;;
      esac
      ;;
    *) log_error "Network UNKNOWN (rc=$network_rc target=$PING_TARGET)" ;;
  esac

  # --- CPU ---
  cpu_rc=0
  cpu_check || cpu_rc=$?
  load1="$(cpu_load1)"

  case "$cpu_rc" in
    0) log_info  "CPU OK (load1=$load1)" ;;
    1) log_warn  "CPU WARN (load1=$load1 warn>=$CPU_LOAD_WARN)" ;;
    2) log_error "CPU ERROR (load1=$load1 error>=$CPU_LOAD_ERROR)" ;;
    *) log_error "CPU UNKNOWN (rc=$cpu_rc load1=$load1)" ;;
  esac

  # --- Memory ---
  mem_rc=0
  memory_check || mem_rc=$?
  avail_pct="$(mem_avail_pct)"

  case "$mem_rc" in
    0) log_info  "Memory OK (avail=${avail_pct}%)" ;;
    1) log_warn  "Memory WARN (avail=${avail_pct}% warn<=${MEM_AVAIL_WARN_PCT}%)" ;;
    2) log_error "Memory ERROR (avail=${avail_pct}% error<=${MEM_AVAIL_ERROR_PCT}%)" ;;
    *) log_error "Memory UNKNOWN (rc=$mem_rc avail=${avail_pct}%)" ;;
  esac

  # --- Disk ---
  disk_rc=0
  disk_check "/" || disk_rc=$?
  disk_used="$(disk_used_pct "/")"

  case "$disk_rc" in
    0) log_info  "Disk OK (used=${disk_used}%)" ;;
    1) log_warn  "Disk WARN (used=${disk_used}% warn>=${DISK_USED_WARN_PCT}%)" ;;
    2) log_error "Disk ERROR (used=${disk_used}% error>=${DISK_USED_ERROR_PCT}%)" ;;
    *) log_error "Disk UNKNOWN (rc=$disk_rc used=${disk_used}%)" ;;
  esac

  # --- CPU Temperature ---
  temp_rc=0
  cpu_temp_check || temp_rc=$?
  cpu_temp=$(cpu_temp_value)

  case "$temp_rc" in
    0) log_info  "CPU Temperature OK (temp=${cpu_temp}°C)" ;;
    1) log_warn  "CPU Temperature WARN (temp=${cpu_temp}°C warn>=${CPU_TEMP_WARN}°C)" ;;
    2) log_error "CPU Temperature ERROR (temp=${cpu_temp}°C error>=${CPU_TEMP_ERROR}°C)" ;;
    *) log_error "CPU Temperature UNKNOWN (rc=$temp_rc temp=${cpu_temp}°C)" ;;
  esac

  sleep "$CHECK_INTERVAL"
done

