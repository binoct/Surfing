#!/bin/sh

version=$(grep 'version=' module.prop | awk -F '=' '{print $2}' | sed 's/ (.*//')

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
    -x '.git/*' \
    -x '.github/*' \
    -x 'folder/*' \
    -x 'build.sh' \
    -x 'Surfing.json'