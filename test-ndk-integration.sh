#!/bin/bash
# NDK Integration Test Script for gitlab-ci-android Docker Image
# This script validates that all NDK components are properly installed and configured

echo "==================================="
echo "NDK Integration Test Script"
echo "==================================="

# Test 1: Java Version
echo "1. Testing Java installation..."
docker run --rm jangrewe/gitlab-ci-android:latest java -version
echo "✓ Java test completed"
echo ""

# Test 2: Android SDK
echo "2. Testing Android SDK..."
docker run --rm jangrewe/gitlab-ci-android:latest sdkmanager --list | head -10
echo "✓ Android SDK test completed"
echo ""

# Test 3: NDK Environment Variables
echo "3. Testing NDK environment variables..."
docker run --rm jangrewe/gitlab-ci-android:latest bash -c '
echo "ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
echo "ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo "NDK Latest: $(readlink /sdk/ndk/latest)"
echo "NDK Previous: $(readlink /sdk/ndk/previous)"
'
echo "✓ NDK environment test completed"
echo ""

# Test 4: NDK Installation
echo "4. Testing NDK installation..."
docker run --rm jangrewe/gitlab-ci-android:latest bash -c '
if [ -d "$ANDROID_NDK_HOME" ]; then
    echo "✓ NDK 27 installed at: $ANDROID_NDK_HOME"
    ls -la $ANDROID_NDK_HOME/build/cmake/
else
    echo "✗ NDK 27 not found"
fi

if [ -d "/sdk/ndk/26.3.11579264" ]; then
    echo "✓ NDK 26 installed at: /sdk/ndk/26.3.11579264"
else
    echo "✗ NDK 26 not found"
fi
'
echo "✓ NDK installation test completed"
echo ""

# Test 5: CMake
echo "5. Testing CMake installation..."
docker run --rm jangrewe/gitlab-ci-android:latest cmake --version
echo "✓ CMake test completed"
echo ""

# Test 6: Ninja
echo "6. Testing Ninja installation..."
docker run --rm jangrewe/gitlab-ci-android:latest ninja --version
echo "✓ Ninja test completed"
echo ""

# Test 7: Clang
echo "7. Testing Clang installation..."
docker run --rm jangrewe/gitlab-ci-android:latest clang --version
echo "✓ Clang test completed"
echo ""

# Test 8: NDK-Build
echo "8. Testing ndk-build..."
docker run --rm jangrewe/gitlab-ci-android:latest bash -c '
if [ -f "$ANDROID_NDK_HOME/ndk-build" ]; then
    $ANDROID_NDK_HOME/ndk-build --version
    echo "✓ ndk-build is available"
else
    echo "✗ ndk-build not found"
fi
'
echo "✓ NDK-Build test completed"
echo ""

# Test 9: Environment Setup Script
echo "9. Testing NDK environment setup script..."
docker run --rm jangrewe/gitlab-ci-android:latest bash -c '
if [ -f "/usr/local/bin/ndk-env" ]; then
    echo "✓ NDK environment script exists"
    cat /usr/local/bin/ndk-env
else
    echo "✗ NDK environment script not found"
fi
'
echo "✓ Environment setup test completed"
echo ""

echo "==================================="
echo "NDK Integration Test Completed"
echo "==================================="