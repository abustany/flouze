#!/bin/bash

OUT_NAME=ic_launcher.png

set -e

cd $(dirname $0)

icon() {
	local name=$1
	local size=$2
	inkscape -z -f icon.svg -e android/app/src/main/res/mipmap-$name/$OUT_NAME --export-area-page --export-width=$size --export-height=$size
}

#icon ldpi 36
icon mdpi 48
icon hdpi 72
icon xhdpi 96
icon xxhdpi 144
icon xxxhdpi 192
