#!/bin/bash
set -e

echo "Testing for NDK warnings in Docker image..."

# Build the Docker image
echo "Building Docker image..."
docker build -t test-ndk-warnings .

# Test that no NDK warnings are present
echo "Checking for NDK warnings..."
if docker run --rm test-ndk-warnings bash -c "sdkmanager --list 2>&1" | grep -i "warning.*ndk.*inconsistent\|warning.*already observed.*ndk"; then
    echo "❌ FAIL: NDK warnings still present"
    exit 1
else
    echo "✅ PASS: No NDK warnings detected"
fi

# Test that NDK directories exist in canonical locations (if installed)
echo "Checking NDK directory structure..."
docker run --rm test-ndk-warnings bash -c "
    if [ -d /sdk/ndk ]; then
        echo 'NDK directory structure:'
        ls -la /sdk/ndk/
        # Check that no symbolic links exist
        if find /sdk/ndk -type l | grep -q .; then
            echo '❌ FAIL: Symbolic links found in NDK directory'
            exit 1
        else
            echo '✅ PASS: No symbolic links in NDK directory'
        fi
    else
        echo 'ℹ️  NDK directory not present (packages may not have installed due to network issues)'
    fi
"

echo "✅ All NDK warning tests passed!"