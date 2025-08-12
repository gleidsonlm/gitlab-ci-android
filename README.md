# gitlab-ci-android

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

## Usage Example

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

Current version: **2.0.0** (see [VERSION](VERSION) file)

### Changelog

#### v2.0.0 - Phase 1 Modernization
- Updated base image from Ubuntu 20.04 to Ubuntu 22.04 LTS
- Upgraded Java from OpenJDK 11 to OpenJDK 17
- Updated Android SDK command-line tools for Java 17 compatibility
- Improved Dockerfile following modern best practices
- Enhanced documentation and added semantic versioning
