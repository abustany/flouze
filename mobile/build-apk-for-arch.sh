#!/bin/sh

# Builds an Android APK for a given architecture. This is currently required
# because of https://github.com/flutter/flutter/issues/18494. The supported
# architectures are android-arm and android-arm64.

set -e

arch=$1

case "$1" in
	android-arm)
		rust_arch="arm-linux-androideabi"
		;;
	android-arm64)
		rust_arch="aarch64-linux-android"
		;;
	*)
		echo "Unsupported architecture: $arch."
		echo ""
		echo "Usage: $0 ARCH"
		echo "Builds the Flutter APK for a given architecture."
		echo "Supported architectures are android-arm and android-arm64."
		exit 1
		;;
esac

my_dir=$(cd $(dirname $0) && pwd)
(cd $my_dir/../flouze_flutter && rm -fr android/src/main/jniLibs && ONLY_ARCH=$rust_arch ./build-jni-libs.sh --release)
flutter build apk --target-platform=$arch
