## Overview

This Docker image contains the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI.

**Note**: As of version 3.1.0, the constraint-layout library is no longer included as an SDK package since it has moved to AndroidX. Add constraint-layout as a Gradle dependency in your `app/build.gradle` file:
```gradle
implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
```

Make sure your CI environment's caching works as expected, this greatly improves the build time, especially if you use multiple build jobs.

## Troubleshooting

### Docker Build Issues

**Gradle/Android SDK Download Errors**

If you encounter errors like "End-of-central-directory signature not found" or SSL certificate problems during the Docker build:

1. **Network Issues**: Ensure your build environment has stable internet access
2. **SSL Certificate Problems**: The image includes fallback logic for SSL issues, but in corporate environments you may need to:
   - Configure proxy settings properly
   - Mount custom CA certificates
   - Use pre-built images from Docker Hub instead of building locally

**Common Error Messages and Solutions:**

- `End-of-central-directory signature not found`: Corrupted download, the build will automatically retry
- `SSL certificate problem: self-signed certificate`: The build includes fallback insecure download logic
- `curl: (60) SSL certificate problem`: Check your network/proxy configuration

**Build Performance:**
- First build takes 10-15 minutes due to downloads (set adequate timeout in CI)
- Subsequent builds with Docker layer caching are much faster
- Use `docker pull gleidsonlm/gitlab-ci-android:latest` if local building fails

### Android Build Issues

**Gradle Memory Issues:**
```bash
# Increase Docker container memory or add to gradle.properties:
org.gradle.jvmargs=-Xmx4g -Xms2g
```

**Missing Dependencies:**
```bash
# Update your dependencies to use AndroidX if targeting API 28+
android.useAndroidX=true
android.enableJetifier=true
```

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
