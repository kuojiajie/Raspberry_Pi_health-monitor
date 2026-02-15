#!/bin/bash
# scripts/cpu_temp_check.sh
# CPU 溫度檢查腳本

# 載入設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 載入環境變數 (如果存在)
ENV_FILE="$BASE_DIR/config/health-monitor.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

# 預設溫度閾值 (可在 env 檔案中覆蓋)
CPU_TEMP_WARN=${CPU_TEMP_WARN:-70}
CPU_TEMP_ERROR=${CPU_TEMP_ERROR:-80}

# 讀取 CPU 溫度
read_cpu_temp() {
    local temp_file="/sys/class/thermal/thermal_zone0/temp"
    if [[ -f "$temp_file" ]]; then
        # 溫度值需要除以 1000 (單位是千分之一度)
        local temp_raw=$(cat "$temp_file")
        echo "$((temp_raw / 1000))"
    else
        echo "0"
    fi
}

# 溫度檢查主函數
cpu_temp_check() {
    local cpu_temp
    cpu_temp=$(read_cpu_temp)
    
    # 檢查溫度範圍
    if [[ $cpu_temp -ge $CPU_TEMP_ERROR ]]; then
        return 2  # ERROR
    elif [[ $cpu_temp -ge $CPU_TEMP_WARN ]]; then
        return 1  # WARN
    else
        return 0  # OK
    fi
}

# 提供溫度數值給其他腳本使用
cpu_temp_value() {
    read_cpu_temp
}

# 如果直接執行此腳本，進行檢查
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if cpu_temp_check; then
        echo "CPU Temperature OK ($(cpu_temp_value)°C)"
        exit 0
    else
        rc=$?
        case $rc in
            1) echo "CPU Temperature WARNING ($(cpu_temp_value)°C >= ${CPU_TEMP_WARN}°C)" ;;
            2) echo "CPU Temperature ERROR ($(cpu_temp_value)°C >= ${CPU_TEMP_ERROR}°C)" ;;
        esac
        exit $rc
    fi
fi
