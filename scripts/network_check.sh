#!/bin/bash
# scripts/network_check.sh
# 檢查網路是否可達

set -u

# 回傳 0 = OK, 1 = FAILED
network_check() {
    if ping -c 3 "$PING_TARGET" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

