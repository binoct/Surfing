#!/system/bin/sh

RUN_LOG="/data/adb/box_bll/run/run.log"

mkdir -p "$(dirname "$RUN_LOG")"

log() {
    local level=$1
    local msg=$2
    local now=$(date +"[%Y-%m-%d %H:%M:%S CST]")
    echo "${now} [${level}]: ${msg}" >> "${RUN_LOG}"
}

BASE_MODULES_DIR="/data/adb/modules"
[ -n "$(magisk -v | grep lite)" ] && BASE_MODULES_DIR="/data/adb/lite_modules"

SURFING_DIR="${BASE_MODULES_DIR}/Surfing"
SURFING_TILE_DIR="${BASE_MODULES_DIR}/SurfingTile"

SCRIPTS_DIR="/data/adb/box_bll/scripts"

(
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 3
done
"${SCRIPTS_DIR}/start.sh"
) &

HOSTS_PATH="/data/adb/box_bll/clash/etc"
HOSTS_FILE="${HOSTS_PATH}/hosts"
SYSTEM_HOSTS="/system/etc/hosts"

mkdir -p "$HOSTS_PATH" "/dev/tmp"

if [ -f "$HOSTS_FILE" ]; then
    mount -o bind "$HOSTS_FILE" "$SYSTEM_HOSTS" 2>/dev/null
fi

sleep 1
safe_inotifyd() {
    local script="$1"
    local target="$2"
    if pgrep -f "inotifyd $script $target" > /dev/null; then
        return 0
    fi
    nohup inotifyd "$script" "$target" > /dev/null 2>&1 &
}

safe_inotifyd "${SCRIPTS_DIR}/box.inotify" "$SURFING_DIR" > /dev/null 2>&1
safe_inotifyd "${SCRIPTS_DIR}/box.inotify" "$HOSTS_PATH" > /dev/null 2>&1

(
NET_DIR="/data/misc/net"
CTR_FILE="/data/misc/net/rt_tables"

while [ ! -f "$CTR_FILE" ]; do
  sleep 3
done

safe_inotifyd "${SCRIPTS_DIR}/net.inotify" "$NET_DIR" > /dev/null 2>&1
safe_inotifyd "${SCRIPTS_DIR}/ctr.inotify" "$CTR_FILE" > /dev/null 2>&1
) &

if [ -d "$SURFING_TILE_DIR" ] && [ -f "$SURFING_TILE_DIR/module.prop" ]; then
    safe_inotifyd "${SCRIPTS_DIR}/box.inotify" "/data/system" > /dev/null 2>&1
fi

delete_op_coloros16_fw_rules() {
    brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
    case "$brand" in
        oppo|oneplus|realme|oplus)
            log Info "命中欧加系设备 (${brand})，准备执行谷歌服务解禁 (120秒后启动)..."
            ;;
        *)
            return 0
            ;;
    esac
    
    sleep 120
    
    local total_deleted=0
    log Info "开始扫描 ColorOS 16 底层防火墙，解除谷歌拦截规则..."

    CHAINS="fw_INPUT fw_OUTPUT"
    PROTOS="ipv4 ipv6"
    for proto in $PROTOS; do
        case "$proto" in
            ipv4) cmd="iptables" ;;
            ipv6) cmd="ip6tables" ;;
        esac
        
        for chain in $CHAINS; do
            $cmd -t filter -nL "$chain" >/dev/null 2>&1 || continue
            lines=$($cmd -t filter -nL "$chain" --line-numbers \
                    | grep "REJECT" \
                    | awk '{print $1}' \
                    | sort -rn)
            for line in $lines; do
                [ -n "$line" ] && [ "$line" -gt 0 ] || continue
                if $cmd -t filter -D "$chain" "$line" 2>/dev/null; then
                    total_deleted=$((total_deleted + 1))
                fi
            done
        done
    done

    if [ "$total_deleted" -gt 0 ]; then
        log Info "谷歌服务解禁完成: 共粉碎 ${total_deleted} 条原生防火墙拦截规则."
    else
        log Info "谷歌服务解禁扫描完毕: 未发现任何异常拦截规则."
    fi
}
delete_op_coloros16_fw_rules &
