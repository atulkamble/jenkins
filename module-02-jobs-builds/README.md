# Module 2: Jenkins Jobs and Builds

## Learning Objectives

By the end of this module, you will:
- Understand different types of Jenkins jobs
- Master build triggers and scheduling
- Work with build parameters and environment variables
- Manage build artifacts and workspaces
- Configure post-build actions

## 2.1 Jenkins Job Types

### 2.1.1 Freestyle Project

The most basic and flexible job type in Jenkins.

**Use Cases:**
- Simple build scripts
- Legacy projects
- Quick prototyping
- Learning Jenkins basics

**Configuration Options:**
- Source Code Management
- Build Triggers
- Build Environment
- Build Steps
- Post-build Actions

### 2.1.2 Pipeline Jobs

Modern way to define builds as code.

**Types:**
- **Pipeline**: Single Jenkinsfile
- **Multibranch Pipeline**: Automatic pipeline per branch
- **GitHub Organization**: Automatic discovery of repositories

### 2.1.3 Multi-configuration Project

Run same job with different configurations (matrix builds).

**Use Cases:**
- Testing across multiple environments
- Different OS/browser combinations
- Multiple parameter combinations

### 2.1.4 Maven Project

Specialized for Maven-based Java projects.

**Features:**
- Automatic Maven integration
- POM-based configuration
- Incremental builds
- Automatic test reporting

## 2.2 Build Triggers

### 2.2.1 Manual Triggers

```
Build Now - Immediate execution
Build with Parameters - With user input
```

### 2.2.2 SCM Polling

Check source code repository for changes.

**Configuration:**
```
Schedule: H/5 * * * *  # Every 5 minutes
Poll SCM: H/15 * * * * # Every 15 minutes
```

**Cron Syntax:**
```
# Minute Hour Day Month DayOfWeek
H/30 * * * *    # Every 30 minutes
H 9-17 * * 1-5  # Every hour between 9 AM and 5 PM, Mon-Fri
H 0 * * 0       # Once a week on Sunday at midnight
```

### 2.2.3 Webhook Triggers

Real-time triggers from external systems.

**GitHub Webhook:**
```
Payload URL: http://jenkins.example.com/github-webhook/
Content type: application/json
Events: Just the push event
```

**Generic Webhook:**
```
URL: http://jenkins.example.com/generic-webhook-trigger/invoke
Token: mySecretToken
```

### 2.2.4 Scheduled Builds

Time-based triggering using cron expressions.

```
# Build daily at 2 AM
H 2 * * *

# Build every Monday at 6 AM
H 6 * * 1

# Build every 6 hours
H H/6 * * *

# Build twice a day
H H(0-7),H(16-23) * * *
```

### 2.2.5 Upstream/Downstream Triggers

Chain jobs together.

**Upstream Configuration:**
- Build after other projects are built
- Build when upstream is successful/unstable/failed

**Downstream Configuration:**
- Trigger other builds when this build completes
- Pass parameters to downstream jobs

## 2.3 Build Parameters

### 2.3.1 String Parameters

```bash
# In job configuration
Name: ENVIRONMENT
Default Value: staging
Description: Target environment for deployment

# Usage in build script
echo "Deploying to: $ENVIRONMENT"
```

### 2.3.2 Choice Parameters

```bash
# Configuration
Name: BUILD_TYPE
Choices: debug\nrelease\nprofile
Description: Type of build to perform

# Usage
if [ "$BUILD_TYPE" = "debug" ]; then
    echo "Building debug version"
elif [ "$BUILD_TYPE" = "release" ]; then
    echo "Building release version"
fi
```

### 2.3.3 Boolean Parameters

```bash
# Configuration
Name: RUN_TESTS
Default: true
Description: Whether to run tests

# Usage
if [ "$RUN_TESTS" = "true" ]; then
    echo "Running tests..."
    npm test
else
    echo "Skipping tests"
fi
```

### 2.3.4 File Parameters

Allow users to upload files for the build.

```bash
# Configuration
Name: CONFIG_FILE
Description: Configuration file to use

# Usage - file is available in workspace
if [ -f "$CONFIG_FILE" ]; then
    echo "Using config file: $CONFIG_FILE"
    cp "$CONFIG_FILE" ./config/app.conf
fi
```

## 2.4 Environment Variables

### 2.4.1 Built-in Variables

```bash
# Jenkins built-in variables
echo "Build Number: $BUILD_NUMBER"
echo "Job Name: $JOB_NAME"
echo "Job URL: $JOB_URL"
echo "Build URL: $BUILD_URL"
echo "Workspace: $WORKSPACE"
echo "Jenkins Home: $JENKINS_HOME"
echo "Jenkins URL: $JENKINS_URL"
echo "Node Name: $NODE_NAME"
echo "Build Tag: $BUILD_TAG"
echo "Git Commit: $GIT_COMMIT"
echo "Git Branch: $GIT_BRANCH"
```

### 2.4.2 Custom Environment Variables

**Job-level Configuration:**
```
# In job configuration under "Build Environment"
Name: API_URL
Value: https://api.staging.example.com
```

