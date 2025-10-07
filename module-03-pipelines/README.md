# Module 3: Jenkins Pipelines

## Learning Objectives

By the end of this module, you will:
- Understand Jenkins Pipeline concepts and benefits
- Write Declarative and Scripted pipelines
- Use Jenkinsfile for Pipeline as Code
- Implement advanced pipeline features
- Debug and troubleshoot pipelines

## 3.1 Introduction to Jenkins Pipelines

### What are Jenkins Pipelines?

Jenkins Pipeline is a suite of plugins that supports implementing and integrating continuous delivery pipelines into Jenkins. It provides:

- **Pipeline as Code**: Define builds in source code
- **Durability**: Survives Jenkins restarts
- **Pausable**: Can wait for human input
- **Versatile**: Supports complex real-world requirements
- **Extensible**: Plugin ecosystem

### Benefits over Freestyle Jobs

| Freestyle Jobs | Pipelines |
|----------------|-----------|
| GUI-based configuration | Code-based definition |
| Limited conditional logic | Full programming constructs |
| Basic error handling | Advanced error handling |
| Manual job chaining | Integrated workflow |
| Configuration in Jenkins | Version controlled Jenkinsfile |

## 3.2 Pipeline Types

### 3.2.1 Declarative Pipeline

Modern, structured approach with predefined sections.

**Basic Structure:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Testing...'
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
```

### 3.2.2 Scripted Pipeline

Flexible, programmatic approach using Groovy syntax.

**Basic Structure:**
```groovy
node {
    stage('Build') {
        echo 'Building...'
    }
    
    stage('Test') {
        echo 'Testing...'
    }
    
    stage('Deploy') {
        echo 'Deploying...'
    }
}
```

## 3.3 Declarative Pipeline Deep Dive

### 3.3.1 Complete Pipeline Structure

```groovy
pipeline {
    // Define where to run
    agent {
        label 'linux'
    }
    
    // Define tools
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    // Environment variables
    environment {
        APP_NAME = 'my-awesome-app'
        VERSION = "${env.BUILD_NUMBER}"
        DEPLOY_ENV = 'staging'
    }
    
    // Build parameters
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run tests?')
    }
    
    // Build triggers
    triggers {
        cron('H 2 * * *')  // Daily at 2 AM
        pollSCM('H/15 * * * *')  // Poll every 15 minutes
    }
    
    // Pipeline options
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        retry(3)
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
            post {
                always {
                    echo 'Build stage completed'
                }
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS }
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                    }
                    post {
                        always {
                            junit 'target/surefire-reports/*.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh 'mvn integration-test'
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: 'Deploy to production?', ok: 'Deploy'
                    }
                }
                sh "echo 'Deploying to ${params.ENVIRONMENT}'"
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            emailext subject: 'Build Success: ${JOB_NAME} - ${BUILD_NUMBER}',
                     body: 'Build completed successfully!',
                     to: '${DEFAULT_RECIPIENTS}'
        }
        failure {
            emailext subject: 'Build Failed: ${JOB_NAME} - ${BUILD_NUMBER}',
                     body: 'Build failed. Please check the logs.',
                     to: '${DEFAULT_RECIPIENTS}'
        }
    }
}
```

### 3.3.2 Pipeline Sections Explained

#### Agent Section
```groovy
// Run on any available agent
agent any

// Run on specific label
agent { label 'linux && docker' }

// Run in Docker container
agent {
    docker {
        image 'node:16'
        args '-v /tmp:/tmp'
    }
}

