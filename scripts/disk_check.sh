#!/bin/bash
# scripts/disk_check.sh
# 檢查磁碟使用率（預設檢查 /）
# 回傳：
#   0 = OK
#   1 = WARN
#   2 = ERROR

set -u

disk_used_pct() {
    local mount_point="${1:-/}"
    # df -P 確保輸出格式固定；NR==2 取第二行；$5 是 "xx%"
    df -P "$mount_point" | awk 'NR==2 {gsub(/%/,"",$5); print $5}'
}

disk_check() {
    local mount_point="${1:-/}"
    local warn="${DISK_USED_WARN_PCT:-80}"
    local err="${DISK_USED_ERROR_PCT:-90}"
    local used

    used="$(disk_used_pct "$mount_point")"

    # 防呆：如果 df 失敗或抓不到數字
    if [[ -z "$used" ]]; then
        return 2
    fi

    if (( used >= err )); then
        return 2
    fi
    if (( used >= warn )); then
        return 1
    fi
    return 0
}

# 直接執行測試
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    disk_check "/"
    rc=$?
    echo "disk_used_pct=$(disk_used_pct "/")% rc=$rc"
    exit $rc
fi

