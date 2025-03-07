#!/bin/sh

version=$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}' | sed 's/ (.*//')

if [ "$isAlpha" = true ]; then
    filename="Surfing_${version}_alpha.zip"
else
    filename="Surfing_${version}_release.zip"
fi

zip -r -o -X -ll "$filename" ./ -x '.git/*' -x '.github/*' -x 'folder/*' -x 'build.sh' -x 'Surfing.json'
