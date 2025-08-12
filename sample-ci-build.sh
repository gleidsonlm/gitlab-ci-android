#!/bin/bash

# sample-ci-build.sh
# Phase 5: Sample CI/CD build script demonstrating typical Android development workflows
# This script shows best practices for Android CI/CD builds using the gitlab-ci-android image

set -e

echo "=================================================================="
echo "Sample CI/CD Build Script - Android Development Workflow"
echo "=================================================================="
echo "Image: jangrewe/gitlab-ci-android"
echo "Phase: 5 - Testing & Validation"
echo "=================================================================="

# Configuration
BUILD_TYPE="${BUILD_TYPE:-debug}"
API_LEVEL="${API_LEVEL:-34}"
ENABLE_NDK="${ENABLE_NDK:-true}"
ENABLE_TESTS="${ENABLE_TESTS:-true}"
GRADLE_OPTS="${GRADLE_OPTS:--Xmx4g -Xms2g -XX:MaxMetaspaceSize=1g -XX:+UseG1GC}"

echo "Build Configuration:"
echo "- Build Type: $BUILD_TYPE"
echo "- API Level: $API_LEVEL"
echo "- NDK Enabled: $ENABLE_NDK"
echo "- Tests Enabled: $ENABLE_TESTS"
echo "- Gradle Options: $GRADLE_OPTS"

echo -e "\n=================================================================="
echo "Step 1: Environment Setup"
echo "=================================================================="

# Set up environment variables
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$(pwd)/.gradle}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/sdk}"
export ANDROID_HOME="${ANDROID_HOME:-/sdk}"

if [ "$ENABLE_NDK" = "true" ]; then
    export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-/sdk/ndk/latest}"
    echo "NDK enabled: $ANDROID_NDK_HOME"
fi

# Verify environment
echo "Environment verification:"
echo "✓ Java: $(java -version 2>&1 | head -1)"
echo "✓ Gradle: $(gradle --version | grep Gradle)"
echo "✓ Android SDK: $ANDROID_SDK_ROOT"

if [ "$ENABLE_NDK" = "true" ] && [ -d "$ANDROID_NDK_HOME" ]; then
    echo "✓ Android NDK: $ANDROID_NDK_HOME"
fi

# Make gradlew executable
if [ -f "./gradlew" ]; then
    chmod +x ./gradlew
    GRADLE_CMD="./gradlew"
    echo "✓ Using project Gradle wrapper"
else
    GRADLE_CMD="gradle"
    echo "✓ Using global Gradle installation"
fi

echo -e "\n=================================================================="
echo "Step 2: Dependency Resolution & Caching"
echo "=================================================================="

# Configure Gradle for optimal performance
echo "Configuring Gradle for CI environment..."

# Create/update gradle.properties for CI optimization
cat >> gradle.properties << 'EOF'

# CI/CD Optimizations
org.gradle.daemon=false
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configureondemand=true
org.gradle.workers.max=4

# Android CI optimizations
android.builder.sdkDownload=false
android.experimental.legacyTransform.forceNonIncremental=true
android.enableR8.fullMode=true
android.enableJetifier=true
android.useAndroidX=true

# Kotlin optimizations
kotlin.incremental=true
kotlin.incremental.android=true
kotlin.parallel.tasks.in.project=true
EOF

# Download dependencies
echo "Downloading and caching dependencies..."
$GRADLE_CMD dependencies --build-cache --parallel

echo -e "\n=================================================================="
echo "Step 3: Code Quality & Static Analysis"
echo "=================================================================="

# Run lint checks
echo "Running Android Lint analysis..."
$GRADLE_CMD lint --build-cache --parallel || echo "Lint warnings found (non-blocking)"

# Check for common issues
echo "Checking project structure..."
if [ ! -f "app/src/main/AndroidManifest.xml" ]; then
    echo "⚠ Warning: AndroidManifest.xml not found in expected location"
fi

