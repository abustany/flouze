FROM fedora:28

# Install all needed packages as root before dropping to CI user
RUN dnf install -y unzip java-1.8.0-openjdk-devel python gcc git libstdc++.i686

RUN useradd -m ci
USER ci

ENV PATH="/home/ci/.cargo/bin:$PATH"
ENV RUSTC_RELEASE_DATE="2018-07-18"

RUN \
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly-$RUSTC_RELEASE_DATE -y && \
  rustup default nightly-$RUSTC_RELEASE_DATE && \
  rustup target add aarch64-linux-android && \
  rustup target add armv7-linux-androideabi && \
  rustup target add i686-linux-android && \
  rustup target add x86_64-linux-android

RUN \
  export SDK_TOOLS_RELEASE="4333796" && \
  curl -o /tmp/sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-$SDK_TOOLS_RELEASE.zip && \
  mkdir -p ~/.local/android-sdk-linux && \
  (cd ~/.local/android-sdk-linux && unzip -q /tmp/sdk-tools.zip) && \
  rm /tmp/sdk-tools.zip

ENV ANDROID_HOME="/home/ci/.local/android-sdk-linux"
ENV PATH="/home/ci/.local/android-sdk-linux/tools/bin:$PATH"

RUN \
  curl -o /tmp/ndk.zip https://dl.google.com/android/repository/android-ndk-r18-linux-x86_64.zip && \
  (cd ~/.local && unzip -q /tmp/ndk.zip) && \
  rm /tmp/ndk.zip

ENV NDK_HOME="/home/ci/.local/android-ndk-r18"

ENV PATH="/home/ci/.local/flutter/bin:$PATH"

RUN \
  echo yes | sdkmanager --install "build-tools;27.0.3" "platform-tools" "platforms;android-27" && \
  cd ~/.local && \
  git clone https://github.com/flutter/flutter.git -b v0.8.2 && \
  flutter doctor

RUN \
  yes | flutter doctor --android-licenses

RUN \
  export ANDROID_API="27" && \
  mkdir ~/.local/ndk-toolchains && \
  for arch in x86 x86_64 arm arm64; do \
    echo "Generating toolchain for $arch" && \
    $NDK_HOME/build/tools/make_standalone_toolchain.py --api $ANDROID_API --arch $arch --install-dir $HOME/.local/ndk-toolchains/$arch; \
  done

ADD cargo_config /home/ci/.cargo/config
RUN sed -i "s|_HOME_|$HOME|g" $HOME/.cargo/config
