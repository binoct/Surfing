#!/bin/sh

SKIPUNZIP=1
ASH_STANDALONE=1
MIN_KSU_VER=10670; KSU_DIR_VER=10683
LANG_EN=false

CURRENT_MODULES_DIR="/data/adb/modules"
magisk -v | grep -q lite && abort "Error: Magisk Lite is no longer supported. Please use standard Magisk / KernelSU / APatch"

SURFING_PATH="$CURRENT_MODULES_DIR/Surfing"
BOX_BLL_PATH="/data/adb/box_bll"
BIN_PATH="$BOX_BLL_PATH/bin"

SCRIPTS_PATH="$BOX_BLL_PATH/scripts"
NET_PATH="/data/misc/net"
CTR_PATH="/data/misc/net/rt_tables"
CONFIG_FILE="$BOX_BLL_PATH/clash/config.yaml"
BACKUP_FILE="$BOX_BLL_PATH/clash/proxies/subscribe_urls_backup.txt"
HOSTS_FILE="$BOX_BLL_PATH/clash/etc/hosts"
HOSTS_PATH="$BOX_BLL_PATH/clash/etc"
HOSTS_BACKUP="$BOX_BLL_PATH/clash/etc/hosts.bak"

[ "$BOOTMODE" != true ] && abort "Error: Please install via Magisk Manager / KernelSU Manager / APatch"; [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt "$MIN_KSU_VER" ] && abort "Error: Please update your KernelSU Manager version"; [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt "$KSU_DIR_VER" ] && service_dir="/data/adb/ksu/service.d" || service_dir="/data/adb/service.d"

[ ! -d "$service_dir" ] && mkdir -p "$service_dir"; unzip -qo "${ZIPFILE}" -x 'META-INF/*' -d "$MODPATH"

init_busybox_toolchain() { chmod 755 "$BIN_PATH/busybox" && (cd "$BIN_PATH" && find . -type l -delete && ./busybox --install -s .); }

run_watch() { nohup inotifyd "${SCRIPTS_PATH}/$1" "$2" >/dev/null 2>&1 & }

print_lang() { [ "$LANG_EN" = true ] && ui_print "$2" || ui_print "$1"; }

choose_volume_key() {
  timeout_seconds=10
  line=$(timeout $timeout_seconds getevent -ql | awk '/KEY_VOLUME/ {print; exit}')
  if [ -z "$line" ]; then
      print_lang "未检测到输入，执行默认操作..." "No input detected. Running default option..."
      return 1
  fi
  if echo "$line" | grep -q "KEY_VOLUMEUP"; then
      return 0
  else
      return 1
  fi
}

choose_language() {
  ui_print "*********************************"
  ui_print "请选择安装日志语言 / Choose language:"
  ui_print "音量上键 / Vol Up: 中文 (Chinese)"
  ui_print "音量下键 / Vol Down: English"
  ui_print "*********************************"
  ui_print "请在 10 秒内按下音量键 / Please press Vol Key in 10s..."
  if choose_volume_key; then
    LANG_EN=false
    ui_print "已选择: 中文"
  else
    LANG_EN=true
    ui_print "Selected: English"
  fi
  ui_print " "
}

extract_subscribe_urls() {
  if [ -f "$CONFIG_FILE" ]; then
    sed -n '/# 订阅地址相关/,/profile:.*↑/p' "$CONFIG_FILE" > "$BACKUP_FILE"
    
    if [ -s "$BACKUP_FILE" ]; then
      print_lang "已备份订阅配置." "Backed up subscription configuration."
    else
      print_lang "未找到订阅块.将使用默认值." "No subscription block found. Using default."
    fi
  else
    print_lang "配置文件丢失.无法提取订阅." "Config file missing. Cannot extract subscriptions."
  fi
}

restore_subscribe_urls() {
  if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    awk -v backup="$BACKUP_FILE" '
      BEGIN { skip = 0 }
      /# 订阅地址相关/ {
        skip = 1
        while ((getline < backup) > 0) { print }
        close(backup)
        next
      }
      /profile:.*↑/ {
        skip = 0
        next
      }
      !skip { print }
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    print_lang "已恢复订阅配置." "Restored subscription configuration."
  else
    print_lang "未找到有效备份.跳过恢复操作." "No valid backup found. Skipped restore."
  fi
}

