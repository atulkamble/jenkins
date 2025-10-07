# Module 4: Source Code Management

## Learning Objectives

By the end of this module, you will:
- Integrate Jenkins with Git repositories
- Configure webhooks for automatic builds
- Work with multi-branch pipelines
- Handle different branching strategies
- Manage credentials securely

## 4.1 Git Integration Basics

### 4.1.1 Configuring Git in Jenkins

**Global Git Configuration:**
1. Manage Jenkins → Global Tool Configuration
2. Add Git installation
3. Configure user name and email

**Job-level Git Configuration:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'CleanCheckout'],
                        [$class: 'CloneOption', depth: 1, shallow: true]
                    ],
                    userRemoteConfigs: [[
                        url: 'https://github.com/user/repo.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }
    }
}
```

### 4.1.2 Git Environment Variables

Jenkins automatically provides git-related environment variables:

```bash
echo "Git Branch: $GIT_BRANCH"
echo "Git Commit: $GIT_COMMIT"
echo "Git Previous Commit: $GIT_PREVIOUS_COMMIT"
echo "Git Previous Successful Commit: $GIT_PREVIOUS_SUCCESSFUL_COMMIT"
echo "Git Author Name: $GIT_AUTHOR_NAME"
echo "Git Author Email: $GIT_AUTHOR_EMAIL"
echo "Git Committer Name: $GIT_COMMITTER_NAME"
echo "Git Committer Email: $GIT_COMMITTER_EMAIL"
```

## 4.2 Webhook Configuration

### 4.2.1 GitHub Webhooks

**Setup Steps:**
1. Go to GitHub repository → Settings → Webhooks
2. Add webhook with URL: `http://jenkins-url/github-webhook/`
3. Content type: `application/json`
4. Select events: `Push` and `Pull requests`

**Jenkins Configuration:**
```groovy
pipeline {
    agent any
    
    triggers {
        // GitHub webhook trigger
        githubPush()
    }
    
    stages {
        stage('Build') {
            steps {
                echo "Triggered by GitHub webhook"
                sh 'echo "Commit: $GIT_COMMIT"'
            }
        }
    }
}
```

### 4.2.2 GitLab Webhooks

**GitLab CI Token Configuration:**
1. Project Settings → CI/CD → Pipeline triggers
2. Add trigger token
3. Use webhook URL: `http://jenkins-url/project/job-name`

### 4.2.3 Generic Webhooks

```groovy
pipeline {
    agent any
    
    triggers {
        // Generic webhook with token
        GenericTrigger(
            genericVariables: [
                [key: 'ref', value: '$.ref'],
                [key: 'repository', value: '$.repository.name']
            ],
            token: 'my-secret-token',
            causeString: 'Triggered by $repository on $ref'
        )
    }
    
    stages {
        stage('Build') {
            steps {
                echo "Repository: $repository"
                echo "Branch: $ref"
            }
        }
    }
}
```

## 4.3 Multi-branch Pipelines

### 4.3.1 Creating Multi-branch Pipeline

1. New Item → Multibranch Pipeline
2. Configure Branch Sources (GitHub, GitLab, etc.)
3. Build Configuration → by Jenkinsfile
4. Scan Multibranch Pipeline Triggers

**Benefits:**
- Automatic pipeline creation for new branches
- Branch-specific build history
- Automatic cleanup of old branches
- Pull request validation

### 4.3.2 Jenkinsfile for Multi-branch