**Global Configuration:**
```
# Manage Jenkins > Configure System > Global Properties
Name: COMPANY_NAME
Value: My Company Inc.
```

### 2.4.3 Environment Variables from Files

```bash
# Load environment from file
if [ -f ".env" ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Or source the file
source .env 2>/dev/null || true
```

## 2.5 Build Steps

### 2.5.1 Execute Shell (Linux/macOS)

```bash
#!/bin/bash
set -e  # Exit on any error

# Print environment info
echo "=== Build Environment ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "Node: $NODE_NAME"
echo "Build: $BUILD_NUMBER"

# Install dependencies
echo "=== Installing Dependencies ==="
if [ -f "package.json" ]; then
    npm install
elif [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
elif [ -f "pom.xml" ]; then
    mvn dependency:resolve
fi

# Run build
echo "=== Building Application ==="
if [ -f "package.json" ]; then
    npm run build
elif [ -f "Makefile" ]; then
    make build
elif [ -f "pom.xml" ]; then
    mvn compile
fi

# Run tests
echo "=== Running Tests ==="
if [ "$RUN_TESTS" = "true" ]; then
    if [ -f "package.json" ]; then
        npm test
    elif [ -f "pom.xml" ]; then
        mvn test
    fi
fi

echo "=== Build Completed Successfully ==="
```

### 2.5.2 Execute Windows Batch Command

```batch
@echo off
echo === Build Environment ===
echo Date: %DATE% %TIME%
echo User: %USERNAME%
echo Working Directory: %CD%
echo Build: %BUILD_NUMBER%

echo === Installing Dependencies ===
if exist package.json (
    call npm install
) else if exist requirements.txt (
    pip install -r requirements.txt
)

echo === Building Application ===
if exist package.json (
    call npm run build
) else if exist "*.sln" (
    msbuild /p:Configuration=Release
)

echo === Build Completed ===
```

### 2.5.3 Invoke Build Tools

**Maven:**
```
Goals and options: clean compile test package
POM: pom.xml
Properties: skipTests=false
```

**Gradle:**
```
Tasks: clean build
Build File: build.gradle
Gradle Version: Use Gradle Wrapper
```

**Ant:**
```
Targets: clean compile test
Build File: build.xml
Properties: env=production
```

## 2.6 Post-build Actions

### 2.6.1 Archive Artifacts

```
Files to archive: target/*.jar, dist/**, build/libs/*.jar
Exclude: **/*-sources.jar
```

### 2.6.2 Publish Test Results

```
Test report XMLs: target/surefire-reports/*.xml, test-results.xml
Health report amplification factor: 1.0
Health report description: Test Result
```

### 2.6.3 Email Notifications

```
Recipients: $DEFAULT_RECIPIENTS, developer@company.com
Subject: Build $BUILD_STATUS - Job '$JOB_NAME' - Build #$BUILD_NUMBER
Content: Build $BUILD_STATUS for job $JOB_NAME
```

### 2.6.4 Trigger Other Jobs

```
Projects to build: deploy-staging, run-integration-tests
Trigger when build is: Stable
Parameters: ENVIRONMENT=staging, BUILD_VERSION=$BUILD_NUMBER
```

## Hands-on Exercise 2.1: Advanced Freestyle Job

### Step 1: Create Multi-Parameter Job

1. Create new job: `advanced-build-job`
2. Add parameters:
   - String: `VERSION` (default: "1.0.0")
   - Choice: `ENVIRONMENT` (dev, staging, prod)
   - Boolean: `RUN_TESTS` (default: true)
   - Boolean: `DEPLOY` (default: false)

### Step 2: Configure Build Script

```bash
#!/bin/bash
set -e

echo "=== Advanced Build Job ==="
echo "Version: $VERSION"
echo "Environment: $ENVIRONMENT"
echo "Run Tests: $RUN_TESTS"
echo "Deploy: $DEPLOY"
echo "Build Number: $BUILD_NUMBER"

# Create project structure
mkdir -p src test dist logs

# Simulate source code
cat > src/app.js << EOF
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Jenkins!',
    version: '$VERSION',
    environment: '$ENVIRONMENT',
    build: '$BUILD_NUMBER'
  });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});

module.exports = app;
EOF

# Create package.json
cat > package.json << EOF
{
  "name": "jenkins-demo-app",
  "version": "$VERSION",
  "description": "Demo app for Jenkins course",
  "main": "src/app.js",
  "scripts": {
    "start": "node src/app.js",
    "test": "echo 'Running tests...' && exit 0",
    "build": "echo 'Building application...'"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# Install dependencies (simulated)
echo "Installing dependencies..."
echo "express@4.18.0 installed" > logs/npm-install.log

# Build application
echo "Building application for $ENVIRONMENT environment..."
if [ "$ENVIRONMENT" = "prod" ]; then
    echo "Production build - optimizing..."
    echo "optimized build" > dist/app-optimized.js
else
    echo "Development build"
    cp src/app.js dist/app.js
fi

# Run tests if requested
if [ "$RUN_TESTS" = "true" ]; then
    echo "Running tests..."
    echo "Test Suite: PASSED" > test/test-results.xml
    echo "✅ All tests passed"
else
    echo "⏭️  Skipping tests"
fi

# Create build artifact
echo "Creating build artifact..."
tar -czf "jenkins-demo-app-$VERSION-$BUILD_NUMBER.tar.gz" dist/ package.json

# Deployment simulation
if [ "$DEPLOY" = "true" ]; then
    echo "🚀 Deploying to $ENVIRONMENT environment..."
    echo "Deployment completed successfully" > logs/deploy-$ENVIRONMENT.log
else
    echo "📦 Build ready for deployment"
fi

echo "✅ Build completed successfully!"
echo "Artifact: jenkins-demo-app-$VERSION-$BUILD_NUMBER.tar.gz"
```

