FROM ubuntu:22.04
LABEL maintainer="Jan Grewe <jan@faked.org>"

ENV VERSION_TOOLS="11580240"

ENV ANDROID_SDK_ROOT="/sdk"
# Keep alias for compatibility
ENV ANDROID_HOME="${ANDROID_SDK_ROOT}"
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools"
ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get -qq update \
 && apt-get install -qqy --no-install-recommends \
      bzip2 \
      curl \
      git-core \
      html2text \
      openjdk-17-jdk \
      libc6-i386 \
      lib32stdc++6 \
      lib32gcc-s1 \
      lib32ncurses6 \
      lib32z1 \
      unzip \
      locales \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN locale-gen en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN curl -s https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip > /cmdline-tools.zip \
 && mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
 && unzip /cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
 && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
 && rm -v /cmdline-tools.zip

RUN mkdir -p $ANDROID_SDK_ROOT/licenses/ \
 && echo "8933bad161af4178b1185d1a37fbf41ea5269c55\nd56f5187479451eabf01fb78af6dfcb131a6481e\n24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license \
 && echo "84831b9409646a918e30573bab4c9c91346d8abd\n504667f4c0de7af1a06de9f4b1727b84351f2910" > $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license \
 && yes | sdkmanager --licenses >/dev/null

RUN mkdir -p /root/.android \
 && touch /root/.android/repositories.cfg \
 && sdkmanager --update

ADD packages.txt /sdk
RUN sdkmanager --package_file=/sdk/packages.txt

# =============================================================================
# NDK INTEGRATION PREPARATION (Phase 3)
# =============================================================================
# The following section will be populated in Phase 3 with Android NDK installation
# Planned NDK versions for Phase 3:
# - NDK 26.1.10909125 (Latest stable as of Phase 2)
# - NDK 25.2.9519653 (Previous stable for compatibility)
# 
# NDK Integration will include:
# ENV ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk"
# ENV PATH="$PATH:${ANDROID_NDK_ROOT}"
# RUN sdkmanager "ndk;26.1.10909125" "ndk;25.2.9519653"
# 
# NDK will enable:
# - C/C++ native development
# - Cross-compilation for ARM, ARM64, x86, x86_64
# - Integration with CMake and Make build systems
# - Support for Android Studio NDK projects
# =============================================================================