```groovy
pipeline {
    agent any
    
    environment {
        BRANCH_TYPE = getBranchType()
    }
    
    stages {
        stage('Build') {
            steps {
                echo "Building branch: ${env.BRANCH_NAME}"
                echo "Branch type: ${BRANCH_TYPE}"
                
                script {
                    switch(env.BRANCH_NAME) {
                        case 'main':
                            sh 'echo "Building main branch - production build"'
                            break
                        case 'develop':
                            sh 'echo "Building develop branch - integration build"'
                            break
                        case ~/feature\/.*/:
                            sh 'echo "Building feature branch"'
                            break
                        case ~/release\/.*/:
                            sh 'echo "Building release branch"'
                            break
                        case ~/hotfix\/.*/:
                            sh 'echo "Building hotfix branch"'
                            break
                        default:
                            sh 'echo "Building unknown branch type"'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Running tests for ${BRANCH_NAME}"'
            }
        }
        
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    expression { return env.BRANCH_NAME.startsWith('release/') }
                }
            }
            steps {
                script {
                    def deployEnv = getDeploymentEnvironment()
                    sh "echo 'Deploying to ${deployEnv}'"
                }
            }
        }
    }
}

def getBranchType() {
    if (env.BRANCH_NAME == 'main') return 'production'
    if (env.BRANCH_NAME == 'develop') return 'integration'
    if (env.BRANCH_NAME.startsWith('feature/')) return 'feature'
    if (env.BRANCH_NAME.startsWith('release/')) return 'release'
    if (env.BRANCH_NAME.startsWith('hotfix/')) return 'hotfix'
    return 'unknown'
}

def getDeploymentEnvironment() {
    if (env.BRANCH_NAME == 'main') return 'production'
    if (env.BRANCH_NAME == 'develop') return 'staging'
    if (env.BRANCH_NAME.startsWith('release/')) return 'staging'
    return 'development'
}
```

## 4.4 Branch Strategies

### 4.4.1 Git Flow Strategy

```groovy
pipeline {
    agent any
    
    stages {
        stage('Validate Branch') {
            steps {
                script {
                    def validBranches = [
                        'main',
                        'develop',
                        ~/^feature\/[a-zA-Z0-9-]+$/,
                        ~/^release\/v\d+\.\d+\.\d+$/,
                        ~/^hotfix\/v\d+\.\d+\.\d+$/
                    ]
                    
                    def isValid = validBranches.any { pattern ->
                        env.BRANCH_NAME ==~ pattern
                    }
                    
                    if (!isValid) {
                        error "Invalid branch name: ${env.BRANCH_NAME}"
                    }
                    
                    echo "✅ Valid branch name: ${env.BRANCH_NAME}"
                }
            }
        }
        
        stage('Build Strategy') {
            steps {
                script {
                    switch(true) {
                        case env.BRANCH_NAME == 'main':
                            buildProduction()
                            break
                        case env.BRANCH_NAME == 'develop':
                            buildIntegration()
                            break
                        case env.BRANCH_NAME.startsWith('feature/'):
                            buildFeature()
                            break
                        case env.BRANCH_NAME.startsWith('release/'):
                            buildRelease()
                            break
                        case env.BRANCH_NAME.startsWith('hotfix/'):
                            buildHotfix()
                            break
                    }
                }
            }
        }
    }
}

def buildProduction() {
    echo "🚀 Production build"
    sh '''
        echo "Building for production..."
        echo "Running full test suite..."
        echo "Creating production artifacts..."
    '''
}

def buildIntegration() {
    echo "🔄 Integration build"
    sh '''
        echo "Building for integration..."
        echo "Running integration tests..."
        echo "Deploying to staging..."
    '''
}

def buildFeature() {
    echo "🔧 Feature build"
    sh '''
        echo "Building feature branch..."
        echo "Running unit tests..."
        echo "Code quality checks..."
    '''
}

def buildRelease() {
    echo "📦 Release build"
    sh '''
        echo "Building release candidate..."
        echo "Running full test suite..."
        echo "Creating release artifacts..."
    '''
}

def buildHotfix() {
    echo "🚨 Hotfix build"
    sh '''
        echo "Building hotfix..."
        echo "Running critical tests..."
        echo "Fast-track deployment preparation..."
    '''
}
```

### 4.4.2 GitHub Flow Strategy

