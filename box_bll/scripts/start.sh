#!/system/bin/sh

module_dir="/data/adb/modules/Surfing"

[ -n "$(magisk -v | grep lite)" ] && module_dir=/data/adb/lite_modules/Surfing

scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})

source ${scripts_dir}/box.config

wait_until_login(){
  # we doesn't have the permission to rw "/sdcard" before the user unlocks the screen
  local test_file="/sdcard/Android/.SURFINGTEST"
  true > "$test_file"
  while [ ! -f "$test_file" ] ; do
    true > "$test_file"
    sleep 1
  done
  rm "$test_file"

  while [ ! -f "/data/system/packages.xml" ] ; do
    sleep 1
  done
}
wait_until_login

rm ${pid_file}
mkdir -p ${run_path}

if [ ! -f ${box_path}/manual ] && [ ! -f ${module_dir}/disable ] ; then
  mv ${run_path}/run.log ${run_path}/run.log.bak
  mv ${run_path}/run_error.log ${run_path}/run_error.log.bak

  ${scripts_dir}/box.service start >> ${run_path}/run.log 2>> ${run_path}/run_error.log && \
  ${scripts_dir}/box.tproxy enable >> ${run_path}/run.log 2>> ${run_path}/run_error.log

  MONITOR_SCRIPT="${scripts_dir}/box.monitor"
  MONITOR_PID_FILE="${scripts_dir}/../run/monitor.pid"

  if [ "$enable_monitor" = "true" ]; then
    nohup "$MONITOR_SCRIPT" >> "${run_path}/run_error.log" 2>&1 &
  fi
fi

chown -R 0:0 /data/adb/box_bll/clash/etc/
find /data/adb/box_bll/clash/etc/ -type d -exec chmod 755 {} \;
find /data/adb/box_bll/clash/etc/ -type f -exec chmod 644 {} \;

CONFIG_FILE="${scripts_dir}/box.config"

parse_interval() {
  raw=$(echo "$clean_interval" | tr -d '[:space:]')
  [ -z "$raw" ] && echo 43200 && return

  unit=${raw: -1}
  value=${raw%[smhd]}

  case "$unit" in
    s) echo "$value" ;;
    m) echo $((value * 60)) ;;
    h) echo $((value * 3600)) ;;
    d) echo $((value * 86400)) ;;
    *) echo "$raw" ;;
  esac
}

(
  LAST_RUN_TIME=0
  CURRENT_INTERVAL=43200

  while true; do
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

    [ "$interval_enabled" != "true" ] && sleep 1 && continue

    INTERVAL=$(parse_interval)
    NOW=$(date +%s)
    TIME_DIFF=$((NOW - LAST_RUN_TIME))

    if [ "$TIME_DIFF" -ge "$INTERVAL" ]; then
      LAST_RUN_TIME=$NOW
      curl -X DELETE http://127.0.0.1:9090/connections >/dev/null 2>&1
    fi

    sleep 1
  done
) &