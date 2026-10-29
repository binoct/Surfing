#!/bin/sh

isAlpha="${isAlpha:-false}"

CORE_DST="box_bll/bin/clash"
CORE_TMP="clash_core.gz"
MIHOMO_API="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
MIHOMO_BASE="https://github.com/MetaCubeX/mihomo/releases/download"
MIHOMO_NAME="mihomo-android-arm64-v8"

CURL_DST="box_bll/bin/curl"
CURL_TMP="curl_tmp"
CURL_URL="https://raw.githubusercontent.com/Zackptg5/Cross-Compiled-Binaries-Android/master/curl/curl-arm64"

ZASH_API="https://api.github.com/repos/Zephyruso/zashboard/releases/latest"
ZASH_DST="box_bll/clash/webroot/Zash"
ZASH_TMP="zash_dist.zip"

# 跳过注释行, 取第一个 engine=<名称> 有效行; 兼容旧版裸引擎名
EXTRA_ENGINE="${EXTRA_ENGINE:-$(sed -n 's/^[[:space:]]*#.*//; s/^[[:space:]]*engine=//; /^[[:space:]]*$/d; p' box_bll/extra/engine 2>/dev/null | head -n 1 | tr -d ' \t\r')}"

extra_repo() {
    case "$1" in
        aether) echo "CluvexStudio/Aether" ;;
        usque) echo "Diniboy1123/usque" ;;
        warpscout) echo "vernette/warpscout" ;;
    esac
}

extra_asset_re() {
    case "$1" in
        aether) echo 'aether-android-arm64\.tar\.gz$' ;;
        usque) echo 'usque_.*_android_arm64\.zip$' ;;
        warpscout) echo 'warpscout_.*_android_arm64\.tar\.gz$' ;;
    esac
}

# 打包时把第三方引擎的 android arm64 二进制放进模块, 设备端启动即用, 无需联网下载.
# 拉取失败只告警: 运行时仍会自动下载, 不因外部仓库不可用而阻断模块发布.
gh_api_get() {
    if [ -n "$GITHUB_TOKEN" ]; then
        curl -fsSL --retry 5 --retry-delay 5 \
            -H "Authorization: token $GITHUB_TOKEN" "$1" -o "$2"
    else
        curl -fsSL --retry 5 --retry-delay 5 "$1" -o "$2"
    fi
}

fetch_extra_engine() {
    engine="$1"
    repo=$(extra_repo "$engine")
    if [ -z "$repo" ]; then
        echo "Warning: unknown extra engine '$engine', skipped."
        return 0
    fi

    json=".extra_${engine}.json"
    dl=".extra_${engine}.dl"
    dst="box_bll/extra/${engine}"

    if ! gh_api_get "https://api.github.com/repos/${repo}/releases/latest" "$json"; then
        echo "Warning: failed to fetch ${repo} release info, extra engine not bundled."
        rm -f "$json"
        return 0
    fi

    tag=$(sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' "$json" | head -n 1)
    url=$(grep -o '"browser_download_url":[[:space:]]*"[^"]*"' "$json" \
        | sed -n 's/.*"\(https[^"]*\)".*/\1/p' \
        | grep -E "$(extra_asset_re "$engine")" | head -n 1)

    if [ -z "$url" ]; then
        echo "Warning: no android_arm64 asset in ${repo} ${tag}, extra engine not bundled."
        rm -f "$json"
        return 0
    fi

    echo "Downloading ${engine} ${tag}: ${url}"
    if ! curl -fL --retry 5 --retry-delay 5 "$url" -o "$dl"; then
        echo "Warning: ${engine} download failed, extra engine not bundled."
        rm -f "$json" "$dl"
        return 0
    fi

    mkdir -p "$dst"
    case "$url" in
        *.zip) unzip -qo "$dl" -d "$dst" || true ;;
        *) tar -xzf "$dl" -C "$dst" || true ;;
    esac
    rm -f "$json" "$dl"

    if [ ! -f "${dst}/${engine}" ]; then
        found=$(find "$dst" -type f -name "$engine" | head -n 1)
        if [ -n "$found" ] && [ "$found" != "${dst}/${engine}" ]; then
            mv -f "$found" "${dst}/${engine}"
        fi
    fi
    if [ ! -f "${dst}/${engine}" ]; then
        echo "Warning: ${engine} binary not found after extraction, extra engine not bundled."
        return 0
    fi

    chmod 0755 "${dst}/${engine}"
    printf '%s\n' "$tag" > "${dst}/version"
    echo "${engine} ${tag} bundled at ${dst}"
}

