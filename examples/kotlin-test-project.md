# Kotlin Android Test Project

This directory contains a minimal Kotlin Android project for testing the Docker image's Kotlin build capabilities with Gradle optimization.

## Project Structure

```
kotlin-test-project/
├── app/
│   ├── src/main/
│   │   ├── kotlin/com/example/kotlintest/
│   │   │   └── MainActivity.kt
│   │   └── AndroidManifest.xml
│   └── build.gradle.kts
├── gradle.properties
├── settings.gradle.kts
└── build.gradle.kts
```

## Files Content

### build.gradle.kts (Project level)
```kotlin
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}
```

### settings.gradle.kts
```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "KotlinTest"
include(":app")
```

### app/build.gradle.kts
```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.kotlintest"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.kotlintest"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
}
```

### app/src/main/kotlin/com/example/kotlintest/MainActivity.kt
```kotlin
package com.example.kotlintest

import android.app.Activity
import android.os.Bundle
import android.util.Log

class MainActivity : Activity() {
    
    companion object {
        private const val TAG = "KotlinTest"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val message = generateMessage()
        Log.i(TAG, message)
        
        // Test Kotlin features
        testKotlinFeatures()
    }
    
    private fun generateMessage(): String {
        return "Hello from Kotlin ${getKotlinVersion()} with Gradle optimization!"
    }
    
    private fun getKotlinVersion(): String {
        return kotlin.KotlinVersion.CURRENT.toString()
    }
    
    private fun testKotlinFeatures() {
        // Test data classes
        data class BuildInfo(val gradle: String, val kotlin: String, val optimization: Boolean)
        
        val buildInfo = BuildInfo(
            gradle = "9.0.0",
            kotlin = "2.1.0", 
            optimization = true
        )
        
        Log.i(TAG, "Build Info: $buildInfo")
        
        // Test extension functions
        fun String.isOptimized() = this.contains("optimization")
        
        val testMessage = "Gradle optimization enabled"
        Log.i(TAG, "Optimization status: ${testMessage.isOptimized()}")
        
        // Test lambda expressions
        val numbers = listOf(1, 2, 3, 4, 5)
        val doubled = numbers.map { it * 2 }
        Log.i(TAG, "Doubled numbers: $doubled")
    }
}
```

### app/src/main/AndroidManifest.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

### gradle.properties
```properties
# Project-specific Gradle properties
android.useAndroidX=true
android.enableJetifier=true

# Kotlin code style
kotlin.code.style=official

# Enable R8 full mode
android.enableR8.fullMode=true

# Build performance optimizations (these will be inherited from global config)
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
```

## Testing with Docker

```bash
# Build the Kotlin test project
docker run --rm -v $(pwd)/kotlin-test-project:/workspace -w /workspace \
  jangrewe/gitlab-ci-android:latest \
  gradle assembleDebug

# Test with Gradle wrapper (if gradlew exists)
docker run --rm -v $(pwd)/kotlin-test-project:/workspace -w /workspace \
  jangrewe/gitlab-ci-android:latest \
  ./gradlew assembleDebug

# Test build performance with cache
docker run --rm -v $(pwd)/kotlin-test-project:/workspace -w /workspace \
  -e GRADLE_USER_HOME=/workspace/.gradle \
  jangrewe/gitlab-ci-android:latest \
  gradle assembleDebug --build-cache --parallel
```

## Performance Testing

```bash
# Time the build process
docker run --rm -v $(pwd)/kotlin-test-project:/workspace -w /workspace \
  jangrewe/gitlab-ci-android:latest \
  bash -c "time gradle assembleDebug"

# Test incremental build
docker run --rm -v $(pwd)/kotlin-test-project:/workspace -w /workspace \
  jangrewe/gitlab-ci-android:latest \
  bash -c "gradle assembleDebug && touch app/src/main/kotlin/com/example/kotlintest/MainActivity.kt && time gradle assembleDebug"
```

This test project verifies:
- Kotlin 2.1.0 compilation with latest features
- Gradle 9.0.0 build system integration
- Performance optimizations (caching, parallel builds)
- Android Gradle Plugin 8.2.0 compatibility
- Kotlin-specific build optimizations
- Incremental compilation performance