```groovy
pipeline {
    agent any
    
    stages {
        stage('PR Validation') {
            when {
                changeRequest()
            }
            steps {
                echo "🔍 Validating Pull Request"
                sh '''
                    echo "PR Number: ${CHANGE_ID}"
                    echo "PR Title: ${CHANGE_TITLE}"
                    echo "PR Author: ${CHANGE_AUTHOR}"
                    echo "Target Branch: ${CHANGE_TARGET}"
                '''
            }
        }
        
        stage('Build & Test') {
            steps {
                script {
                    if (env.CHANGE_ID) {
                        echo "Building PR #${env.CHANGE_ID}"
                    } else {
                        echo "Building branch ${env.BRANCH_NAME}"
                    }
                }
                
                sh '''
                    echo "Running build..."
                    echo "Running tests..."
                    echo "Code quality analysis..."
                '''
            }
        }
        
        stage('Deploy Preview') {
            when {
                changeRequest()
            }
            steps {
                script {
                    def previewUrl = "https://pr-${env.CHANGE_ID}.preview.example.com"
                    sh "echo 'Deploying preview to ${previewUrl}'"
                    
                    // Add PR comment with preview URL
                    if (env.CHANGE_ID) {
                        sh """
                            echo "Preview deployed: ${previewUrl}" > pr-comment.txt
                        """
                    }
                }
            }
        }
        
        stage('Deploy Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh 'echo "Deploying to production..."'
            }
        }
    }
    
    post {
        success {
            script {
                if (env.CHANGE_ID) {
                    echo "✅ PR #${env.CHANGE_ID} validation successful"
                }
            }
        }
        
        failure {
            script {
                if (env.CHANGE_ID) {
                    echo "❌ PR #${env.CHANGE_ID} validation failed"
                }
            }
        }
    }
}
```

## 4.5 Credential Management

### 4.5.1 Adding Git Credentials

**Username/Password:**
1. Manage Jenkins → Manage Credentials
2. Add Credentials → Username with password
3. Use in pipeline: `credentialsId: 'git-credentials'`

**SSH Key:**
1. Generate SSH key: `ssh-keygen -t rsa -b 4096`
2. Add public key to Git provider
3. Add private key to Jenkins credentials
4. Use SSH URL in repository configuration

**Personal Access Token:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/user/repo.git',
                        credentialsId: 'github-token'
                    ]]
                ])
            }
        }
    }
}
```

### 4.5.2 Using Credentials in Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Use Credentials') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'git-credentials',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "Username: $GIT_USERNAME"
                        # Password is available as $GIT_PASSWORD
                        git config user.name "$GIT_USERNAME"
                    '''
                }
                
                withCredentials([
                    string(credentialsId: 'api-token', variable: 'API_TOKEN')
                ]) {
                    sh 'curl -H "Authorization: Bearer $API_TOKEN" https://api.example.com'
                }
            }
        }
    }
}
```

## 4.6 Advanced Git Operations

### 4.6.1 Git Operations in Pipeline

```groovy
pipeline {
    agent any
    
    stages {
        stage('Git Operations') {
            steps {
                script {
                    // Get git information
                    def gitCommit = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    def gitBranch = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    def gitAuthor = sh(script: 'git log -1 --pretty=format:"%an"', returnStdout: true).trim()
                    def gitMessage = sh(script: 'git log -1 --pretty=format:"%s"', returnStdout: true).trim()
                    
                    echo "Commit: ${gitCommit}"
                    echo "Branch: ${gitBranch}"
                    echo "Author: ${gitAuthor}"
                    echo "Message: ${gitMessage}"
                    
                    // Check for changes in specific paths
                    def changedFiles = sh(
                        script: 'git diff --name-only HEAD~1 HEAD',
                        returnStdout: true
                    ).trim().split('\n')
                    
                    echo "Changed files: ${changedFiles}"
                    
                    // Conditional logic based on changes
                    def frontendChanged = changedFiles.any { it.startsWith('frontend/') }
                    def backendChanged = changedFiles.any { it.startsWith('backend/') }
                    
                    if (frontendChanged) {
                        echo "Frontend changes detected"
                    }
                    
                    if (backendChanged) {
                        echo "Backend changes detected"
                    }
                }
            }
        }
        
        stage('Tagging') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def version = "v1.0.${env.BUILD_NUMBER}"
                    
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'git-credentials',
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )
                    ]) {
                        sh """
                            git config user.name 'Jenkins'
                            git config user.email 'jenkins@company.com'
                            git tag -a ${version} -m 'Release ${version}'
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/user/repo.git ${version}
                        """
                    }
                    
                    echo "Tagged release: ${version}"
                }
            }
        }
    }
}
```

