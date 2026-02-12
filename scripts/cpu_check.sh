#!/bin/bash
# scripts/cpu_check.sh
# 使用 /proc/loadavg 檢查系統負載（load average）
# 回傳：
#   0 = OK
#   1 = WARN
#   2 = ERROR

set -u

cpu_load1() {
    awk '{print $1}' /proc/loadavg
}

cpu_check() {
    # 讀 1 分鐘 load average（最常用來當健康指標）
    local load1
    load1="$(cpu_load1)"

    # 若 config 沒設定，給預設值（避免 set -u 爆炸）
    local warn="${CPU_LOAD_WARN:-2.00}"
    local err="${CPU_LOAD_ERROR:-4.00}"

    # 用 awk 做浮點數比較
    if awk -v l="$load1" -v e="$err" 'BEGIN{exit !(l >= e)}'; then
        return 2
    fi
    if awk -v l="$load1" -v w="$warn" 'BEGIN{exit !(l >= w)}'; then
        return 1
    fi

    return 0
}

# （可選）如果有人直接執行這支檔案，就輸出一次結果，方便你手動測
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    cpu_check
    exit $?
fi

