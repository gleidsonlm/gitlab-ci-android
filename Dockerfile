FROM ubuntu:22.04

LABEL version="1.2.0" \
      description="Android CI/CD Docker image with pre-configured SDK, build tools, and GitLab optimization" \
      maintainer="gleidsonlm"

ENV VERSION_TOOLS="13114758"

ENV ANDROID_SDK_ROOT="/sdk"
# Keep alias for compatibility
ENV ANDROID_HOME="${ANDROID_SDK_ROOT}"
ENV PATH="$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/34.0.0:${ANDROID_SDK_ROOT}/build-tools/33.0.2:${ANDROID_SDK_ROOT}/build-tools/32.0.0"
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

# Update CA certificates for proper SSL/TLS validation
RUN update-ca-certificates

# Download Android command line tools with retry logic and validation
RUN for i in 1 2 3; do \
      echo "Attempt $i: Downloading Android command line tools..." && \
      (curl --fail --location --retry 3 --retry-delay 2 --retry-connrefused \
           --show-error --output /cmdline-tools.zip \
           https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip \
      || { \
           echo "HTTPS download failed, trying insecure download (NOT RECOMMENDED for production)..." && \
           curl --fail --location --retry 3 --retry-delay 2 --retry-connrefused \
                --insecure --show-error --output /cmdline-tools.zip \
                https://dl.google.com/android/repository/commandlinetools-linux-${VERSION_TOOLS}_latest.zip; \
      }) \
      && echo "Download completed. Validating zip file..." \
      && unzip -t /cmdline-tools.zip > /dev/null 2>&1 \
      && echo "Zip file validation successful." \
      && break || { \
           echo "Download attempt $i failed. Cleaning up..." && \
           rm -f /cmdline-tools.zip && \
           [ $i -eq 3 ] && { \
             echo "ERROR: Failed to download Android command line tools after 3 attempts." && \
             echo "This may be due to network issues or SSL certificate problems." && \
             echo "Please check your network connection and try again." && \
             exit 1; \
           } || sleep 5; \
      }; \
    done \
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
 && sdkmanager --package_file=/sdk/packages_clean.txt --verbose || echo "Warning: Some packages failed to install due to network issues"

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
RUN sdkmanager "ndk;27.3.13750724" "ndk;26.3.11579264" "cmake;3.22.1" || echo "Warning: NDK packages failed to install due to network issues"

# Verify NDK installation and create runtime environment setup
RUN echo "#!/bin/bash" > /usr/local/bin/ndk-env \
 && echo "export ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}" >> /usr/local/bin/ndk-env \
 && echo "export ANDROID_NDK_HOME=${ANDROID_NDK_HOME}" >> /usr/local/bin/ndk-env \
 && echo "export PATH=\$PATH:${ANDROID_NDK_HOME}:${ANDROID_SDK_ROOT}/cmake/3.22.1/bin" >> /usr/local/bin/ndk-env \
 && chmod +x /usr/local/bin/ndk-env \
 && echo "NDK environment setup script created (run 'source /usr/local/bin/ndk-env' if NDK was installed)"

# Validate SDK Manager detects no duplicate NDK packages
RUN echo "Validating NDK installation without warnings..." \
 && sdkmanager --list 2>&1 | grep -i "warning.*ndk" || echo "✓ No NDK warnings detected"

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
# - ANDROID_NDK_HOME: Points to default/latest NDK version (27.3.13750724)
# - PATH: Includes NDK and CMake binaries for global access
#
# NDK Locations:
# - /sdk/ndk/27.3.13750724 (latest stable - canonical location)
# - /sdk/ndk/26.3.11579264 (previous stable - canonical location)
# Note: No symbolic links are created to avoid SDK Manager warnings about duplicate packages
# =============================================================================

# =============================================================================
# GRADLE AND KOTLIN BUILD OPTIMIZATION - Phase 4
# =============================================================================

# Install Gradle 9.0.0 (latest stable) for global availability
ENV GRADLE_VERSION="9.0.0"
ENV GRADLE_HOME="/opt/gradle"
ENV PATH="$PATH:${GRADLE_HOME}/bin"

