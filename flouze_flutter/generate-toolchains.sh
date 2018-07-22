#!/bin/sh

ANDROID_HOME="$HOME/.local/android-sdk-linux"

if [ ! -d "$ANDROID_HOME" ]; then
	echo "Cannot find the Android SDK in $ANDROID_HOME"
	exit 1
fi

NDK_HOME="$ANDROID_HOME/ndk-bundle"

if [ ! -d "$NDK_HOME" ]; then
	echo "Cannot find the Android NDK in $NDK_HOME"
	exit 1
fi

set -e

ANDROID_API=27

mkdir -p ndk-toolchains

for arch in x86 x86_64 arm arm64; do
	echo "Generating toolchain for $arch"
	rm -fr ndk-toolchains/$arch
	$NDK_HOME/build/tools/make_standalone_toolchain.py --api $ANDROID_API --arch $arch --install-dir ndk-toolchains/$arch
done
