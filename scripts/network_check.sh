#!/bin/bash
# scripts/network_check.sh
# 檢查網路連線品質（延遲）
# 回傳：
#   0 = OK
#   1 = WARN
#   2 = ERROR

set -u

# ---- metrics helpers（提供數值給 daemon 用） ----
network_latency_ms() {
    # ping -c 3 發送3個封包，tail -1 取統計行，awk -F'/' 取平均延遲
    local latency
    latency="$(ping -c 3 "$PING_TARGET" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')"
    echo "${latency:-0}"
}

network_packet_loss_pct() {
    # 取封包遺失率百分比
    local loss
    loss="$(ping -c 3 "$PING_TARGET" 2>/dev/null | grep 'packet loss' | awk -F'%' '{print $1}' | awk '{print $NF}')"
    echo "${loss:-0}"
}

# ---- main check（只回傳狀態碼，不寫 log）----
network_check() {
    local latency loss warn_latency err_latency warn_loss err_loss
    
    # 若 config 沒設定，給預設值（避免 set -u 爆炸）
    warn_latency="${NETWORK_LATENCY_WARN_MS:-200}"
    err_latency="${NETWORK_LATENCY_ERROR_MS:-500}"
    warn_loss="${NETWORK_PACKET_LOSS_WARN_PCT:-10}"
    err_loss="${NETWORK_PACKET_LOSS_ERROR_PCT:-30}"
    
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    
    # 如果 ping 完全失敗（延遲為 0 且遺失率為 0）
    if [[ "$latency" == "0" && "$loss" == "0" ]]; then
        return 2  # ERROR - 無法連線
    fi
    
    # 檢查延遲閾值
    if (( $(echo "$latency >= $err_latency" | bc -l 2>/dev/null || echo "0") )); then
        return 2  # ERROR - 延遲過高
    fi
    
    if (( $(echo "$latency >= $warn_latency" | bc -l 2>/dev/null || echo "0") )); then
        return 1  # WARN - 延遲偏高
    fi
    
    # 檢查封包遺失率閾值
    if (( loss >= err_loss )); then
        return 2  # ERROR - 封包遺失過高
    fi
    
    if (( loss >= warn_loss )); then
        return 1  # WARN - 封包遺失偏高
    fi
    
    return 0  # OK
}

# 直接執行時方便測試
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    network_check
    rc=$?
    latency="$(network_latency_ms)"
    loss="$(network_packet_loss_pct)"
    echo "network_latency=${latency}ms packet_loss=${loss}% rc=$rc"
    exit $rc
fi

