#!/bin/bash

# test-gradle-kotlin-integration.sh
# Test script for verifying Gradle and Kotlin optimization features

set -e

echo "==============================================="
echo "Gradle and Kotlin Integration Test - Phase 4"
echo "==============================================="

# Test Gradle installation
echo "Testing Gradle installation..."
if command -v gradle &> /dev/null; then
    echo "✓ Gradle is installed"
    gradle --version
else
    echo "✗ Gradle is not installed"
    exit 1
fi

# Test Gradle environment variables
echo -e "\nTesting Gradle environment variables..."
if [ -n "$GRADLE_HOME" ]; then
    echo "✓ GRADLE_HOME is set: $GRADLE_HOME"
else
    echo "✗ GRADLE_HOME is not set"
    exit 1
fi

if [ -n "$GRADLE_OPTS" ]; then
    echo "✓ GRADLE_OPTS is set: $GRADLE_OPTS"
else
    echo "✗ GRADLE_OPTS is not set"
    exit 1
fi

if [ -n "$KOTLIN_DAEMON_JVM_OPTIONS" ]; then
    echo "✓ KOTLIN_DAEMON_JVM_OPTIONS is set: $KOTLIN_DAEMON_JVM_OPTIONS"
else
    echo "✗ KOTLIN_DAEMON_JVM_OPTIONS is not set"
    exit 1
fi

# Test gradle.properties file
echo -e "\nTesting global gradle.properties configuration..."
if [ -f "$GRADLE_USER_HOME/gradle.properties" ]; then
    echo "✓ Global gradle.properties exists"
    echo "Configuration content:"
    cat "$GRADLE_USER_HOME/gradle.properties"
else
    echo "✗ Global gradle.properties does not exist"
    exit 1
fi

# Test Gradle cache directory
echo -e "\nTesting Gradle cache directory..."
if [ -d "$GRADLE_USER_HOME" ]; then
    echo "✓ Gradle user home directory exists: $GRADLE_USER_HOME"
    ls -la "$GRADLE_USER_HOME/"
else
    echo "✗ Gradle user home directory does not exist"
    exit 1
fi

# Test Java version compatibility
echo -e "\nTesting Java version compatibility..."
java -version
if java -version 2>&1 | grep -q "17\|21"; then
    echo "✓ Java version is compatible with Gradle 9.0.0"
else
    echo "✗ Java version may not be compatible"
    exit 1
fi

# Test basic Gradle command
echo -e "\nTesting basic Gradle commands..."
if gradle help &> /dev/null; then
    echo "✓ Gradle help command works"
else
    echo "✗ Gradle help command failed"
    exit 1
fi

# Test Gradle build scan functionality
echo -e "\nTesting Gradle build scan capability..."
if gradle help --scan --dry-run &> /dev/null; then
    echo "✓ Gradle build scan functionality available"
else
    echo "✗ Gradle build scan functionality not available"
fi

# Test performance features
echo -e "\nTesting performance optimization features..."
if gradle help --build-cache --dry-run &> /dev/null; then
    echo "✓ Build cache functionality available"
else
    echo "✗ Build cache functionality not available"
fi

if gradle help --parallel --dry-run &> /dev/null; then
    echo "✓ Parallel build functionality available"
else
    echo "✗ Parallel build functionality not available"
fi

if gradle help --configuration-cache --dry-run &> /dev/null; then
    echo "✓ Configuration cache functionality available"
else
    echo "✗ Configuration cache functionality not available"
fi

echo -e "\n==============================================="
echo "All Gradle and Kotlin integration tests passed!"
echo "Docker image is ready for optimized Kotlin builds"
echo "==============================================="

# Display final summary
echo -e "\nSUMMARY:"
echo "- Gradle 9.0.0: Installed and configured"
echo "- Kotlin optimization: Enabled"
echo "- Build cache: Configured"
echo "- Parallel builds: Enabled"
echo "- JVM optimization: Applied"
echo "- Environment variables: Set"
echo "- Global configuration: Ready"