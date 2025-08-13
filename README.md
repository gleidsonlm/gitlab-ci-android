## Overview

This Docker image contains the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI.

## NDK Best Practices

**Important:** This image uses canonical NDK paths to avoid SDK Manager warnings:
- NDK 27.3.13750724: `/sdk/ndk/27.3.13750724` (latest stable)
- NDK 26.3.11579264: `/sdk/ndk/26.3.11579264` (previous stable)

**No symbolic links** are created (e.g., `/sdk/ndk/latest`) to prevent Android SDK Manager from detecting duplicate package IDs. When referencing NDK in your builds, use the full canonical paths.

## Usage Examples

### Targeting Latest Android API (34)

To build your Android project targeting the latest API level:

```yaml
image: gleidsonlm/gitlab-ci-android

stages:
- build

before_script:
- export GRADLE_USER_HOME=$(pwd)/.gradle
- chmod +x ./gradlew

cache:
  key: ${CI_PROJECT_ID}
  paths:
  - .gradle/

build_api34:
  stage: build
  script:
  - ./gradlew assembleDebug -PtargetSdkVersion=34 -PcompileSdkVersion=34
  artifacts:
    paths:
    - app/build/outputs/apk/app-debug.apk
```

### Multi-API Compatibility Testing

Build and test across multiple Android API levels:

```yaml
.build_template: &build_template
  image: gleidsonlm/gitlab-ci-android
  before_script:
  - export GRADLE_USER_HOME=$(pwd)/.gradle
  - chmod +x ./gradlew
  cache:
    key: ${CI_PROJECT_ID}-${API_LEVEL}
    paths:
    - .gradle/
  script:
  - ./gradlew assembleDebug -PtargetSdkVersion=${API_LEVEL} -PcompileSdkVersion=${API_LEVEL}

build_api34:
  <<: *build_template
  variables:
    API_LEVEL: "34"

build_api33:
  <<: *build_template  
  variables:
    API_LEVEL: "33"

build_api32:
  <<: *build_template
  variables:
    API_LEVEL: "32"
```

### Basic Usage Example

A `.gitlab-ci.yml` with caching of your project's dependencies would look like this:

```yaml
image: gleidsonlm/gitlab-ci-android

stages:
- build

before_script:
- export GRADLE_USER_HOME=$(pwd)/.gradle
- chmod +x ./gradlew

cache:
  key: ${CI_PROJECT_ID}
  paths:
  - .gradle/

build:
  stage: build
  script:
  - ./gradlew assembleDebug
  artifacts:
    paths:
    - app/build/outputs/apk/app-debug.apk
```

For complete details on installed packages, see the documented [packages.txt](packages.txt) file.
