## Overview

This Docker image contains the Android SDK and most common packages necessary for building Android apps in a CI tool like GitLab CI.

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

## Android App Signing Tools

This image includes all essential Android app signing and validation tools for secure CI/CD pipelines:

### Available Tools

#### 1. keytool
- **Purpose**: Java keystore management and certificate operations
- **Location**: Included with OpenJDK 17, globally accessible
- **Usage**: Create, manage, and verify keystores and certificates

```bash
# Create a new keystore
keytool -genkey -alias mykey -keystore my-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000

# List keystore contents
keytool -list -keystore my-release-key.keystore

# Verify certificate details
keytool -list -v -keystore my-release-key.keystore -alias mykey
```

#### 2. jarsigner
- **Purpose**: Sign JAR files, APKs, and AABs using keystores
- **Location**: Included with OpenJDK 17, globally accessible
- **Usage**: Legacy signing method supporting APK Signature Scheme v1

```bash
# Sign an APK with jarsigner
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.keystore app-release-unsigned.apk mykey

# Verify APK signature
jarsigner -verify -verbose -certs app-release-signed.apk
```

#### 3. apksigner
- **Purpose**: Modern Android APK signing tool with advanced signature schemes
- **Location**: Android SDK Build Tools (34.0.0, 33.0.2, 32.0.0)
- **Usage**: Recommended for APK signing with v2/v3 signature scheme support

```bash
# Sign an APK with apksigner (recommended)
apksigner sign --ks my-release-key.keystore --out app-release.apk app-release-unsigned.apk

# Sign with specific key alias
apksigner sign --ks my-release-key.keystore --ks-key-alias mykey --out app-release.apk app-release-unsigned.apk

# Verify APK signatures (all schemes)
apksigner verify --verbose app-release.apk

# Check signature details
apksigner verify --print-certs app-release.apk
```

#### 4. zipalign
- **Purpose**: Optimize APK file alignment for better runtime performance
- **Location**: Android SDK Build Tools (34.0.0, 33.0.2, 32.0.0)
- **Usage**: Align APK data for optimal memory usage (run before signing)

```bash
# Align an APK (4-byte alignment)
zipalign -v 4 app-release-unaligned.apk app-release-aligned.apk

# Check if APK is already aligned
zipalign -c -v 4 app-release.apk
```

### Complete Signing Workflow

Here's the recommended workflow for signing Android APKs in CI/CD:

```yaml
image: gleidsonlm/gitlab-ci-android

stages:
  - build
  - sign

variables:
  KEYSTORE_FILE: "release.keystore"
  KEY_ALIAS: "mykey"

before_script:
  - export GRADLE_USER_HOME=$(pwd)/.gradle
  - chmod +x ./gradlew

build:
  stage: build
  script:
    - ./gradlew assembleRelease
  artifacts:
    paths:
      - app/build/outputs/apk/release/app-release-unsigned.apk
    expire_in: 1 hour

sign_apk:
  stage: sign
  dependencies:
    - build
  before_script:
    # Decode keystore from CI/CD variables (base64 encoded)
    - echo "$KEYSTORE_BASE64" | base64 -d > $KEYSTORE_FILE
  script:
    # Step 1: Align the APK for optimal performance
    - zipalign -v 4 app/build/outputs/apk/release/app-release-unsigned.apk app-release-aligned.apk
    
    # Step 2: Sign the aligned APK with apksigner (recommended)
    - apksigner sign 
        --ks $KEYSTORE_FILE 
        --ks-key-alias $KEY_ALIAS 
        --ks-pass env:KEYSTORE_PASSWORD 
        --key-pass env:KEY_PASSWORD 
        --out app-release-signed.apk 
        app-release-aligned.apk
    
    # Step 3: Verify the signature
    - apksigner verify --verbose app-release-signed.apk
    
    # Step 4: Display certificate information
    - apksigner verify --print-certs app-release-signed.apk
  artifacts:
    paths:
      - app-release-signed.apk
  after_script:
    # Clean up keystore for security
    - rm -f $KEYSTORE_FILE
```

### Tool Information Helper

Run the built-in helper script for quick reference:

```bash
android-signing-tools
```

This displays all available tools, their locations, and usage examples.

### Security Best Practices

1. **Never commit keystores** to your repository
2. **Use CI/CD variables** to store keystore and passwords securely
3. **Encode keystores as base64** for safe storage in CI/CD variables
4. **Always clean up** keystores after signing
5. **Use apksigner** for new projects (supports newer signature schemes)
6. **Run zipalign before signing** for optimal APK performance
7. **Verify signatures** after signing to ensure integrity
