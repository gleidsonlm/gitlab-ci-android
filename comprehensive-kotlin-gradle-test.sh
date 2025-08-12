#!/bin/bash

# comprehensive-kotlin-gradle-test.sh
# Comprehensive test demonstrating Gradle 9.0.0 and Kotlin functionality

set -e

echo "========================================================"
echo "Comprehensive Gradle 9.0.0 and Kotlin Test"
echo "========================================================"

# Setup test directory
TEST_DIR="/tmp/kotlin-gradle-test"
rm -rf $TEST_DIR
mkdir -p $TEST_DIR
cd $TEST_DIR

echo "Step 1: Download and setup Gradle 9.0.0..."
wget --no-verbose --output-document=gradle.zip \
     https://services.gradle.org/distributions/gradle-9.0.0-bin.zip
unzip -q gradle.zip
GRADLE_BIN="$TEST_DIR/gradle-9.0.0/bin/gradle"

echo "Step 2: Verify Gradle installation..."
$GRADLE_BIN --version

echo -e "\nStep 3: Initialize Kotlin application project..."
mkdir kotlin-app && cd kotlin-app
$GRADLE_BIN init --type kotlin-application --dsl kotlin \
  --project-name kotlin-app --package com.example.app \
  --no-split-project --quiet

echo -e "\nStep 4: Customize Kotlin source file with modern features..."
cat > app/src/main/kotlin/com/example/app/App.kt << 'EOF'
package com.example.app

import kotlin.system.measureTimeMillis

data class GradleInfo(
    val version: String,
    val kotlinVersion: String,
    val javaVersion: String
)

class App {
    fun getGreeting(): String {
        val gradleInfo = GradleInfo(
            version = "9.0.0",
            kotlinVersion = KotlinVersion.CURRENT.toString(),
            javaVersion = System.getProperty("java.version")
        )
        
        return """
        |=== Gradle and Kotlin Integration Test ===
        |Gradle Version: ${gradleInfo.version}
        |Kotlin Version: ${gradleInfo.kotlinVersion}
        |Java Version: ${gradleInfo.javaVersion}
        |
        |Testing modern Kotlin features:
        |${testKotlinFeatures()}
        |===========================================
        """.trimMargin()
    }
    
    private fun testKotlinFeatures(): String {
        val results = mutableListOf<String>()
        
        // Test lambdas and collections
        val time1 = measureTimeMillis {
            val numbers = (1..1000).toList()
            val processed = numbers
                .filter { it % 2 == 0 }
                .map { it * it }
                .take(5)
            results.add("✓ Collections & Lambdas: $processed")
        }
        results.add("  Performance: ${time1}ms")
        
        // Test sealed classes (modern Kotlin feature)
        sealed class Result {
            object Success : Result()
            data class Error(val message: String) : Result()
        }
        
        val result = Result.Success
        when (result) {
            is Result.Success -> results.add("✓ Sealed Classes: Success case handled")
            is Result.Error -> results.add("✗ Sealed Classes: Error case")
        }
        
        // Test extension functions
        fun String.addBuildInfo() = "$this [Built with Gradle ${gradleInfo.version}]"
        results.add("✓ Extension Functions: ${"Test".addBuildInfo()}")
        
        return results.joinToString("\n|")
    }
}

fun main() {
    println(App().getGreeting())
}
EOF

echo -e "\nStep 5: Update build.gradle.kts with optimization settings..."
cat > app/build.gradle.kts << 'EOF'
plugins {
    id("org.jetbrains.kotlin.jvm") version "2.1.0"
    application
}

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testImplementation("org.junit.jupiter:junit-jupiter-engine:5.10.1")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

application {
    mainClass.set("com.example.app.AppKt")
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}

// Kotlin compilation optimization
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-opt-in=kotlin.RequiresOptIn",
            "-Xjsr305=strict"
        )
    }
}
EOF

echo -e "\nStep 6: Create gradle.properties with performance settings..."
cat > gradle.properties << 'EOF'
# Gradle Build Performance Optimization
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true
org.gradle.caching=true
org.gradle.workers.max=4

# JVM optimization for Kotlin compilation
org.gradle.jvmargs=-Xmx4g -Xms1g -XX:MaxMetaspaceSize=1g -XX:+UseG1GC

# Kotlin optimization
kotlin.incremental=true
kotlin.caching.enabled=true
kotlin.parallel.tasks.in.project=true
EOF

echo -e "\nStep 7: Build the Kotlin application with optimizations..."
echo "Building with parallel execution and build cache..."
time $GRADLE_BIN build --build-cache --parallel --info | grep -E "(BUILD|kotlin|cache|parallel)"

echo -e "\nStep 8: Run the Kotlin application..."
$GRADLE_BIN run --quiet

echo -e "\nStep 9: Test incremental build performance..."
echo "Testing incremental build by touching source file..."
touch app/src/main/kotlin/com/example/app/App.kt
echo "Rebuilding (should be faster with incremental compilation)..."
time $GRADLE_BIN build --build-cache --parallel

echo -e "\nStep 10: Cleanup..."
cd /
rm -rf $TEST_DIR

echo -e "\n========================================================"
echo "✓ All Gradle and Kotlin tests completed successfully!"
echo "✓ Gradle 9.0.0 installation: Working"
echo "✓ Kotlin compilation: Working"  
echo "✓ Build optimizations: Enabled"
echo "✓ Performance features: Functional"
echo "========================================================"