#!/bin/bash
# scripts/memory_check.sh
# 使用 /proc/meminfo 檢查記憶體可用量（MemAvailable）
# 回傳：
#   0 = OK
#   1 = WARN
#   2 = ERROR

set -u

# ---- metrics helpers（提供數值給 daemon 用） ----
mem_total_kb() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

mem_avail_kb() {
    awk '/^MemAvailable:/ {print $2}' /proc/meminfo
}

mem_avail_pct() {
    local total avail
    total="$(mem_total_kb)"
    avail="$(mem_avail_kb)"

    # 防呆
    if [[ -z "$total" || "$total" -le 0 || -z "$avail" ]]; then
        echo "0"
        return
    fi

    echo $(( avail * 100 / total ))
}

# ---- main check（只回傳狀態碼，不寫 log）----
memory_check() {
    local warn_pct err_pct avail_pct

    warn_pct="${MEM_AVAIL_WARN_PCT:-15}"
    err_pct="${MEM_AVAIL_ERROR_PCT:-5}"
    avail_pct="$(mem_avail_pct)"

    if (( avail_pct <= err_pct )); then
        return 2
    fi
    if (( avail_pct <= warn_pct )); then
        return 1
    fi

    return 0
}

# 直接執行時方便測試
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    memory_check
    rc=$?
    echo "mem_avail_pct=$(mem_avail_pct)% rc=$rc"
    exit $rc
fi

