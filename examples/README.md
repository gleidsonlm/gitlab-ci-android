# Simple NDK Test Project

This directory contains a minimal Android NDK project for testing the Docker image's native build capabilities.

## Project Structure

```
ndk-test-project/
├── app/
│   ├── src/main/
│   │   ├── cpp/
│   │   │   ├── CMakeLists.txt
│   │   │   └── native-lib.cpp
│   │   └── java/com/example/ndktest/
│   │       └── MainActivity.java
│   └── build.gradle
├── gradle.properties
└── build.gradle
```

## Files Content

### app/src/main/cpp/CMakeLists.txt
```cmake
cmake_minimum_required(VERSION 3.22.1)
project("ndktest")

add_library(native-lib SHARED native-lib.cpp)

find_library(log-lib log)
target_link_libraries(native-lib ${log-lib})
```

### app/src/main/cpp/native-lib.cpp
```cpp
#include <jni.h>
#include <string>
#include <android/log.h>

#define LOG_TAG "NDKTest"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_ndktest_MainActivity_stringFromJNI(JNIEnv *env, jobject /* this */) {
    std::string hello = "Hello from C++ with NDK 27!";
    LOGI("Native function called successfully");
    return env->NewStringUTF(hello.c_str());
}
```

### app/build.gradle
```gradle
android {
    compileSdk 33
    
    defaultConfig {
        applicationId "com.example.ndktest"
        minSdk 21
        targetSdk 33
        
        externalNativeBuild {
            cmake {
                cppFlags "-std=c++17"
            }
        }
        
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
    
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
            version "3.22.1"
        }
    }
}
```

## Testing with Docker

```bash
# Build the test project
docker run --rm -v $(pwd)/ndk-test-project:/workspace -w /workspace \
  gitlab-ci-android-ndk:latest \
  ./gradlew assembleDebug

# Verify native library was built
docker run --rm -v $(pwd)/ndk-test-project:/workspace -w /workspace \
  gitlab-ci-android-ndk:latest \
  find . -name "*.so" -type f
```

This test project verifies:
- CMake integration with Android NDK
- Multi-architecture builds (ARM64, ARM32)
- C++17 standard library support
- Android logging functionality
- Gradle NDK plugin integration