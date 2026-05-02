#!/system/bin/sh

module_dir="/data/adb/modules/Surfing"
magisk -v | grep -q lite && module_dir="/data/adb/lite_modules/Surfing"

scripts=$(realpath "$0")
scripts_dir=$(dirname "${scripts}")
mkdir -p "${run_path}"
source "${scripts_dir}/box.config"

wait_until_login() {
  local test_file="/sdcard/Android/.SURFINGTEST"
  true > "$test_file"
  while [ ! -f "$test_file" ]; do
    true > "$test_file"
    sleep 1
  done
  rm -f "$test_file"

  while [ ! -f "/data/system/packages.xml" ]; do
    sleep 1
  done
}

wait_until_login

if [ ! -f "${box_path}/manual" ] && [ ! -f "${module_dir}/disable" ]; then
  mv "${run_path}/run.log" "${run_path}/run.log.bak" 2>/dev/null
  mv "${run_path}/run_error.log" "${run_path}/run_error.log.bak" 2>/dev/null
  "${scripts_dir}/box.service" start >> "${run_path}/run.log" 2>> "${run_path}/run_error.log" && \
  "${scripts_dir}/box.iptables" enable >> "${run_path}/run.log" 2>> "${run_path}/run_error.log"
(
    sleep 1
    MAX_RETRIES=20
    RETRY_COUNT=0
    INTERVAL=1
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if service list | grep -q "activity"; then
            if am broadcast -a com.surfing.tile.ACTION_WAKEUP_CLASH \
                         -n com.surfing.tile/com.surfing.tile.service.BootReceiver \
                         -f 0x01000020 2>&1 | grep -q "Broadcast completed"; then
                break
            fi
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep $INTERVAL
    done
) &
fi

find /data/adb/box_bll/clash/etc/ -type d -exec chmod 755 {} \; -o -type f -exec chmod 644 {} \;