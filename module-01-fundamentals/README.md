# Module 1: Jenkins Fundamentals

## Learning Objectives

By the end of this module, you will:
- Understand what Jenkins is and its role in CI/CD
- Know Jenkins architecture and key components
- Install and configure Jenkins
- Navigate the Jenkins UI
- Understand basic Jenkins concepts

## 1.1 Introduction to Jenkins and CI/CD

### What is Jenkins?

Jenkins is an open-source automation server that helps teams build, test, and deploy applications. It's the most popular CI/CD tool in the DevOps ecosystem.

### Key Features:
- **Free and Open Source**: Large community support
- **Easy Installation**: Available for multiple platforms
- **Extensive Plugin Ecosystem**: 1500+ plugins
- **Distributed Builds**: Master-slave architecture
- **Pipeline as Code**: Infrastructure as Code for CI/CD

### CI/CD Overview

**Continuous Integration (CI):**
- Developers integrate code changes frequently
- Automated builds and tests run on each integration
- Early detection of integration issues

**Continuous Delivery (CD):**
- Code changes are automatically prepared for release
- Manual approval for production deployment

**Continuous Deployment:**
- Code changes are automatically deployed to production
- Fully automated pipeline

### Jenkins in the CI/CD Pipeline

```
Developer → Git Push → Jenkins Trigger → Build → Test → Deploy → Monitor
```

## 1.2 Jenkins Architecture

### Master-Slave Architecture

```
Jenkins Master (Controller)
    ├── Web UI
    ├── Job Scheduling
    ├── Plugin Management
    └── Build Coordination
    
Jenkins Agents (Slaves)
    ├── Agent 1 (Linux)
    ├── Agent 2 (Windows)
    └── Agent 3 (macOS)
```

### Key Components:

1. **Jenkins Master/Controller**
   - Central coordination point
   - Hosts the web UI
   - Stores configuration
   - Schedules builds

2. **Jenkins Agents/Slaves**
   - Execute build jobs
   - Can be on different platforms
   - Communicate with master via Java Web Start or SSH

3. **Jobs/Projects**
   - Unit of work in Jenkins
   - Contains build steps and configuration

4. **Builds**
   - Instance of a job execution
   - Has build number and results

5. **Plugins**
   - Extend Jenkins functionality
   - Available from Jenkins Plugin Manager

## 1.3 Installation Guide

### Prerequisites

- Java 11 or 17 (LTS versions recommended)
- Minimum 256 MB RAM (1GB+ recommended)
- 1 GB disk space

### Installation Methods

#### Method 1: Docker Installation (Recommended for Learning)

```bash
# Pull Jenkins LTS image
docker pull jenkins/jenkins:lts

# Run Jenkins container
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

#### Method 2: Direct Installation (macOS)

```bash
# Install using Homebrew
brew install jenkins-lts

# Start Jenkins
brew services start jenkins-lts
```

#### Method 3: Direct Installation (Ubuntu/Debian)

```bash
# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list and install
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### Initial Setup

1. **Access Jenkins**: Open browser and go to `http://localhost:8080`

2. **Unlock Jenkins**: 
   - Find initial admin password:
   ```bash
   # For Docker installation
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   
   # For direct installation
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. **Install Suggested Plugins**: Choose "Install suggested plugins"

4. **Create Admin User**: Set up your first admin user

5. **Instance Configuration**: Set Jenkins URL (usually `http://localhost:8080`)

## 1.4 Jenkins UI Overview

### Main Dashboard

- **New Item**: Create new jobs
- **People**: User management
- **Build History**: Recent builds across all jobs
- **Manage Jenkins**: System configuration
- **My Views**: Personal dashboards

### Job Dashboard

- **Build Now**: Trigger immediate build
- **Configure**: Modify job settings
- **Workspace**: View job's working directory
- **Build History**: Past executions

### Build Details

- **Console Output**: Real-time build logs
- **Changes**: Code changes in this build
- **Tests**: Test results (if configured)
- **Artifacts**: Build outputs

## 1.5 Basic Concepts

### Jobs/Projects Types

