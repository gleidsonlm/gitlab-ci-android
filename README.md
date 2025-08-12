# gitlab-ci-android

## Phase 2: Toolchain Modernization

This Docker image has been further modernized in Phase 2 with comprehensive Android SDK updates:

### Latest Android SDK Support
- **Android API 34** (Android 14) - Latest stable release with cutting-edge features
- **Android API 33** (Android 13) - Previous stable release for broad compatibility  
- **Android API 32** (Android 12L) - Extended support for tablets and foldable devices

### Build Tools Updates
- **Build Tools 34.0.0** - Latest optimizations and features for API 34
- **Build Tools 33.0.2** - Stable and widely adopted for API 33 projects
- **Build Tools 32.0.0** - Legacy support for API 32 compatibility

### Enhanced packages.txt
The `packages.txt` file has been completely refactored with:
- **Comprehensive documentation** - Each SDK component is fully commented
- **Multiple API levels** - Support for Android 32, 33, and 34
- **Latest build tools** - Updated to most recent stable versions
- **Organized structure** - Grouped by functionality for easy maintenance

### NDK Integration Readiness
Phase 2 includes preparation for upcoming Native Development Kit (NDK) integration:
- **Structured placeholders** in Dockerfile for Phase 3 NDK installation
- **Planned NDK versions**: 26.1.10909125 (latest) and 25.2.9519653 (compatibility)
- **Native development support** for C/C++ Android applications

## Phase 1: Modernization

This Docker image has been modernized with the following updates:

- **Base Image**: Ubuntu 22.04 LTS (upgraded from Ubuntu 20.04)
- **Java Version**: OpenJDK 17 (upgraded from OpenJDK 11)
- **Compatibility**: Fully compatible with latest Android SDK tools
- **Build Optimizations**: Improved Dockerfile structure following current best practices

### Minimum Requirements

- **Java 17**: Required for the latest Android build tools and Gradle versions
- **Ubuntu 22.04**: Provides latest security updates and package versions
- **Docker**: Compatible with Docker Engine 20.10+ and Docker Compose v2

## Overview

This Docker image contains the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI. Make sure your CI environment's caching works as expected, this greatly improves the build time, especially if you use multiple build jobs.

## Usage Examples

### Targeting Latest Android API (34)

To build your Android project targeting the latest API level:

```yaml
image: jangrewe/gitlab-ci-android

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
  image: jangrewe/gitlab-ci-android
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
image: jangrewe/gitlab-ci-android

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

## Version Information

Current version: **2.1.0** (see [VERSION](VERSION) file)

### Changelog

#### v2.1.0 - Phase 2: Toolchain Modernization
- **Android API Support**: Added support for Android API 34 (Android 14), 33, and 32
- **Build Tools Update**: Updated to build-tools 34.0.0, 33.0.2, and 32.0.0
- **Enhanced packages.txt**: Comprehensive documentation and organized structure
- **NDK Preparation**: Added structured placeholders and documentation for Phase 3 NDK integration
- **Multi-API Targeting**: Enhanced CI examples for building across multiple Android versions
- **Toolchain Validation**: Confirmed Java 17 compatibility with latest Android SDK

#### v2.0.0 - Phase 1 Modernization
- Updated base image from Ubuntu 20.04 to Ubuntu 22.04 LTS
- Upgraded Java from OpenJDK 11 to OpenJDK 17
- Updated Android SDK command-line tools for Java 17 compatibility
- Improved Dockerfile following modern best practices
- Enhanced documentation and added semantic versioning

## Android SDK Components

### Supported API Levels
- **API 34 (Android 14)**: Latest stable release with enhanced performance and security
- **API 33 (Android 13)**: Stable release with refined Material You design
- **API 32 (Android 12L)**: Optimized for large screens and foldable devices

### Installed Build Tools
- **34.0.0**: Latest build tools with new optimizations and bug fixes
- **33.0.2**: Stable and widely adopted version
- **32.0.0**: Maintained for legacy project compatibility

### Additional Components
- **Google APIs 24**: Backward compatibility support
- **Android Support Repository**: Required for support libraries
- **Google Repository**: Google Play Services and Firebase integration
- **Google Play Services**: Essential services for modern Android apps
- **Constraint Layout**: Modern layout system support

For complete details on installed packages, see the documented [packages.txt](packages.txt) file.