// Run on Kubernetes
agent {
    kubernetes {
        yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: maven
            image: maven:3.8-jdk-11
            command: ['cat']
            tty: true
        '''
    }
}

// No global agent, specify per stage
agent none
```

#### Environment Section
```groovy
environment {
    // Global environment variables
    APP_NAME = 'my-app'
    VERSION = "${env.BUILD_NUMBER}"
    
    // Credentials
    API_KEY = credentials('api-key-id')
    DB_CREDENTIALS = credentials('db-creds')
    
    // Dynamic values
    TIMESTAMP = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
    GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
}
```

#### When Conditions
```groovy
when {
    // Branch conditions
    branch 'main'
    not { branch 'dev' }
    anyOf { branch 'main'; branch 'develop' }
    
    // Environment conditions
    environment name: 'DEPLOY_ENV', value: 'production'
    
    // Expression conditions
    expression { params.RUN_TESTS == true }
    expression { env.BRANCH_NAME ==~ /release\/.*/ }
    
    // Change conditions
    changeset "src/**"
    changeRequest()
    
    // Combined conditions
    allOf {
        branch 'main'
        environment name: 'DEPLOY_ENV', value: 'prod'
    }
}
```

## 3.4 Scripted Pipeline Deep Dive

### 3.4.1 Basic Scripted Pipeline

```groovy
node('linux') {
    try {
        // Checkout code
        stage('Checkout') {
            checkout scm
        }
        
        // Build
        stage('Build') {
            sh 'mvn clean compile'
        }
        
        // Test
        stage('Test') {
            sh 'mvn test'
            junit 'target/surefire-reports/*.xml'
        }
        
        // Deploy
        stage('Deploy') {
            if (env.BRANCH_NAME == 'main') {
                sh 'mvn deploy'
            } else {
                echo 'Skipping deployment for non-main branch'
            }
        }
        
        // Success notification
        emailext subject: 'Build Success',
                 body: 'Build completed successfully!',
                 to: '${DEFAULT_RECIPIENTS}'
                 
    } catch (Exception e) {
        // Failure notification
        emailext subject: 'Build Failed',
                 body: "Build failed: ${e.getMessage()}",
                 to: '${DEFAULT_RECIPIENTS}'
        throw e
    } finally {
        // Cleanup
        cleanWs()
    }
}
```

### 3.4.2 Advanced Scripted Features

```groovy
// Define reusable functions
def buildApp() {
    sh 'mvn clean compile'
}

def runTests() {
    sh 'mvn test'
    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
}

def deployApp(environment) {
    echo "Deploying to ${environment}"
    sh "mvn deploy -Denv=${environment}"
}

// Main pipeline
node {
    // Dynamic agent selection
    def agents = ['linux-1', 'linux-2', 'linux-3']
    def selectedAgent = agents[new Random().nextInt(agents.size())]
    
    node(selectedAgent) {
        stage('Checkout') {
            checkout scm
        }
        
        stage('Build') {
            buildApp()
        }
        
        // Parallel execution
        stage('Test') {
            parallel(
                'Unit Tests': {
                    runTests()
                },
                'Integration Tests': {
                    sh 'mvn integration-test'
                },
                'Security Scan': {
                    sh 'mvn dependency-check:check'
                }
            )
        }
        
        // Conditional deployment
        stage('Deploy') {
            def environments = ['dev', 'staging']
            
            if (env.BRANCH_NAME == 'main') {
                environments.add('production')
            }
            
            for (env_name in environments) {
                if (env_name == 'production') {
                    input message: 'Deploy to production?', ok: 'Deploy'
                }
                deployApp(env_name)
            }
        }
    }
}
```

## 3.5 Pipeline Steps and Built-in Functions

### 3.5.1 Essential Steps

```groovy
// Shell commands
sh 'ls -la'
sh script: 'echo "Hello World"', returnStdout: true

// Batch commands (Windows)
bat 'dir'
bat script: 'echo Hello World', returnStdout: true

// PowerShell commands
powershell 'Get-ChildItem'

// File operations
writeFile file: 'config.txt', text: 'key=value'
def content = readFile 'config.txt'

// Archive artifacts
archiveArtifacts artifacts: '**/*.jar', fingerprint: true

// Publish test results
junit 'target/surefire-reports/*.xml'
publishHTML([
    allowMissing: false,
    alwaysLinkToLastBuild: false,
    keepAll: true,
    reportDir: 'coverage',
    reportFiles: 'index.html',
    reportName: 'Coverage Report'
])

// Workspace management
dir('subdir') {
    sh 'pwd'  // Runs in subdir
}

// Timeout
timeout(time: 5, unit: 'MINUTES') {
    sh 'long-running-command'
}

// Retry
retry(3) {
    sh 'flaky-command'
}

// Wait for external condition
waitUntil {
    script {
        def response = sh(script: 'curl -s http://app/health', returnStdout: true)
        return response.contains('healthy')
    }
}
```

### 3.5.2 Git Operations

```groovy
// Checkout specific branch
checkout([
    $class: 'GitSCM',
    branches: [[name: '*/develop']],
    userRemoteConfigs: [[url: 'https://github.com/user/repo.git']]
])

// Get git information
def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
def gitAuthor = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()

// Tag repository
sh "git tag v${env.BUILD_NUMBER}"
sh "git push origin v${env.BUILD_NUMBER}"
```

### 3.5.3 Docker Integration

```groovy
// Build Docker image
def image = docker.build("myapp:${env.BUILD_NUMBER}")

// Run container
image.inside {
    sh 'npm test'
}

// Push to registry
docker.withRegistry('https://registry.example.com', 'registry-credentials') {
    image.push()
    image.push('latest')
}

// Run container with custom options
image.inside('-v /tmp:/tmp -e ENV=test') {
    sh 'run-tests.sh'
}
```

## 3.6 Parallel Execution

### 3.6.1 Simple Parallel Stages

```groovy
pipeline {
    agent any
    
    stages {
        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh 'mvn integration-test'
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        sh 'npm audit'
                    }
                }
            }
        }
    }
}
```

### 3.6.2 Dynamic Parallel Execution

```groovy
pipeline {
    agent any
    
    stages {
        stage('Dynamic Parallel') {
            steps {
                script {
                    def tests = [:]
                    def testFiles = sh(script: 'find test -name "*.js"', returnStdout: true).trim().split('\n')
                    
                    for (testFile in testFiles) {
                        def file = testFile  // Important: capture variable
                        tests["Test ${file}"] = {
                            sh "npm test ${file}"
                        }
                    }
                    
                    parallel tests
                }
            }
        }
    }
}
```

## 3.7 Error Handling and Post Actions

### 3.7.1 Try-Catch in Scripted Pipeline

```groovy
node {
    try {
        stage('Build') {
            sh 'mvn compile'
        }
        
        stage('Test') {
            sh 'mvn test'
        }
        
    } catch (Exception e) {
        echo "Build failed: ${e.getMessage()}"
        currentBuild.result = 'FAILURE'
        
        // Send notification
        emailext subject: 'Build Failed',
                 body: "Build failed with error: ${e.getMessage()}",
                 to: '${DEFAULT_RECIPIENTS}'
                 
    } finally {
        // Always executed
        cleanWs()
        
        // Archive logs even on failure
        archiveArtifacts artifacts: 'logs/**', allowEmptyArchive: true
    }
}
```

### 3.7.2 Post Actions in Declarative Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn compile'
            }
        }
    }
    
    post {
        always {
            // Always executed
            echo 'Pipeline completed'
            cleanWs()
        }
        
        success {
            // Only on success
            archiveArtifacts artifacts: 'target/*.jar'
            emailext subject: 'Build Success',
                     body: 'Build completed successfully!',
                     to: '${DEFAULT_RECIPIENTS}'
        }
        
        failure {
            // Only on failure
            emailext subject: 'Build Failed',
                     body: 'Build failed. Check logs for details.',
                     to: '${DEFAULT_RECIPIENTS}'
        }
        
        unstable {
            // When tests fail but build succeeds
            emailext subject: 'Build Unstable',
                     body: 'Build completed but tests failed.',
                     to: '${DEFAULT_RECIPIENTS}'
        }
        
        changed {
            // When build result changes from previous
            echo 'Build result changed from previous build'
        }
    }
}
```

## Hands-on Exercise 3.1: Your First Pipeline

### Step 1: Create Pipeline Job

1. Create new item: `my-first-pipeline`
2. Select "Pipeline"
3. In Pipeline section, select "Pipeline script"

### Step 2: Basic Declarative Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'demo-app'
        VERSION = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                // Simulate checkout
                sh '''
                    mkdir -p src
                    echo 'console.log("Hello from Demo App!");' > src/app.js
                    echo '{"name": "demo-app", "version": "1.0.0"}' > package.json
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building application...'
                sh '''
                    echo "Building ${APP_NAME} version ${VERSION}"
                    mkdir -p dist
                    cp src/app.js dist/
                    echo "Build completed at $(date)" > dist/build-info.txt
                '''
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        echo 'Running unit tests...'
                        sh '''
                            echo "Running unit tests..."
                            mkdir -p test-results
                            echo "All tests passed!" > test-results/unit-tests.log
                        '''
                    }
                }
                
                stage('Lint') {
                    steps {
                        echo 'Running linting...'
                        sh '''
                            echo "Linting code..."
                            echo "No linting issues found!" > test-results/lint.log
                        '''
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging application...'
                sh '''
                    tar -czf ${APP_NAME}-${VERSION}.tar.gz dist/
                    echo "Package created: ${APP_NAME}-${VERSION}.tar.gz"
                '''
                
                archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
        
        success {
            echo 'Pipeline succeeded! 🎉'
        }
        
        failure {
            echo 'Pipeline failed! ❌'
        }
    }
}
```

## Hands-on Exercise 3.2: Parameterized Pipeline

### Step 1: Create Parameterized Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        string(name: 'VERSION', defaultValue: '1.0.0', description: 'Version to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Target environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run tests?')
        booleanParam(name: 'DEPLOY', defaultValue: false, description: 'Deploy after build?')
    }
    
    environment {
        APP_NAME = 'parameterized-app'
        BUILD_TIME = sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
    }
    
    stages {
        stage('Info') {
            steps {
                echo "Building ${APP_NAME} version ${params.VERSION}"
                echo "Target environment: ${params.ENVIRONMENT}"
                echo "Run tests: ${params.RUN_TESTS}"
                echo "Deploy: ${params.DEPLOY}"
                echo "Build time: ${BUILD_TIME}"
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo 'Building application...'
                    
                    // Environment-specific build configuration
                    def buildConfig = [:]
                    switch(params.ENVIRONMENT) {
                        case 'dev':
                            buildConfig.optimization = false
                            buildConfig.debug = true
                            break
                        case 'staging':
                            buildConfig.optimization = true
                            buildConfig.debug = true
                            break
                        case 'production':
                            buildConfig.optimization = true
                            buildConfig.debug = false
                            break
                    }
                    
                    echo "Build configuration: ${buildConfig}"
                    
                    sh """
                        mkdir -p build
                        echo "App: ${APP_NAME}" > build/config.txt
                        echo "Version: ${params.VERSION}" >> build/config.txt
                        echo "Environment: ${params.ENVIRONMENT}" >> build/config.txt
                        echo "Optimization: ${buildConfig.optimization}" >> build/config.txt
                        echo "Debug: ${buildConfig.debug}" >> build/config.txt
                        echo "Build Time: ${BUILD_TIME}" >> build/config.txt
                    """
                }
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS }
            }
            steps {
                echo 'Running tests...'
                sh '''
                    mkdir -p test-results
                    echo "Test run at $(date)" > test-results/test.log
                    echo "All tests passed for environment: ''' + params.ENVIRONMENT + '''" >> test-results/test.log
                '''
            }
        }
        
        stage('Deploy') {
            when {
                expression { params.DEPLOY }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'production') {
                        input message: 'Deploy to production?', ok: 'Deploy',
                              submitterParameter: 'DEPLOYER'
                        echo "Deployment approved by: ${env.DEPLOYER}"
                    }
                    
                    echo "Deploying to ${params.ENVIRONMENT}..."
                    sh """
                        echo "Deployment started at \$(date)" > deploy-${params.ENVIRONMENT}.log
                        echo "Deploying ${APP_NAME} v${params.VERSION} to ${params.ENVIRONMENT}" >> deploy-${params.ENVIRONMENT}.log
                        echo "Deployment completed successfully" >> deploy-${params.ENVIRONMENT}.log
                    """
                }
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'build/*, test-results/*, deploy-*.log', allowEmptyArchive: true
        }
        
        success {
            echo "✅ Build successful for ${params.VERSION} targeting ${params.ENVIRONMENT}"
        }
    }
}
```