# 「3.额外地址」用于外部引擎的本地 socks5 入口 (type: file); 升级时订阅块会被整体还原,
# 若该槽位没有填写真实订阅地址, 则把类型改回 file, 否则保留用户原有的 http 订阅
normalize_extra_provider() {
  [ -f "$CONFIG_FILE" ] || return 0
  extra_url=$(awk '
    /^proxy-providers:/ { inpp = 1; next }
    inpp && /^[^[:space:]]/ { exit }
    inpp && /^[[:space:]]+"3\.额外地址":[[:space:]]*$/ { inblk = 1; next }
    inblk && /^[[:space:]]+"[^"]+":[[:space:]]*$/ { exit }
    inblk && /^[[:space:]]+url:/ {
      sub(/^[[:space:]]+url:[[:space:]]*/, "")
      gsub(/["\047]/, "")
      print
      exit
    }
  ' "$CONFIG_FILE")
  case "$extra_url" in
    ""|*此处引入*)
      awk '
        /^proxy-providers:/ { inpp = 1; print; next }
        inpp && /^[^[:space:]]/ { inpp = 0; inblk = 0 }
        inpp && /^[[:space:]]+"3\.额外地址":[[:space:]]*$/ {
          inblk = 1
          print
          print "    type: file"
          next
        }
        inblk && /^[[:space:]]+"[^"]+":[[:space:]]*$/ { inblk = 0 }
        inblk && /^[[:space:]]+type:[[:space:]]*/ { next }
        { print }
      ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      print_lang "外部引擎 provider 已设为本地文件模式." "External engine provider set to local file mode."
      ;;
  esac
}

sync_version_from_module_prop() {
  dst_prop="$CURRENT_MODULES_DIR/Surfing/module.prop"
  if [ -f "$MODPATH/module.prop" ] && [ -d "$CURRENT_MODULES_DIR/Surfing" ]; then
    cp -f "$MODPATH/module.prop" "$dst_prop"
  fi
}

choose_to_umount_hosts_file() {
  print_lang "是否挂载 hosts 文件到系统？" "Mount the hosts file to the system?"
  print_lang "音量上键: 挂载" "Volume Up: Mount"
  print_lang "音量下键: 卸载 (恢复默认)" "Volume Down: Uninstall default"
  print_lang "请等待输入 (10s)..." "Waiting for input (10s)..."
  if choose_volume_key; then
    print_lang "Hosts 文件已挂载." "Hosts file mounted."
  else
    print_lang "Hosts 文件卸载完成." "Uninstalling hosts file is complete."
    rm -f "$HOSTS_FILE"
  fi
}

choose_to_restore_config() {
  if [ -f "$BOX_BLL_PATH/clash/config.yaml.bak" ]; then
    ui_print " "
    print_lang "检测到已有 Clash 配置，是否保留？" "Existing Clash config found. Keep it?"
    print_lang "音量上键: 保留我的配置" "Volume Up: Keep my config"
    print_lang "音量下键: 使用新默认配置" "Volume Down: Use new default config"
    print_lang "请等待输入 (10s)..." "Waiting for input (10s)..."

    if choose_volume_key; then
      cp -f "$BOX_BLL_PATH/clash/config.yaml.bak" "$BOX_BLL_PATH/clash/config.yaml"
      print_lang "已保留更新前的配置." "Kept the previous config."
    else
      print_lang "已使用新默认配置." "Using the new default config."
    fi
  fi
}

remove_old_surfingtile() {
  pm uninstall "com.surfing.tile" >/dev/null 2>&1 || pm uninstall --user 0 "com.surfing.tile" >/dev/null 2>&1
  OLD_UNINSTALL="$CURRENT_MODULES_DIR/SurfingTile/uninstall.sh"
  [ -f "$OLD_UNINSTALL" ] && sh "$OLD_UNINSTALL"
}

choose_language

