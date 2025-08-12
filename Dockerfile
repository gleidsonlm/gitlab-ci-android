FROM ubuntu:22.04

LABEL version="1.0.0" \
      description="Android CI/CD Docker image with pre-configured SDK, build tools, and GitLab optimization" \
      maintainer="gleidsonlm"

ENV VERSION_TOOLS="13114758"

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
      wget \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN locale-gen en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

RUN rm -f /etc/ssl/certs/java/cacerts; \
    /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN wget --no-verbose --no-check-certificate --output-document=/cmdline-tools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip \
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
RUN grep -v '^#' /sdk/packages.txt | grep -v '^$' > /sdk/packages_clean.txt \
 && sdkmanager --package_file=/sdk/packages_clean.txt

# =============================================================================
# ANDROID NDK AND NATIVE DEVELOPMENT TOOLCHAIN - Phase 3
# =============================================================================

# Configure NDK environment variables for multi-version support
ENV ANDROID_NDK_ROOT="${ANDROID_SDK_ROOT}/ndk"
ENV ANDROID_NDK_HOME="${ANDROID_NDK_ROOT}/27.3.13750724"
ENV PATH="$PATH:${ANDROID_NDK_HOME}:${ANDROID_SDK_ROOT}/cmake/3.22.1/bin"

# Install native development tools
RUN apt-get -qq update \
 && apt-get install -qqy --no-install-recommends \
      build-essential \
      clang \
      libc6-dev \
      ninja-build \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android NDK and CMake through SDK Manager
# This ensures proper integration with Android SDK and automatic license handling
RUN sdkmanager "ndk;27.3.13750724" "ndk;26.3.11579264" "cmake;3.22.1"

# Create symbolic links for easier NDK access and backward compatibility
RUN ln -sf ${ANDROID_SDK_ROOT}/ndk/27.3.13750724 ${ANDROID_SDK_ROOT}/ndk/latest \
 && ln -sf ${ANDROID_SDK_ROOT}/ndk/26.3.11579264 ${ANDROID_SDK_ROOT}/ndk/previous

# Verify NDK installation and create runtime environment setup
RUN echo "#!/bin/bash" > /usr/local/bin/ndk-env \
 && echo "export ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}" >> /usr/local/bin/ndk-env \
 && echo "export ANDROID_NDK_HOME=${ANDROID_NDK_HOME}" >> /usr/local/bin/ndk-env \
 && echo "export PATH=\$PATH:${ANDROID_NDK_HOME}:${ANDROID_SDK_ROOT}/cmake/3.22.1/bin" >> /usr/local/bin/ndk-env \
 && chmod +x /usr/local/bin/ndk-env

# =============================================================================
# NDK INTEGRATION SUMMARY
# =============================================================================
# Installed Components:
# - NDK 27.3.13750724 (Latest LTS) - Primary NDK for new projects
# - NDK 26.3.11579264 (Previous Stable) - Compatibility for legacy projects  
# - CMake 3.22.1 (LTS) - Native build system integration
# - Ninja Build - High-performance build system
# - Clang/LLVM - Modern C/C++ compiler toolchain
# - LLDB - Advanced native code debugger (included with NDK)
#
# Environment Variables:
# - ANDROID_NDK_ROOT: Points to NDK installation directory
# - ANDROID_NDK_HOME: Points to default/latest NDK version
# - PATH: Includes NDK and CMake binaries for global access
#
# Symbolic Links:
# - /sdk/ndk/latest -> NDK 27.3.13750724 (latest stable)
# - /sdk/ndk/previous -> NDK 26.3.11579264 (previous stable)
# =============================================================================

# =============================================================================
# GRADLE AND KOTLIN BUILD OPTIMIZATION - Phase 4
# =============================================================================

# Install Gradle 9.0.0 (latest stable) for global availability
ENV GRADLE_VERSION="9.0.0"
ENV GRADLE_HOME="/opt/gradle"
ENV PATH="$PATH:${GRADLE_HOME}/bin"

RUN wget --no-verbose --output-document=/gradle.zip \
      https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
 && mkdir -p ${GRADLE_HOME} \
 && unzip /gradle.zip -d /opt \
 && mv /opt/gradle-${GRADLE_VERSION} ${GRADLE_HOME} \
 && rm -v /gradle.zip

# Configure Gradle and Kotlin optimization environment variables
ENV GRADLE_USER_HOME="/root/.gradle"
ENV GRADLE_OPTS="-Xmx4g -Xms2g -XX:MaxMetaspaceSize=1g -XX:+UseG1GC -XX:+UseStringDeduplication -Dfile.encoding=UTF-8"
ENV KOTLIN_DAEMON_JVM_OPTIONS="-Xmx2g -Xms512m"

# Create optimized gradle.properties for Kotlin builds
RUN mkdir -p ${GRADLE_USER_HOME} && \
    echo "# Gradle Build Performance Optimization for Kotlin" > ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.daemon=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.parallel=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.configureondemand=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.caching=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.workers.max=4" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "# Android Build Optimization" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "android.useAndroidX=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "android.enableJetifier=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "android.enableR8.fullMode=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "android.bundle.enableUncompressedNativeLibs=false" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "# Kotlin Compilation Optimization" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "kotlin.incremental=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "kotlin.incremental.android=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "kotlin.incremental.java=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "kotlin.caching.enabled=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "kotlin.parallel.tasks.in.project=true" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "# JVM Memory Settings" >> ${GRADLE_USER_HOME}/gradle.properties && \
    echo "org.gradle.jvmargs=-Xmx4g -Xms2g -XX:MaxMetaspaceSize=1g -XX:+UseG1GC -XX:+UseStringDeduplication -Dfile.encoding=UTF-8" >> ${GRADLE_USER_HOME}/gradle.properties

# =============================================================================
# GRADLE AND KOTLIN INTEGRATION SUMMARY
# =============================================================================
# Installed Components:
# - Gradle 9.0.0 (Latest Stable) - Global installation for all projects
# - Optimized gradle.properties with performance settings
# - Kotlin build optimization configurations
# - Android build performance enhancements
#
# Environment Variables:
# - GRADLE_HOME: Points to Gradle installation directory
# - GRADLE_USER_HOME: Points to global Gradle user directory
# - GRADLE_OPTS: JVM optimization arguments for Gradle
# - KOTLIN_DAEMON_JVM_OPTIONS: JVM optimization for Kotlin daemon
# - PATH: Includes Gradle binaries for global access
#
# Performance Features:
# - Build cache enabled for faster subsequent builds
# - Parallel execution for multi-module projects
# - Optimized JVM settings for Kotlin compilation
# - Android build optimizations (R8, native libs, etc.)
# - Incremental compilation for Kotlin and Java
# =============================================================================