get_latest_tag() {
    curl -fsSL --retry 5 --retry-delay 5 \
        -H "Authorization: token $GITHUB_TOKEN" "$1" \
        | grep '"tag_name":' | head -n 1 \
        | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

# 规则集与 ASN 数据库不进 git (体积大且 mihomo 能自行更新), 打包时按 config.yaml
# 里的 url 补齐; 拉取失败只告警, 设备端 http 规则提供者与 geo-auto-update 会兜底下载
RULE_DST="box_bll/clash/rules"
ASN_DST="box_bll/clash/ASN.mmdb"
ASN_URL="$(sed -n 's/^  asn: "\(.*\)".*/\1/p' box_bll/clash/config.yaml | head -n 1)"

fetch_if_missing() {
    url="$1"
    out="$2"
    [ -s "$out" ] && return 0
    curl -fsSL --retry 3 --retry-delay 3 "$url" -o "${out}.tmp" || {
        rm -f "${out}.tmp"
        return 1
    }
    mv -f "${out}.tmp" "$out"
}

fetch_rule_sets() {
    mkdir -p "$RULE_DST"
    awk '
        /^  [^ #].*:[[:space:]]*(#.*)?$/ { file = "" }
        /^    path: \.\/rules\// { p = $0; sub(/^    path: \.\/rules\//, "", p); file = p }
        /^    url: / { u = $0; sub(/^    url: "/, "", u); sub(/".*$/, "", u); if (file ~ /\.mrs$/) print file " " u }
    ' box_bll/clash/config.yaml |
    while read -r name url; do
        [ -n "$name" ] || continue
        if fetch_if_missing "$url" "${RULE_DST}/${name}"; then
            echo "Rule set ready: ${name}"
        else
            echo "Warning: rule set ${name} download failed, device will fetch it on first start."
        fi
    done

    if [ -z "$ASN_URL" ]; then
        echo "Warning: no geox-url asn in config.yaml, ASN database not bundled."
    elif fetch_if_missing "$ASN_URL" "$ASN_DST"; then
        echo "ASN database ready."
    else
        echo "Warning: ASN database download failed, mihomo will fetch it via geo-auto-update."
    fi
}

latest_version=$(get_latest_tag "$MIHOMO_API")

if [ -z "$latest_version" ]; then
    echo "Error: Failed to fetch Mihomo version."
    exit 1
fi

echo "Latest Mihomo version: $latest_version"

download_url="${MIHOMO_BASE}/${latest_version}/${MIHOMO_NAME}-${latest_version}.gz"

echo "Downloading Mihomo core..."
if curl -fL --retry 5 --retry-delay 5 "$download_url" -o "$CORE_TMP"; then
    gunzip -c "$CORE_TMP" > "$CORE_DST"
    rm -f "$CORE_TMP"
    chmod +x "$CORE_DST"
else
    echo "Error: Mihomo download failed."
    exit 1
fi

echo "Downloading curl..."
if curl -fL --retry 5 --retry-delay 5 "$CURL_URL" -o "$CURL_TMP"; then
    mv -f "$CURL_TMP" "$CURL_DST"
    chmod +x "$CURL_DST"
else
    echo "Error: curl download failed."
    exit 1
fi

case "$EXTRA_ENGINE" in
    ""|none|clash|mihomo)
        echo "Extra engine not bundled (EXTRA_ENGINE='${EXTRA_ENGINE}')."
        ;;
    *)
        fetch_extra_engine "$EXTRA_ENGINE"
        ;;
esac

zash_latest_version=$(get_latest_tag "$ZASH_API")
if [ -n "$zash_latest_version" ]; then
    echo "Latest Zashboard version: $zash_latest_version"
    zash_url="https://github.com/Zephyruso/zashboard/releases/download/${zash_latest_version}/dist.zip"
    echo "Downloading Zashboard..."
    if curl -fL --retry 5 --retry-delay 5 "$zash_url" -o "$ZASH_TMP"; then
        rm -rf dist Zash "$ZASH_DST"
        mkdir -p "$(dirname "$ZASH_DST")"
        unzip -q "$ZASH_TMP" -d "./zash_temp"
        if [ -d "./zash_temp/dist" ]; then
            mv "./zash_temp/dist" "$ZASH_DST"
            echo "Zashboard deployed to $ZASH_DST"
        else
            echo "Error: Unexpected ZIP structure in Zashboard."
        fi
        rm -rf zash_temp "$ZASH_TMP"
    else
        echo "Error: Zashboard download failed."
    fi
else
    echo "Error: Failed to fetch Zashboard version."
fi

fetch_rule_sets

version=$(grep '^version=' module.prop | awk -F '=' '{print $2}' | sed 's/ (.*//')
short_hash=${SHORT_HASH:-$(git rev-parse --short=7 HEAD)}

if [ "$isAlpha" = "true" ]; then
    new_version="${version} (alpha-${short_hash})"
    filename="Surfing_alpha_${short_hash}.zip"
else
    new_version="${version} (release-${short_hash})"
    filename="Surfing_${version}_release.zip"
fi

sed -i "s/^version=.*/version=${new_version}/" module.prop

zip -r -o -X "$filename" ./ \
    -x 'app/*' \
    -x '.git/*' \
    -x '.github/*' \
    -x 'folder/*' \
    -x 'build.sh' \
    -x 'Surfing.json' \
    -x 'SurfingTile.zip' \
    -x '*.apk'

echo "Build Completed: $filename"