### 4.6.2 Submodule Support

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout with Submodules') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [
                        [$class: 'SubmoduleOption',
                         disableSubmodules: false,
                         parentCredentials: true,
                         recursiveSubmodules: true,
                         reference: '',
                         trackingSubmodules: false]
                    ],
                    userRemoteConfigs: [[
                        url: 'https://github.com/user/repo.git',
                        credentialsId: 'github-credentials'
                    ]]
                ])
            }
        }
    }
}
```

## Hands-on Exercise 4.1: Multi-branch Pipeline Setup

### Step 1: Create Sample Repository Structure

```bash
# Create sample project
mkdir jenkins-multibranch-demo
cd jenkins-multibranch-demo

# Initialize git
git init
git checkout -b main

# Create Jenkinsfile
cat > Jenkinsfile << 'EOF'
pipeline {
    agent any
    
    environment {
        APP_NAME = 'multibranch-demo'
        BRANCH_TYPE = getBranchType()
    }
    
    stages {
        stage('Info') {
            steps {
                echo "Branch: ${env.BRANCH_NAME}"
                echo "Branch Type: ${env.BRANCH_TYPE}"
                echo "Build Number: ${env.BUILD_NUMBER}"
            }
        }
        
        stage('Build') {
            steps {
                script {
                    switch(env.BRANCH_TYPE) {
                        case 'main':
                            sh 'echo "Production build"'
                            break
                        case 'develop':
                            sh 'echo "Development build"'
                            break
                        case 'feature':
                            sh 'echo "Feature build"'
                            break
                        default:
                            sh 'echo "Standard build"'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'echo "Running tests for ${BRANCH_NAME}"'
            }
        }
        
        stage('Deploy') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def environment = env.BRANCH_NAME == 'main' ? 'production' : 'staging'
                    sh "echo 'Deploying to ${environment}'"
                }
            }
        }
    }
}

def getBranchType() {
    if (env.BRANCH_NAME == 'main') return 'main'
    if (env.BRANCH_NAME == 'develop') return 'develop'
    if (env.BRANCH_NAME.startsWith('feature/')) return 'feature'
    if (env.BRANCH_NAME.startsWith('release/')) return 'release'
    if (env.BRANCH_NAME.startsWith('hotfix/')) return 'hotfix'
    return 'other'
}
EOF

# Create sample application files
echo "console.log('Hello from main branch!');" > app.js
echo "# Multibranch Demo" > README.md

# Commit to main
git add .
git commit -m "Initial commit"

# Create develop branch
git checkout -b develop
echo "console.log('Hello from develop branch!');" > app.js
git add app.js
git commit -m "Update app for develop branch"

# Create feature branch
git checkout -b feature/new-feature
echo "console.log('Hello from feature branch!');" > app.js
echo "// New feature code" >> app.js
git add app.js
git commit -m "Add new feature"

# Back to main
git checkout main
```

### Step 2: Configure Multi-branch Pipeline in Jenkins

1. Create new item: "Multibranch Pipeline Demo"
2. Select "Multibranch Pipeline"
3. Add Branch Source → Git
4. Repository URL: your repository URL
5. Credentials: select appropriate credentials
6. Save configuration

## Quiz: Module 4

1. What's the difference between polling and webhooks?
2. How do you access git commit information in a pipeline?
3. What are the benefits of multi-branch pipelines?
4. How do you securely store git credentials in Jenkins?
5. How do you conditionally run stages based on the branch name?

## Key Takeaways

- Git integration is essential for modern CI/CD
- Webhooks provide real-time build triggers
- Multi-branch pipelines automate branch management
- Proper credential management ensures security
- Branch strategies enable different build behaviors

## Next Module

In [Module 5](../module-05-build-tools/), we'll explore integrating various build tools like Maven, Gradle, and Node.js with Jenkins.