#!/bin/sh

version=$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}' | sed 's/ (.*//')

if [ "$isAlpha" = true ]; then
    filename="Surfing_${version}_alpha.zip"
else
    filename="Surfing_${version}_release.zip"
fi

cd Surfingtile || exit 1
zip -r -o -X -ll ../Surfingtile.zip ./*
cd ..

zip -r -o -X -ll "$filename" ./ -x 'Surfingtile/*' -x '.git/*' -x '.github/*' -x 'folder/*' -x 'build.sh' -x 'Surfing.json'