1. **Freestyle Project**: Basic job type with GUI configuration
2. **Pipeline**: Jobs defined as code
3. **Multi-configuration Project**: Matrix builds
4. **Folder**: Organize jobs into folders
5. **Multibranch Pipeline**: Automatic pipeline creation for branches

### Build Triggers

1. **Manual**: Click "Build Now"
2. **SCM Polling**: Check for code changes periodically
3. **Webhook**: Triggered by external systems
4. **Scheduled**: Cron-like scheduling
5. **Upstream/Downstream**: Triggered by other jobs

### Build Steps

1. **Execute Shell**: Run shell commands
2. **Invoke Ant/Maven/Gradle**: Build tools
3. **Send files**: Copy artifacts
4. **Trigger other builds**: Chain jobs

## Hands-on Exercise 1.1: Your First Jenkins Job

### Step 1: Create a Simple Job

1. Click "New Item" on Jenkins dashboard
2. Enter name: `hello-world-job`
3. Select "Freestyle project"
4. Click "OK"

### Step 2: Configure the Job

1. In "Build" section, click "Add build step"
2. Select "Execute shell" (or "Execute Windows batch command" on Windows)
3. Enter the following script:

```bash
echo "Hello, Jenkins!"
echo "Current date and time: $(date)"
echo "Jenkins Build Number: $BUILD_NUMBER"
echo "Jenkins Job Name: $JOB_NAME"
echo "Current working directory: $(pwd)"
ls -la
```

4. Click "Save"

### Step 3: Run the Job

1. Click "Build Now"
2. Watch the build in "Build History"
3. Click on the build number (e.g., "#1")
4. Click "Console Output" to see the results

### Expected Output:
```
Started by user admin
Running as SYSTEM
Building in workspace /var/jenkins_home/workspace/hello-world-job
[hello-world-job] $ /bin/sh -xe /tmp/jenkins123.sh
+ echo 'Hello, Jenkins!'
Hello, Jenkins!
+ echo 'Current date and time: Mon Oct  7 12:00:00 UTC 2025'
Current date and time: Mon Oct  7 12:00:00 UTC 2025
+ echo 'Jenkins Build Number: 1'
Jenkins Build Number: 1
+ echo 'Jenkins Job Name: hello-world-job'
Jenkins Job Name: hello-world-job
+ echo 'Current working directory: /var/jenkins_home/workspace/hello-world-job'
Current working directory: /var/jenkins_home/workspace/hello-world-job
+ ls -la
total 8
drwxr-xr-x 2 jenkins jenkins 4096 Oct  7 12:00 .
drwxr-xr-x 3 jenkins jenkins 4096 Oct  7 12:00 ..
Finished: SUCCESS
```

## Hands-on Exercise 1.2: Job with Parameters

### Step 1: Create Parameterized Job

1. Create new job: `parameterized-hello`
2. Select "Freestyle project"
3. Check "This project is parameterized"
4. Add parameter: "String Parameter"
   - Name: `USER_NAME`
   - Default Value: `World`
   - Description: `Name to greet`

### Step 2: Use Parameter in Build

Add build step with shell script:

```bash
echo "Hello, $USER_NAME!"
echo "This build was triggered with parameter: $USER_NAME"
echo "Build number: $BUILD_NUMBER"
echo "All environment variables:"
env | sort
```

### Step 3: Build with Parameters

1. Click "Build with Parameters"
2. Enter different values for `USER_NAME`
3. Run multiple builds with different parameters

## Quiz: Module 1

1. What are the main components of Jenkins architecture?
2. What is the difference between CI and CD?
3. What file contains the initial Jenkins admin password?
4. Name three types of build triggers in Jenkins.
5. What is the difference between a job and a build?

## Key Takeaways

- Jenkins is a powerful CI/CD automation server
- Master-slave architecture enables distributed builds
- Jenkins can be installed via Docker, package managers, or WAR file
- Jobs are units of work, builds are job executions
- Parameters make jobs flexible and reusable

## Next Module

In [Module 2](../module-02-jobs-builds/), we'll dive deeper into Jenkins jobs and builds, exploring different project types, build triggers, and advanced job configuration.

## Additional Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Plugin Index](https://plugins.jenkins.io/)
- [Jenkins Community](https://www.jenkins.io/community/)