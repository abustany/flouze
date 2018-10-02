#!/bin/bash

set -ex

SDK_TOOLS_RELEASE="4333796"
MY_DIR=$(pwd)

export PATH="$HOME/.local/android-sdk-linux/tools/bin:$PATH"

if ! which sdkmanager >/dev/null 2>&1; then
  curl -O -C - https://dl.google.com/android/repository/sdk-tools-linux-$SDK_TOOLS_RELEASE.zip
  mkdir -p ~/.local/android-sdk-linux
  (cd ~/.local/android-sdk-linux && unzip -q $MY_DIR/sdk-tools-linux-$SDK_TOOLS_RELEASE.zip)
  rm $MY_DIR/sdk-tools-linux-$SDK_TOOLS_RELEASE.zip
fi

ensure_java() {
  if ! dpkg -l openjdk-8-jre-headless >/dev/null 2>&1; then
    echo "Setting up Java 8"
    sudo add-apt-repository ppa:openjdk-r/ppa -y
    sudo apt-get update -q
    sudo apt-get -y -q install openjdk-8-jre-headless
  fi
}

#if [ ! -d ~/.local/android-sdk-linux/ndk-bundle ]; then
#  ensure_java
#  # Mute the output, else we hit Travis' output rate limiting
#  echo "Installing NDK"
#  yes | sdkmanager --install ndk-bundle >/dev/null
#fi

if [ ! -f ~/.local/android-ndk-r18/README.md ]; then
  curl -O -C - https://dl.google.com/android/repository/android-ndk-r18-linux-x86_64.zip
  (cd ~/.local && unzip -q $MY_DIR/android-ndk-r18-linux-x86_64.zip)
  rm $MY_DIR/android-ndk-r18-linux-x86_64.zip
fi