sync_version_from_module_prop
remove_old_surfingtile
    if [ -d "$BOX_BLL_PATH" ]; then
      print_lang "正在更新模块..." "Updating module..."
      ui_print "↴"

      cp -f "$MODPATH/box_bll/bin/busybox" "$BIN_PATH/busybox" && init_busybox_toolchain
      cp -f "$MODPATH/box_bll/bin/curl" "$BIN_PATH/curl"
      extract_subscribe_urls

      if pm path "com.github.surfing" >/dev/null 2>&1; then
        CORE_HASH=$(grep '^version=' "$MODPATH/module.prop" | sed 's/.*(//; s/).*//; s/.*-//')
        [ -n "$CORE_HASH" ] && {
          SYNC_DATA=$(settings get global surfing_sync_data 2>/dev/null)
          case "$SYNC_DATA" in
            ""|null) ;;
            *)
              NOW_TS=$(date +%s)
              settings put global surfing_sync_data "$(echo "$SYNC_DATA" | sed "s|^ID=[0-9]*|ID=$NOW_TS|; s|version=[^|]*|version=$CORE_HASH|")"
              ;;
          esac
        }
      fi

      [ -f "$HOSTS_FILE" ] && cp -f "$HOSTS_FILE" "$HOSTS_BACKUP"
      mkdir -p "$HOSTS_PATH" && touch "$HOSTS_FILE"

      cp "$BOX_BLL_PATH/clash/config.yaml" "$BOX_BLL_PATH/clash/config.yaml.bak"
      cp -f "$MODPATH/box_bll/clash/config.yaml" "$BOX_BLL_PATH/clash/"
      cp -f "$MODPATH/box_bll/clash/config.yaml" "$MODPATH/default_config.yaml"

      # config.yaml 将「3.额外地址」声明为 type: file 的 provider, 文件为 proxies/外部引擎.yaml;
      # 旧版写入的 "socks5://host:port" 单行不是合法 provider, 这里直接替换为合法文件
      PROXY_EXTRA="$BOX_BLL_PATH/clash/proxies/外部引擎.yaml"
      PROXY_EXTRA_OLD="$BOX_BLL_PATH/clash/proxies/3.额外地址.yaml"
      mkdir -p "$BOX_BLL_PATH/clash/proxies"
      [ -f "$PROXY_EXTRA_OLD" ] && [ ! -f "$PROXY_EXTRA" ] && mv -f "$PROXY_EXTRA_OLD" "$PROXY_EXTRA"
      grep -q '^[[:space:]]*proxies:' "$PROXY_EXTRA" 2>/dev/null || \
        cp -f "$MODPATH/box_bll/clash/proxies/外部引擎.yaml" "$PROXY_EXTRA"

      cp "$BOX_BLL_PATH/scripts/box.config" "$BOX_BLL_PATH/scripts/box.config.bak"
      cp -f "$MODPATH/box_bll/scripts/"* "$BOX_BLL_PATH/scripts/"

      mkdir -p "$BOX_BLL_PATH/extra"
      [ -f "$BOX_BLL_PATH/extra/engine" ] || cp -f "$MODPATH/box_bll/extra/engine" "$BOX_BLL_PATH/extra/" 2>/dev/null

      # 打包时预置的第三方引擎二进制: 设备上缺失才复制, 已有的版本保持不动
      for ENGINE in aether usque warpscout; do
        ENGINE_BIN="$MODPATH/box_bll/extra/$ENGINE/$ENGINE"
        [ -f "$ENGINE_BIN" ] || continue
        [ -f "$BOX_BLL_PATH/extra/$ENGINE/$ENGINE" ] && continue
        mkdir -p "$BOX_BLL_PATH/extra/$ENGINE"
        cp -f "$ENGINE_BIN" "$BOX_BLL_PATH/extra/$ENGINE/"
        [ -f "$MODPATH/box_bll/extra/$ENGINE/version" ] && \
          cp -f "$MODPATH/box_bll/extra/$ENGINE/version" "$BOX_BLL_PATH/extra/$ENGINE/"
        chmod 0755 "$BOX_BLL_PATH/extra/$ENGINE/$ENGINE"
        print_lang "已预置外部引擎 $ENGINE." "Bundled external engine $ENGINE installed."
      done

      # 跳过注释行取 engine=<名称>, 兼容旧版裸引擎名
      ENGINE_NAME=$(sed -n 's/^[[:space:]]*#.*//; s/^[[:space:]]*engine=//; /^[[:space:]]*$/d; p' "$BOX_BLL_PATH/extra/engine" 2>/dev/null | head -n 1 | tr -d ' \t\r')

      # 旧版文件只有一行裸引擎名, 升级时改写为带可选清单的 engine= 格式
      if ! grep -q '^[[:space:]]*engine=' "$BOX_BLL_PATH/extra/engine" 2>/dev/null; then
        case "$ENGINE_NAME" in
          aether|usque|warpscout|none)
            [ "$(grep -cv -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$BOX_BLL_PATH/extra/engine")" = "1" ] && {
              printf '%s\n' \
                '# 外部引擎开关: 只保留一个 engine= 行生效, 改等号后的名字即可切换' \
                '# 可选 aether / usque / warpscout, 改为 none 表示不启用' \
                "engine=${ENGINE_NAME}" > "$BOX_BLL_PATH/extra/engine"
            }
            ;;
        esac
      fi

      OLD_CONFIG="$BOX_BLL_PATH/scripts/box.config.bak"; NEW_CONFIG="$BOX_BLL_PATH/scripts/box.config"
      [ -f "$OLD_CONFIG" ] && {
        print_lang "正在迁移网络服务控制设置..." "Migrating network service control settings..."
        TMP_CONFIG="${NEW_CONFIG}.tmp"; cp -f "$NEW_CONFIG" "$TMP_CONFIG"
        VARS="enable_network_service_control bypass_via_iptables enable_cellular_proxy enable_wifi_proxy enable_ssid_filter enable_mac_filter use_wifi_list_mode blacklist_wifi_macs whitelist_wifi_macs blacklist_wifi_ssids whitelist_wifi_ssids ap_list gid_list user_packages_list proxy_mode proxy_method ipv6"
        for var in $VARS; do
          val=$(grep "^${var}=" "$OLD_CONFIG" | cut -d'=' -f2-)
          [ -n "$val" ] && sed "s@^${var}=.*@${var}=${val}@" "$TMP_CONFIG" > "${TMP_CONFIG}.bak" && mv -f "${TMP_CONFIG}.bak" "$TMP_CONFIG"
        done
        for iface in "swlan+" "softap+"; do
          grep "^ap_list=" "$TMP_CONFIG" | grep -qF "$iface" || sed -i "s@^ap_list=(\(.*\))@ap_list=(\1 \"${iface}\")@" "$TMP_CONFIG"
        done
        mv -f "$TMP_CONFIG" "$NEW_CONFIG"
        print_lang "设置迁移成功." "Settings migrated successfully."
      }

      restore_subscribe_urls
      normalize_extra_provider

      for pid in $(pidof inotifyd); do grep -qE "box.inotify|net.inotify|ctr.inotify" "/proc/$pid/cmdline" 2>/dev/null && kill "$pid"; done

      run_watch "box.inotify" "$HOSTS_PATH"; run_watch "box.inotify" "$SURFING_PATH"; run_watch "net.inotify" "$NET_PATH"; run_watch "ctr.inotify" "$CTR_PATH"

      sleep 1
      cp -f "$MODPATH/box_bll/clash/etc/hosts" "$BOX_BLL_PATH/clash/etc/"
      rm -rf "$MODPATH/box_bll"

      choose_to_umount_hosts_file
      choose_to_restore_config
      
      print_lang "更新已完成." "Update completed."
    else
      print_lang "正在安装..." "Installing..."
      ui_print "↴"
      mv "$MODPATH/box_bll" /data/adb/; init_busybox_toolchain
      cp -f "$BOX_BLL_PATH/clash/config.yaml" "$MODPATH/default_config.yaml"
      print_lang "模块安装完毕." "Module installation completed."
      
      choose_to_umount_hosts_file
      choose_to_restore_config
    fi

mv -f "$MODPATH/Surfing_service.sh" "$service_dir/"

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm_recursive "$BOX_BLL_PATH" 0 3005 0755 0644
set_perm_recursive "$BOX_BLL_PATH/scripts" 0 3005 0755 0700
set_perm_recursive "$BIN_PATH" 0 0 0755 0755
set_perm_recursive "$BOX_BLL_PATH/clash/etc" 0 0 0755 0644
set_perm "$service_dir/Surfing_service.sh" 0 0 0700

chmod ugo+x "$BOX_BLL_PATH/scripts/"*

rm -f customize.sh
