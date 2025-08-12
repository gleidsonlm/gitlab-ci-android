# gitlab-ci-android Docker Image

This repository builds a Docker image (`gleidsonlm/gitlab-ci-android`) containing the Android SDK and tools necessary for building Android applications in CI environments like GitLab CI and GitHub Actions.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites
- Docker must be installed and running
- Network access for downloading dependencies (Ubuntu packages, Android SDK, Gradle)
- 8GB+ available disk space for build process
- 16GB+ RAM recommended for Android builds

### Docker Image Building
The image is based on Ubuntu 20.04 and includes:
- OpenJDK 11 (required for modern Android builds)
- Android SDK Command Line Tools (version 8512546)
- Android SDK Platform API 33
- Android SDK Build Tools 33.0.0
- Google APIs, Play Services, and Support Libraries

**Build the Docker image:**
```bash
docker build -t gitlab-ci-android .
```
- NEVER CANCEL: Build takes 10-15 minutes depending on network speed. Set timeout to 30+ minutes.
- Downloads ~600MB of Android SDK components
- Final image size: ~1.8GB

**Test the built image:**
```bash
# Verify Java installation
docker run --rm gitlab-ci-android java -version

# Verify Android SDK components
docker run --rm gitlab-ci-android sdkmanager --list

# Check Android environment variables
docker run --rm gitlab-ci-android env | grep ANDROID
```

### Using the Published Image
**Pull the pre-built image:**
```bash
docker pull gleidsonlm/gitlab-ci-android:latest
```

**Test Android app builds:**
```bash
# In your Android project directory with gradlew
docker run --rm -v $(pwd):/workspace -w /workspace \
  gleidsonlm/gitlab-ci-android:latest \
  ./gradlew assembleDebug
```
- NEVER CANCEL: Initial Gradle builds take 5-10 minutes as dependencies download. Set timeout to 20+ minutes.
- Subsequent builds with cached dependencies: 2-5 minutes
- Always set `GRADLE_USER_HOME` environment variable for caching

### CI Configuration Examples

**GitLab CI (.gitlab-ci.yml):**
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

**GitHub Actions:**
```yaml
name: Android CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    container: gleidsonlm/gitlab-ci-android:latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Gradle cache
      run: export GRADLE_USER_HOME=$(pwd)/.gradle
    - name: Build debug APK
      run: ./gradlew assembleDebug
```

## Validation

### Manual Testing Requirements
After making changes to the Dockerfile or build process:

1. **Build and test the image:**
   ```bash
   docker build -t test-gitlab-ci-android .
   docker run --rm test-gitlab-ci-android java -version
   docker run --rm test-gitlab-ci-android sdkmanager --list
   ```

2. **Test with a real Android project:**
   - Create or use an existing Android project with `gradlew`
   - Mount the project directory and run a build
   - Verify the APK is generated successfully

3. **Environment validation:**
   ```bash
   # Verify all required environment variables
   docker run --rm test-gitlab-ci-android env | grep -E "(ANDROID|JAVA)"
   
   # Check Android SDK structure
   docker run --rm test-gitlab-ci-android ls -la /sdk
   
   # Verify licenses are accepted
   docker run --rm test-gitlab-ci-android ls -la /sdk/licenses
   ```

### Network Connectivity Issues
**Common problem:** In restricted network environments, you may encounter:
- "Unable to resolve host: archive.ubuntu.com" - Ubuntu package installation fails
- "Unable to resolve host: services.gradle.org" - Gradle downloads fail
- "Unable to resolve host: dl.google.com" - Android SDK downloads fail
- "SSL certificate problem: self-signed certificate in certificate chain" - SSL validation fails

**Solutions:**
- Use corporate proxy settings if available
- Build in environments with full internet access
- Use pre-built images from Docker Hub when building locally fails
- **For SSL certificate issues**: Mount custom CA certificates or configure proxy properly rather than disabling SSL verification

**SSL Certificate Handling:**
As of v1.0.0, all insecure SSL certificate bypasses have been removed for security. If building in a corporate environment with SSL interception:
```bash
# Option 1: Mount custom CA certificates
docker build --build-arg http_proxy=http://proxy:port --build-arg https_proxy=https://proxy:port .

# Option 2: Use pre-built image instead
docker pull gleidsonlm/gitlab-ci-android:latest
```

## Common Tasks

### Repository Structure
```
.
├── .github/
│   └── workflows/
│       └── docker-image.yml      # GitHub Actions for image publishing
├── .gitlab-ci.yml                # GitLab CI configuration (legacy)
├── Dockerfile                    # Main Docker image definition
├── LICENSE                       # MIT License
├── README.md                     # Basic usage documentation
└── packages.txt                  # Android SDK packages to install
```

### Key Environment Variables
- `ANDROID_SDK_ROOT=/sdk` - Android SDK installation directory
- `ANDROID_HOME=/sdk` - Legacy Android SDK variable (for compatibility)
- `PATH` includes Android SDK tools and platform-tools
- `DEBIAN_FRONTEND=noninteractive` - Prevents interactive prompts during build

### Android SDK Components Installed
```
platforms;android-33              # Android SDK Platform 33
build-tools;33.0.0                # Android SDK Build-Tools 33
add-ons;addon-google_apis-google-24 # Google APIs
extras;android;m2repository       # Android Support Repository
extras;google;google_play_services # Google Play services
extras;google;m2repository        # Google Repository
```

### Updating Android SDK Versions
To update the Android SDK version:
1. Modify `packages.txt` to include new platform/build-tools versions
2. Update the Dockerfile if newer command line tools are available
3. Test thoroughly with real Android projects
4. Update CI examples in README.md

### Troubleshooting

**Build fails with "licenses not accepted":**
- The image pre-accepts all required licenses
- If issues persist, run: `sdkmanager --licenses` in the container

**Gradle builds fail with memory errors:**
- Increase Docker container memory allocation
- Add `-Xmx4g` to `GRADLE_OPTS` environment variable

**APK not found after build:**
- Check Gradle output for actual APK location
- Common paths: `app/build/outputs/apk/debug/` or `app/build/outputs/apk/`

### Performance Tips
- Use Gradle caching by setting `GRADLE_USER_HOME`
- Cache Docker layers during builds
- Use `--build-arg` for version variables to improve cache efficiency
- Pre-warm Gradle dependencies in separate Docker layer for frequently built projects

## Build Timing Expectations
- **Fresh Docker build:** 10-15 minutes (NEVER CANCEL - set 30+ minute timeout)
- **Android project first build:** 5-10 minutes (NEVER CANCEL - set 20+ minute timeout)  
- **Subsequent builds with cache:** 2-5 minutes
- **SDK download size:** ~600MB
- **Final image size:** ~1.8GB
- **Total SDK installation:** ~1.1GB