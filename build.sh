#!/bin/sh

APK_DIR="app/version/com.surfing.tile"
TILE_DST="SurfingTile/system/app/com.surfing.tile"
TILE_PROP="SurfingTile/module.prop"

latest_apk=$(ls "$APK_DIR"/Tile_*_release.apk 2>/dev/null | sort -V | tail -n 1)

apk_filename=$(basename "$latest_apk")

tile_version=$(echo "$apk_filename" | sed -E 's/^Tile_([0-9.]+)_release\.apk$/\1/')

cp -f "$latest_apk" "$TILE_DST/com.surfing.tile.apk"

sed -i "s/^version=.*/version=v$tile_version/" "$TILE_PROP"

WEB_APK_DIR="app/version/com.android64bit.web"
WEB_DST="webroot"

latest_web_apk=$(ls "$WEB_APK_DIR"/Web_*_release.apk 2>/dev/null | sort -V | tail -n 1)

apk_web_filename=$(basename "$latest_web_apk")

cp -f "$latest_web_apk" "$WEB_DST/com.android64bit.web.apk"

version=$(grep '^version=' module.prop | awk -F '=' '{print $2}' | sed 's/ (.*//')
short_hash=$(git rev-parse --short=7 HEAD)

if [ "$isAlpha" = true ]; then
    new_version="${version} (alpha-${short_hash})"
    filename="Surfing_alpha_${short_hash}.zip"
else
    new_version="${version} (release-${short_hash})"
    filename="Surfing_${version}_release.zip"
fi

sed -i "s/^version=.*/version=${new_version}/" module.prop

cd SurfingTile || exit 1
zip -r -o -X -ll ../SurfingTile.zip ./*
cd ..

zip -r -o -X -ll "$filename" ./ \
    -x 'SurfingTile/*' \
    -x 'app/*' \
    -x '.git/*' \
    -x '.github/*' \
    -x 'folder/*' \
    -x 'build.sh' \
    -x 'Surfing.json'