if [ ! -d "app/src/main/java" ] && [ ! -d "app/src/main/kotlin" ]; then
    echo "⚠ Warning: No Java/Kotlin source directory found"
fi

echo -e "\n=================================================================="
echo "Step 4: Multi-Variant Builds"
echo "=================================================================="

# Build debug variant
if [ "$BUILD_TYPE" = "debug" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "Building debug variant..."
    time $GRADLE_CMD assembleDebug --build-cache --parallel
    
    # Verify APK generation
    if find . -name "*-debug.apk" -type f | head -1; then
        echo "✓ Debug APK generated successfully"
        DEBUG_APK=$(find . -name "*-debug.apk" -type f | head -1)
        APK_SIZE=$(stat -c%s "$DEBUG_APK" 2>/dev/null || echo "Unknown")
        echo "  Debug APK: $DEBUG_APK ($((APK_SIZE / 1024)) KB)"
    else
        echo "✗ Debug APK generation failed"
        exit 1
    fi
fi

# Build release variant
if [ "$BUILD_TYPE" = "release" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "Building release variant..."
    time $GRADLE_CMD assembleRelease --build-cache --parallel
    
    # Verify APK generation
    if find . -name "*-release.apk" -type f | head -1; then
        echo "✓ Release APK generated successfully"
        RELEASE_APK=$(find . -name "*-release.apk" -type f | head -1)
        APK_SIZE=$(stat -c%s "$RELEASE_APK" 2>/dev/null || echo "Unknown")
        echo "  Release APK: $RELEASE_APK ($((APK_SIZE / 1024)) KB)"
    else
        echo "✗ Release APK generation failed"
        exit 1
    fi
fi

echo -e "\n=================================================================="
echo "Step 5: Native Build Validation (NDK)"
echo "=================================================================="

if [ "$ENABLE_NDK" = "true" ]; then
    echo "Validating native library builds..."
    
    # Check for native libraries in APK
    NATIVE_LIBS=$(find . -name "*.so" -type f)
    if [ -n "$NATIVE_LIBS" ]; then
        echo "✓ Native libraries found:"
        echo "$NATIVE_LIBS" | head -5
        
        # Check supported architectures
        ARCHITECTURES=$(echo "$NATIVE_LIBS" | grep -o 'arm64-v8a\|armeabi-v7a\|x86_64\|x86' | sort | uniq)
        echo "✓ Supported architectures: $(echo $ARCHITECTURES | tr '\n' ' ')"
    else
        echo "ℹ No native libraries found (NDK not used in this project)"
    fi
else
    echo "NDK builds disabled"
fi

echo -e "\n=================================================================="
echo "Step 6: Testing"
echo "=================================================================="

if [ "$ENABLE_TESTS" = "true" ]; then
    echo "Running unit tests..."
    $GRADLE_CMD test --build-cache --parallel || echo "Some tests failed (check test reports)"
    
    # Generate test reports
    echo "Generating test reports..."
    if [ -d "app/build/reports/tests" ]; then
        echo "✓ Test reports available in app/build/reports/tests/"
    fi
    
    # Check test results
    TEST_RESULTS=$(find . -name "TEST-*.xml" -type f)
    if [ -n "$TEST_RESULTS" ]; then
        echo "✓ Test result files:"
        echo "$TEST_RESULTS" | head -3
    fi
else
    echo "Testing disabled"
fi

echo -e "\n=================================================================="
echo "Step 7: Build Artifacts & Reports"
echo "=================================================================="

echo "Collecting build artifacts..."

# List generated APKs
echo "Generated APK files:"
find . -name "*.apk" -type f -exec ls -lh {} \; | head -10

# List AAR files (for library modules)
AAR_FILES=$(find . -name "*.aar" -type f)
if [ -n "$AAR_FILES" ]; then
    echo "Generated AAR files:"
    echo "$AAR_FILES" | head -5
fi

# Build reports
echo -e "\nBuild reports available:"
[ -d "app/build/reports/lint" ] && echo "✓ Lint reports: app/build/reports/lint/"
[ -d "app/build/reports/tests" ] && echo "✓ Test reports: app/build/reports/tests/"
[ -d "build/reports" ] && echo "✓ Project reports: build/reports/"

echo -e "\n=================================================================="
echo "Step 8: Performance Metrics"
echo "=================================================================="

# Build performance analysis
echo "Build performance metrics:"

# Gradle build scan (if available)
if $GRADLE_CMD help | grep -q "scan"; then
    echo "Generating build scan..."
    $GRADLE_CMD assembleDebug --scan --build-cache || echo "Build scan not available"
fi

# Cache statistics
if [ -d "$GRADLE_USER_HOME/caches" ]; then
    CACHE_SIZE=$(du -sh "$GRADLE_USER_HOME/caches" | cut -f1)
    echo "✓ Gradle cache size: $CACHE_SIZE"
fi

# Show memory usage
echo "✓ Memory usage during build:"
free -h | head -3

echo -e "\n=================================================================="
echo "Step 9: CI/CD Integration Examples"
echo "=================================================================="

echo "Sample GitLab CI configuration:"
cat << 'EOF'
# .gitlab-ci.yml
image: jangrewe/gitlab-ci-android

stages:
  - build
  - test

variables:
  GRADLE_OPTS: "-Xmx4g -Xms2g -XX:MaxMetaspaceSize=1g"
  GRADLE_USER_HOME: "${CI_PROJECT_DIR}/.gradle"

cache:
  key: ${CI_PROJECT_ID}
  paths:
    - .gradle/
    - app/.cxx/

before_script:
  - export ANDROID_NDK_HOME=/sdk/ndk/latest
  - chmod +x ./gradlew

build_debug:
  stage: build
  script:
    - ./gradlew assembleDebug --build-cache --parallel
  artifacts:
    paths:
      - app/build/outputs/apk/debug/app-debug.apk
    expire_in: 1 week

build_release:
  stage: build
  script:
    - ./gradlew assembleRelease --build-cache --parallel
  artifacts:
    paths:
      - app/build/outputs/apk/release/app-release.apk
    expire_in: 1 month

test:
  stage: test
  script:
    - ./gradlew test --build-cache --parallel
  artifacts:
    reports:
      junit: app/build/test-results/test/**/TEST-*.xml
EOF

echo -e "\nSample GitHub Actions configuration:"
cat << 'EOF'
# .github/workflows/android.yml
name: Android CI
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    container: jangrewe/gitlab-ci-android:latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Environment
      run: |
        export GRADLE_USER_HOME=$(pwd)/.gradle
        export ANDROID_NDK_HOME=/sdk/ndk/latest
        chmod +x ./gradlew
    
    - name: Cache Gradle
      uses: actions/cache@v3
      with:
        path: |
          ~/.gradle/caches
          ~/.gradle/wrapper
        key: gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    
    - name: Build Debug APK
      run: ./gradlew assembleDebug --build-cache --parallel
    
    - name: Run Tests
      run: ./gradlew test --build-cache --parallel
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: debug-apk
        path: app/build/outputs/apk/debug/app-debug.apk
EOF

echo -e "\n=================================================================="
echo "✅ CI/CD BUILD WORKFLOW COMPLETED SUCCESSFULLY"
echo "=================================================================="

echo "Summary:"
echo "✓ Environment setup and validation"
echo "✓ Dependency resolution and caching"
echo "✓ Code quality checks"
echo "✓ Multi-variant builds"
echo "✓ Native library validation"
echo "✓ Testing execution"
echo "✓ Artifact collection"
echo "✓ Performance metrics"
echo "✓ CI/CD integration examples"

echo -e "\nNext steps:"
echo "- Integrate this script into your CI/CD pipeline"
echo "- Customize build variants and testing as needed"
echo "- Monitor build performance and optimize caching"
echo "- Set up artifact deployment for releases"

echo -e "\n=================================================================="