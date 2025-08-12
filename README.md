## Overview

This Docker image contains the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI.

**Note**: As of version 3.1.0, the constraint-layout library is no longer included as an SDK package since it has moved to AndroidX. Add constraint-layout as a Gradle dependency in your `app/build.gradle` file:
```gradle
implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
```

Make sure your CI environment's caching works as expected, this greatly improves the build time, especially if you use multiple build jobs.

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
