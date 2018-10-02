#!/bin/bash

set -ex

MY_DIR=$(cd $(dirname $0) && pwd)

if [ ! -d ~/.local/ndk-toolchains/arm ]; then
  # The make_standalone_toolchain.py script from the Android tools needs Python
  dpkg -l python2.7 >/dev/null 2>&1 || apt-get -y install python2.7

  export NDK_HOME="$HOME/.local/android-ndk-r18"
  (cd ~/.local && $MY_DIR/../flouze_flutter/generate-toolchains.sh)
fi

mkdir -p ~/.cargo
sed "s|_HOME_|$HOME|g" travis/cargo_config > ~/.cargo/config
