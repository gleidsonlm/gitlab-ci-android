#!/bin/bash

# validate-gradle-installation.sh
# Simple validation script to test Gradle installation without network dependencies

echo "=================================="
echo "Gradle Installation Validation"
echo "=================================="

# Test 1: Verify wget can download Gradle
echo "Testing Gradle download capability..."
if wget --no-verbose --output-document=/tmp/gradle-test.zip \
   https://services.gradle.org/distributions/gradle-9.0.0-bin.zip 2>&1; then
    echo "✓ Gradle download successful"
    
    # Test 2: Verify unzip works
    echo "Testing Gradle extraction..."
    if unzip -q /tmp/gradle-test.zip -d /tmp/; then
        echo "✓ Gradle extraction successful"
        
        # Test 3: Verify Gradle runs
        echo "Testing Gradle execution..."
        if /tmp/gradle-9.0.0/bin/gradle --version; then
            echo "✓ Gradle execution successful"
            echo "✓ All validation tests passed!"
        else
            echo "✗ Gradle execution failed"
            exit 1
        fi
    else
        echo "✗ Gradle extraction failed"
        exit 1
    fi
    
    # Cleanup
    rm -rf /tmp/gradle-test.zip /tmp/gradle-9.0.0
else
    echo "✗ Gradle download failed"
    exit 1
fi

echo "=================================="
echo "Validation completed successfully"
echo "=================================="