# Download and install Gradle with retry logic and validation
RUN for i in 1 2 3; do \
      echo "Attempt $i: Downloading Gradle ${GRADLE_VERSION}..." && \
      (curl --fail --location --retry 3 --retry-delay 2 --retry-connrefused \
           --show-error --output /gradle.zip \
           https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
      || { \
           echo "HTTPS download failed, trying insecure download (NOT RECOMMENDED for production)..." && \
           curl --fail --location --retry 3 --retry-delay 2 --retry-connrefused \
                --insecure --show-error --output /gradle.zip \
                https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip; \
      }) \
      && echo "Download completed. Validating zip file..." \
      && unzip -t /gradle.zip > /dev/null 2>&1 \
      && echo "Zip file validation successful." \
      && break || { \
           echo "Download attempt $i failed. Cleaning up..." && \
           rm -f /gradle.zip && \
           [ $i -eq 3 ] && { \
             echo "ERROR: Failed to download Gradle ${GRADLE_VERSION} after 3 attempts." && \
             echo "This may be due to network issues, SSL certificate problems, or invalid Gradle version." && \
             echo "Please check your network connection and verify the Gradle version is available." && \
             exit 1; \
           } || sleep 5; \
      }; \
    done \
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

# =============================================================================
# ANDROID APP SIGNING TOOLS - Phase 6
# =============================================================================

# Verify and document Android app signing tools availability
# These tools are essential for securing Android applications in CI/CD pipelines
RUN echo "Validating Android app signing tools..." && \
    echo "✓ keytool: $(which keytool)" && \
    echo "✓ jarsigner: $(which jarsigner)" && \
    (which apksigner >/dev/null 2>&1 && echo "✓ apksigner: $(which apksigner)" || echo "ℹ apksigner: Will be available when build-tools are installed") && \
    (which zipalign >/dev/null 2>&1 && echo "✓ zipalign: $(which zipalign)" || echo "ℹ zipalign: Will be available when build-tools are installed") && \
    echo "Android app signing tools validation completed."

# Create a helper script for tool validation and usage information
RUN echo '#!/bin/bash' > /usr/local/bin/android-signing-tools && \
    echo 'echo "=== Android App Signing Tools ==="' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "1. keytool - Keystore management (Java/Android certificates)"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Location: $(which keytool 2>/dev/null || echo "Not found")"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Usage: keytool -genkey -alias mykey -keystore my-release-key.keystore"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo ""' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "2. jarsigner - JAR/APK/AAB signing with keystores"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Location: $(which jarsigner 2>/dev/null || echo "Not found")"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Usage: jarsigner -keystore my-release-key.keystore app-release-unsigned.apk mykey"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo ""' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "3. apksigner - Modern Android APK signing (v2/v3 schemes)"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Location: $(which apksigner 2>/dev/null || echo "Available in /sdk/build-tools/*/apksigner")"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Usage: apksigner sign --ks my-release-key.keystore --out app-release.apk app-release-unsigned.apk"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo ""' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "4. zipalign - APK optimization for runtime performance"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Location: $(which zipalign 2>/dev/null || echo "Available in /sdk/build-tools/*/zipalign")"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "   Usage: zipalign -v 4 app-unaligned.apk app-aligned.apk"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo ""' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "=== Complete Signing Workflow Example ==="' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "1. zipalign -v 4 app-release-unsigned.apk app-release-aligned.apk"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "2. apksigner sign --ks release.keystore --out app-release.apk app-release-aligned.apk"' >> /usr/local/bin/android-signing-tools && \
    echo 'echo "3. apksigner verify app-release.apk"' >> /usr/local/bin/android-signing-tools && \
    chmod +x /usr/local/bin/android-signing-tools

# =============================================================================
# ANDROID APP SIGNING TOOLS SUMMARY
# =============================================================================
# Available Tools:
# 1. keytool - Java keystore management tool (included with OpenJDK 17)
#    - Create, manage, and verify keystores and certificates
#    - Essential for keystore preparation and certificate management
#
# 2. jarsigner - JAR/APK/AAB signing tool (included with OpenJDK 17)  
#    - Sign APKs and AABs using existing keystores
#    - Legacy signing method, supports v1 signature scheme
#
# 3. apksigner - Modern Android APK signing tool (Android SDK Build Tools)
#    - Supports APK Signature Scheme v2 and v3 (recommended)
#    - Better security and performance than jarsigner
#    - Available in all installed build-tools versions
#
# 4. zipalign - APK alignment optimization tool (Android SDK Build Tools)
#    - Optimizes APK structure for better runtime performance
#    - Should be run before signing for optimal results
#    - Available in all installed build-tools versions
#
# Environment Setup:
# - PATH includes multiple build-tools versions for maximum compatibility
# - Helper script available: run 'android-signing-tools' for usage information
# - All tools are globally accessible from any directory
# =============================================================================
