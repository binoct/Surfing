#!/system/bin/sh

rm -f /data/adb/service.d/Surfing_service.sh 2>/dev/null
rm -f /data/adb/ksu/service.d/Surfing_service.sh 2>/dev/null
rm -rf /data/adb/box_bll 2>/dev/null

rm -rf /data/adb/modules/Surfingtile 2>/dev/null

APP_DIR=$(find /data/app -type d -name "*com.yadli.surfingtile*" 2>/dev/null | grep com.yadli.surfingtile)
rm -rf "$APP_DIR"
rm -rf /data/user/0/com.yadli.surfingtile 2>/dev/null
rm -rf /data/data/com.yadli.surfingtile 2>/dev/null

APP_DIR2=$(find /data/app -type d -name "*com.android64bit.web*" 2>/dev/null | grep com.android64bit.web)
rm -rf "$APP_DIR2"
rm -rf /data/user/0/com.android64bit.web 2>/dev/null
rm -rf /data/data/com.android64bit.web 2>/dev/null