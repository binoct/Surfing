#!/system/bin/sh

BASE_MODULES_DIR="/data/adb/modules"
[ -n "$(magisk -v | grep lite)" ] && BASE_MODULES_DIR="/data/adb/lite_modules"

SURFING_DIR="${BASE_MODULES_DIR}/Surfing"
SURFING_TILE_DIR="${BASE_MODULES_DIR}/SurfingTile"

SCRIPTS_DIR="/data/adb/box_bll/scripts"

(
until [ "$(getprop sys.boot_completed)" -eq 1 ]; do
  sleep 3
done
"${SCRIPTS_DIR}/start.sh"
) &

HOSTS_PATH="/data/adb/box_bll/clash/etc"
HOSTS_FILE="${HOSTS_PATH}/hosts"
SYSTEM_HOSTS="/system/etc/hosts"

mkdir -p "$HOSTS_PATH" "/dev/tmp"

sleep 1

inotifyd "${SCRIPTS_DIR}/box.inotify" "$SURFING_DIR" > /dev/null 2>&1 &
inotifyd "${SCRIPTS_DIR}/box.inotify" "$HOSTS_PATH" > /dev/null 2>&1 &

mount -o bind "$HOSTS_FILE" "$SYSTEM_HOSTS"

NET_DIR="/data/misc/net"
CTR_FILE="/data/misc/net/rt_tables"

while [ ! -f "$CTR_FILE" ]; do
  sleep 3
done

inotifyd "${SCRIPTS_DIR}/net.inotify" "$NET_DIR" > /dev/null 2>&1 &
inotifyd "${SCRIPTS_DIR}/ctr.inotify" "$CTR_FILE" > /dev/null 2>&1 &

if [ -d "$SURFING_TILE_DIR" ] && [ -f "$SURFING_TILE_DIR/module.prop" ]; then
    inotifyd "${SCRIPTS_DIR}/box.inotify" "/data/system" > /dev/null 2>&1 &
fi

delete_op_coloros16_fw_rules() {
    brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
    case "$brand" in
        oppo|oneplus|realme|oplus)
            ;;
        *)
            return 0
            ;;
    esac
    sleep 120
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
                $cmd -t filter -D "$chain" "$line" 2>/dev/null
            done
        done
    done
}
delete_op_coloros16_fw_rules &