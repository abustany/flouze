FROM centos:7.6.1810

# Install all needed packages as root before dropping to CI user
# Flutter currently need a recent version of Git (https://github.com/flutter/flutter/issues/21626)
RUN \
  curl -o /etc/yum.repos.d/git.repo https://copr.fedorainfracloud.org/coprs/g/git-maint/git/repo/epel-7/group_git-maint-git-epel-7.repo && \
  yum upgrade -y libstdc++ && \
  yum install -y unzip java-1.8.0-openjdk-devel python gcc clang make git which libstdc++.i686 openssl-devel

RUN useradd -m ci
USER ci

ENV PATH="/home/ci/.cargo/bin:$PATH"
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0"

RUN \
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain 1.38.0 -y && \
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
  echo yes | sdkmanager --install "build-tools;28.0.3" "platform-tools" "platforms;android-28" && \
  cd ~/.local && \
  git clone https://github.com/flutter/flutter.git -b "v1.9.1+hotfix.4" && \
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
