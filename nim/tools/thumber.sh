#!/bin/bash

S=512

mkdir -p "thumbnails"
for i in `ls *.png`; do
    if [ ! -f "thumbnails/$i" ]; then
        convert -define png:size=${S}x${S} "$i" \
          -thumbnail "${S}x${S}>" "thumbnails/$i"
    fi
done

ls thumbnails/*.png > thumbnails/list.txt