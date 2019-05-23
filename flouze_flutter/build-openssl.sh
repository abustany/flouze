#!/bin/sh

set -e

cd $(dirname $0)

OPENSSL_VERSION=1.1.1a

build() {
	cargo_arch=$1
	openssl_arch=$2

	echo "Building for $cargo_arch"

	tool_prefix=$(grep '^ar' ~/.cargo/config | grep $cargo_arch | awk '{print $3}' | sed -e 's,",,g' -e "s,/bin/${cargo_arch}-ar\$,,")
	build_dir="$BASE_OUT_DIR/build-openssl-$cargo_arch"
	install_dir="$BASE_OUT_DIR/install-openssl-$cargo_arch"
	ncpus=$(nproc 2>/dev/null || echo 1)
	old_path=$PATH

	rm -fr $build_dir
	mkdir $build_dir
	cd $build_dir

	export ANDROID_NDK="$tool_prefix" PATH="$tool_prefix/bin:$PATH"
	$OPENSSL_SRC_DIR/Configure no-shared no-tests no-ui --prefix=$install_dir $openssl_arch
	make -j${ncpus}
	make install_sw

	unset ANDROID_NDK
	export PATH=$old_path

	cd $BASE_OUT_DIR
	rm -fr $build_dir
}

mkdir -p openssl
cd openssl

if [ ! -d "openssl-${OPENSSL_VERSION}" ]; then
	wget -c https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
	tar xf openssl-${OPENSSL_VERSION}.tar.gz
fi

BASE_OUT_DIR=$(pwd)
OPENSSL_SRC_DIR=$(cd openssl-${OPENSSL_VERSION} && pwd)

build aarch64-linux-android android-arm64
build arm-linux-androideabi android-arm
build i686-linux-android    android-x86
build x86_64-linux-android  android-x86_64