### Step 3: Configure Post-build Actions

1. **Archive Artifacts:**
   - Files: `*.tar.gz, logs/*.log, test/*.xml`

2. **Email Notification:**
   - Send to: your-email@example.com
   - Subject: `Build $BUILD_STATUS - $JOB_NAME #$BUILD_NUMBER`

## Hands-on Exercise 2.2: Scheduled Build with Matrix

### Step 1: Create Multi-configuration Job

1. Create new job: `matrix-test-job`
2. Select "Multi-configuration project"
3. Add Configuration Matrix:
   - Axis name: `OS`
   - Values: `linux`, `windows`, `macos`
   - Axis name: `BROWSER`
   - Values: `chrome`, `firefox`, `safari`

### Step 2: Configure Build Script

```bash
#!/bin/bash

echo "=== Matrix Build ==="
echo "Operating System: $OS"
echo "Browser: $BROWSER"
echo "Combination: $OS-$BROWSER"

# Simulate different behaviors based on matrix
case "$OS" in
    "linux")
        echo "Running on Linux..."
        if [ "$BROWSER" = "safari" ]; then
            echo "⚠️  Safari not supported on Linux, skipping..."
            exit 0
        fi
        ;;
    "windows")
        echo "Running on Windows..."
        ;;
    "macos")
        echo "Running on macOS..."
        ;;
esac

# Simulate browser-specific tests
case "$BROWSER" in
    "chrome")
        echo "🌐 Running Chrome tests..."
        ;;
    "firefox")
        echo "🦊 Running Firefox tests..."
        ;;
    "safari")
        echo "🧭 Running Safari tests..."
        ;;
esac

# Create test results
mkdir -p test-results
echo "Test results for $OS-$BROWSER combination" > test-results/results-$OS-$BROWSER.txt

echo "✅ Matrix combination $OS-$BROWSER completed"
```

### Step 3: Schedule the Build

Add build trigger with cron schedule:
```
# Run every day at 3 AM
H 3 * * *
```

## Hands-on Exercise 2.3: Job Chaining

### Step 1: Create Upstream Job

1. Job name: `build-application`
2. Build script:
```bash
echo "Building main application..."
echo "BUILD_VERSION=1.0.$BUILD_NUMBER" > build.properties
echo "BUILD_STATUS=SUCCESS" >> build.properties
```

3. Post-build action: Archive `build.properties`

### Step 2: Create Downstream Job

1. Job name: `deploy-application`
2. Build trigger: "Build after other projects are built"
   - Projects: `build-application`
   - Trigger only if build is stable

3. Build script:
```bash
echo "Deploying application..."

# Copy artifacts from upstream job
if [ -f "../build-application/build.properties" ]; then
    source ../build-application/build.properties
    echo "Deploying version: $BUILD_VERSION"
    echo "Status: $BUILD_STATUS"
else
    echo "❌ Build properties not found"
    exit 1
fi

echo "✅ Deployment completed"
```

## Quiz: Module 2

1. What's the difference between SCM polling and webhooks?
2. How do you pass parameters between jobs?
3. What cron expression runs a job every weekday at 9 AM?
4. Name three types of build parameters in Jenkins.
5. How do you archive build artifacts?

## Key Takeaways

- Different job types serve different purposes
- Build triggers enable automation
- Parameters make jobs flexible and reusable
- Environment variables provide build context
- Post-build actions extend job functionality
- Job chaining enables complex workflows

## Next Module

In [Module 3](../module-03-pipelines/), we'll explore Jenkins Pipelines - the modern way to define CI/CD workflows as code.

## Troubleshooting Common Issues

### Issue 1: Build Fails with Permission Denied

```bash
# Fix: Add executable permissions
chmod +x build-script.sh
```

### Issue 2: Environment Variables Not Available

```bash
# Debug: Print all environment variables
env | sort
```

### Issue 3: Artifacts Not Archived

- Check file paths are relative to workspace
- Use wildcards correctly: `**/*.jar` not `*/*.jar`
- Verify files exist after build

### Issue 4: Downstream Job Not Triggered

- Check upstream job completed successfully
- Verify job names match exactly
- Check trigger conditions