## Hands-on Exercise 3.3: Pipeline with External Tools

### Step 1: Node.js Application Pipeline

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS-16'  // Configure in Global Tool Configuration
    }
    
    environment {
        NODE_ENV = 'development'
        CI = 'true'
    }
    
    stages {
        stage('Setup') {
            steps {
                echo 'Setting up Node.js application...'
                
                // Create package.json
                writeFile file: 'package.json', text: '''
{
  "name": "jenkins-node-app",
  "version": "1.0.0",
  "description": "Demo Node.js app for Jenkins",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "test": "echo \\"Running tests...\\" && exit 0",
    "lint": "echo \\"Linting code...\\" && exit 0",
    "build": "echo \\"Building application...\\" && mkdir -p dist && cp *.js dist/"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "devDependencies": {
    "jest": "^28.0.0"
  }
}
'''
                
                // Create app.js
                writeFile file: 'app.js', text: '''
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Jenkins Node.js App!',
    version: process.env.npm_package_version,
    environment: process.env.NODE_ENV,
    buildNumber: process.env.BUILD_NUMBER
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server running on port ${port}`);
  });
}

module.exports = app;
'''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }
        
        stage('Package') {
            steps {
                sh '''
                    echo "Creating application package..."
                    tar -czf app-${BUILD_NUMBER}.tar.gz dist/ package.json
                '''
                
                archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

## Quiz: Module 3

1. What's the difference between Declarative and Scripted pipelines?
2. How do you run stages in parallel?
3. What's the purpose of the `post` section?
4. How do you add conditions to stages?
5. What's the benefit of Pipeline as Code?

## Key Takeaways

- Pipelines provide CI/CD as code
- Declarative pipelines are more structured and easier to learn
- Scripted pipelines offer more flexibility
- Parallel execution improves build times
- Error handling ensures robust pipelines
- Pipeline features enable complex workflows

## Next Module

In [Module 4](../module-04-scm/), we'll explore Source Code Management integration with Git, webhooks, and multi-branch pipelines.

## Common Pipeline Patterns

### Blue-Green Deployment Pattern

```groovy
stage('Deploy') {
    parallel {
        stage('Deploy Blue') {
            steps {
                sh 'deploy-to-blue-environment.sh'
            }
        }
        stage('Deploy Green') {
            steps {
                sh 'deploy-to-green-environment.sh'
            }
        }
    }
}

stage('Switch Traffic') {
    steps {
        input message: 'Switch traffic to new version?'
        sh 'switch-load-balancer.sh'
    }
}
```

### Canary Deployment Pattern

```groovy
stage('Canary Deploy') {
    steps {
        sh 'deploy-canary.sh 10%'  // 10% traffic
        
        sleep 300  // Wait 5 minutes
        
        script {
            def metrics = sh(script: 'check-canary-metrics.sh', returnStdout: true)
            if (metrics.contains('healthy')) {
                sh 'deploy-canary.sh 100%'  // Full deployment
            } else {
                error 'Canary deployment failed health checks'
            }
        }
    }
}
```