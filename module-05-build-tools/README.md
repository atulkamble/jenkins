# Module 5: Build Tools Integration

## Learning Objectives

By the end of this module, you will:
- Integrate Maven with Jenkins
- Configure Gradle builds
- Set up Node.js projects
- Work with Docker in pipelines
- Implement multi-language builds
- Optimize build performance

## 5.1 Maven Integration

### 5.1.1 Maven Configuration

**Global Tool Configuration:**
1. Manage Jenkins → Global Tool Configuration
2. Add Maven installation
3. Configure Maven settings and global settings files

**Pipeline Configuration:**
```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven-3.8'  // Name from Global Tool Configuration
        jdk 'JDK-11'       // Java version
    }
    
    environment {
        MAVEN_OPTS = '-Xmx1024m -XX:MaxPermSize=256m'
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
    }
}
```

### 5.1.2 Advanced Maven Pipeline

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    environment {
        MAVEN_OPTS = '-Xmx2048m -XX:MaxMetaspaceSize=512m'
        MAVEN_SETTINGS = 'maven-settings'  // Settings file ID in Jenkins
    }
    
    parameters {
        choice(name: 'PROFILE', choices: ['dev', 'staging', 'prod'], description: 'Maven profile')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip tests')
        booleanParam(name: 'DEPLOY_ARTIFACTS', defaultValue: false, description: 'Deploy to repository')
    }
    
    stages {
        stage('Validate') {
            steps {
                sh '''
                    echo "Maven version:"
                    mvn -version
                    echo "Java version:"
                    java -version
                    echo "Validating POM..."
                    mvn validate
                '''
            }
        }
        
        stage('Compile') {
            steps {
                configFileProvider([configFile(fileId: env.MAVEN_SETTINGS, variable: 'MAVEN_SETTINGS_FILE')]) {
                    sh 'mvn -s $MAVEN_SETTINGS_FILE clean compile -P${PROFILE}'
                }
            }
        }
        
        stage('Test') {
            when {
                expression { !params.SKIP_TESTS }
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test -P${PROFILE}'
                    }
                    post {
                        always {
                            junit 'target/surefire-reports/*.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh 'mvn integration-test -P${PROFILE}'
                    }
                    post {
                        always {
                            junit 'target/failsafe-reports/*.xml'
                        }
                    }
                }
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('SonarQube Analysis') {
                    steps {
                        withSonarQubeEnv('SonarQube') {
                            sh 'mvn sonar:sonar -P${PROFILE}'
                        }
                    }
                }
                
                stage('Dependency Check') {
                    steps {
                        sh 'mvn dependency-check:check'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'target/dependency-check-report',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'Dependency Check Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests -P${PROFILE}'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar, target/*.war', fingerprint: true
                }
            }
        }
        
        stage('Deploy Artifacts') {
            when {
                expression { params.DEPLOY_ARTIFACTS }
            }
            steps {
                configFileProvider([configFile(fileId: env.MAVEN_SETTINGS, variable: 'MAVEN_SETTINGS_FILE')]) {
                    sh 'mvn deploy -DskipTests -s $MAVEN_SETTINGS_FILE -P${PROFILE}'
                }
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

### 5.1.3 Maven Multi-module Projects

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven-3.8'
        jdk 'JDK-11'
    }
    
    stages {
        stage('Build All Modules') {
            steps {
                sh 'mvn clean compile -pl .,core,web,api'
            }
        }
        
        stage('Test Modules') {
            parallel {
                stage('Core Module Tests') {
                    steps {
                        sh 'mvn test -pl core'
                    }
                    post {
                        always {
                            junit 'core/target/surefire-reports/*.xml'
                        }
                    }
                }
                
                stage('Web Module Tests') {
                    steps {
                        sh 'mvn test -pl web'
                    }
                    post {
                        always {
                            junit 'web/target/surefire-reports/*.xml'
                        }
                    }
                }
                
                stage('API Module Tests') {
                    steps {
                        sh 'mvn test -pl api'
                    }
                    post {
                        always {
                            junit 'api/target/surefire-reports/*.xml'
                        }
                    }
                }
            }
        }
        
        stage('Package All') {
            steps {
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: '**/target/*.jar, **/target/*.war', fingerprint: true
                }
            }
        }
    }
}
```

## 5.2 Gradle Integration

### 5.2.1 Basic Gradle Pipeline

```groovy
pipeline {
    agent any
    
    tools {
        gradle 'Gradle-7.6'  // Or use wrapper
        jdk 'JDK-11'
    }
    
    environment {
        GRADLE_OPTS = '-Xmx2048m -Dorg.gradle.daemon=false'
    }
    
    stages {
        stage('Build') {
            steps {
                sh './gradlew clean build --no-daemon'
            }
        }
        
        stage('Test') {
            steps {
                sh './gradlew test --no-daemon'
            }
            post {
                always {
                    junit 'build/test-results/test/*.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'build/reports/tests/test',
                        reportFiles: 'index.html',
                        reportName: 'Test Report'
                    ])
                }
            }
        }
        
        stage('Code Coverage') {
            steps {
                sh './gradlew jacocoTestReport --no-daemon'
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'build/reports/jacoco/test/html',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage Report'
                    ])
                }
            }
        }
        
        stage('Package') {
            steps {
                sh './gradlew bootJar --no-daemon'  // For Spring Boot
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                }
            }
        }
    }
}
```

### 5.2.2 Advanced Gradle Pipeline

```groovy
pipeline {
    agent any
    
    tools {
        jdk 'JDK-11'
    }
    
    environment {
        GRADLE_OPTS = '-Xmx3072m -Dorg.gradle.daemon=false -Dorg.gradle.parallel=true'
    }
    
    parameters {
        choice(name: 'BUILD_TYPE', choices: ['debug', 'release'], description: 'Build type')
        booleanParam(name: 'RUN_INTEGRATION_TESTS', defaultValue: true, description: 'Run integration tests')
        string(name: 'VERSION_SUFFIX', defaultValue: '', description: 'Version suffix (e.g., -SNAPSHOT)')
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    echo "Gradle Wrapper version:"
                    ./gradlew --version
                    
                    echo "Setting up build properties..."
                    echo "buildType=${BUILD_TYPE}" > gradle.properties
                    echo "versionSuffix=${VERSION_SUFFIX}" >> gradle.properties
                '''
            }
        }
        
        stage('Dependencies') {
            steps {
                sh './gradlew dependencies --no-daemon'
            }
        }
        
        stage('Compile') {
            parallel {
                stage('Compile Main') {
                    steps {
                        sh './gradlew compileJava --no-daemon'
                    }
                }
                
                stage('Compile Test') {
                    steps {
                        sh './gradlew compileTestJava --no-daemon'
                    }
                }
            }
        }
        
        stage('Static Analysis') {
            parallel {
                stage('Checkstyle') {
                    steps {
                        sh './gradlew checkstyleMain checkstyleTest --no-daemon'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'build/reports/checkstyle',
                                reportFiles: 'main.html',
                                reportName: 'Checkstyle Report'
                            ])
                        }
                    }
                }
                
                stage('SpotBugs') {
                    steps {
                        sh './gradlew spotbugsMain --no-daemon'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'build/reports/spotbugs',
                                reportFiles: 'main.html',
                                reportName: 'SpotBugs Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh './gradlew test --no-daemon'
                    }
                    post {
                        always {
                            junit 'build/test-results/test/*.xml'
                        }
                    }
                }
                
                stage('Integration Tests') {
                    when {
                        expression { params.RUN_INTEGRATION_TESTS }
                    }
                    steps {
                        sh './gradlew integrationTest --no-daemon'
                    }
                    post {
                        always {
                            junit 'build/test-results/integrationTest/*.xml'
                        }
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                sh """
                    ./gradlew build -PbuildType=${params.BUILD_TYPE} --no-daemon
                """
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/libs/*.jar, build/distributions/*', fingerprint: true
                }
            }
        }
        
        stage('Publish') {
            when {
                branch 'main'
            }
            steps {
                sh './gradlew publish --no-daemon'
            }
        }
    }
    
    post {
        always {
            // Cleanup Gradle cache if needed
            sh 'rm -rf ~/.gradle/caches/modules-2/modules-2.lock'
            cleanWs()
        }
    }
}
```

## 5.3 Node.js Integration

### 5.3.1 Basic Node.js Pipeline

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS-18'  // Configure in Global Tool Configuration
    }
    
    environment {
        NODE_ENV = 'development'
        CI = 'true'
    }
    
    stages {
        stage('Setup') {
            steps {
                sh '''
                    echo "Node.js version:"
                    node --version
                    echo "npm version:"
                    npm --version
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'  // Use npm ci for faster, reliable CI builds
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
            post {
                always {
                    // Publish test results if using Jest with JUnit reporter
                    junit 'test-results.xml'
                    
                    // Publish coverage report if available
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
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
                    echo "Creating deployment package..."
                    tar -czf app-${BUILD_NUMBER}.tar.gz build/ package.json package-lock.json
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: '*.tar.gz', fingerprint: true
                }
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

### 5.3.2 Advanced Node.js Pipeline with Multiple Environments

```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS-18'
    }
    
    environment {
        CI = 'true'
        HUSKY = '0'  // Disable Husky in CI
    }
    
    parameters {
        choice(name: 'NODE_ENV', choices: ['development', 'staging', 'production'], description: 'Node environment')
        booleanParam(name: 'RUN_E2E_TESTS', defaultValue: false, description: 'Run end-to-end tests')
        booleanParam(name: 'PUBLISH_NPM', defaultValue: false, description: 'Publish to npm registry')
    }
    
    stages {
        stage('Environment Setup') {
            steps {
                script {
                    env.NODE_ENV = params.NODE_ENV
                }
                
                sh '''
                    echo "=== Environment Information ==="
                    echo "Node.js: $(node --version)"
                    echo "npm: $(npm --version)"
                    echo "NODE_ENV: $NODE_ENV"
                    echo "Current directory: $(pwd)"
                    echo "Available memory: $(free -h || echo 'N/A')"
                    echo ""
                '''
            }
        }
        
        stage('Cache Check') {
            steps {
                script {
                    // Check if package-lock.json changed
                    def packageLockChanged = sh(
                        script: 'git diff --name-only HEAD~1 HEAD | grep package-lock.json || true',
                        returnStdout: true
                    ).trim()
                    
                    if (packageLockChanged) {
                        echo "📦 package-lock.json changed, dependencies will be reinstalled"
                    } else {
                        echo "📦 package-lock.json unchanged, using cached dependencies"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    echo "🔧 Installing dependencies..."
                    npm ci --prefer-offline --no-audit
                    
                    echo "📋 Listing installed packages..."
                    npm list --depth=0
                '''
            }
        }
        
        stage('Security Audit') {
            steps {
                sh '''
                    echo "🔒 Running security audit..."
                    npm audit --audit-level moderate || true
                '''
            }
        }
        
        stage('Lint & Format Check') {
            parallel {
                stage('ESLint') {
                    steps {
                        sh '''
                            echo "🔍 Running ESLint..."
                            npm run lint -- --format=junit --output-file=eslint-results.xml || true
                        '''
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: 'eslint-results.xml'
                        }
                    }
                }
                
                stage('Prettier Check') {
                    steps {
                        sh '''
                            echo "💅 Checking code formatting..."
                            npm run format:check || true
                        '''
                    }
                }
                
                stage('Type Check') {
                    when {
                        expression {
                            return fileExists('tsconfig.json')
                        }
                    }
                    steps {
                        sh '''
                            echo "📝 Running TypeScript type check..."
                            npm run type-check || npx tsc --noEmit
                        '''
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh '''
                            echo "🧪 Running unit tests..."
                            npm run test:unit -- --coverage --reporters=default --reporters=jest-junit
                        '''
                    }
                    post {
                        always {
                            junit 'junit.xml'
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage',
                                reportFiles: 'index.html',
                                reportName: 'Code Coverage Report'
                            ])
                        }
                    }
                }
                
                stage('Integration Tests') {
                    steps {
                        sh '''
                            echo "🔗 Running integration tests..."
                            npm run test:integration || true
                        '''
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                sh """
                    echo "🏗️ Building application for ${params.NODE_ENV}..."
                    NODE_ENV=${params.NODE_ENV} npm run build
                    
                    echo "📊 Build statistics:"
                    du -sh build/ || du -sh dist/ || echo "Build directory not found"
                    find build/ -name "*.js" -o -name "*.css" | wc -l || echo "JS/CSS files count: N/A"
                """
            }
        }
        
        stage('End-to-End Tests') {
            when {
                expression { params.RUN_E2E_TESTS }
            }
            steps {
                sh '''
                    echo "🎭 Running end-to-end tests..."
                    npm run test:e2e || true
                '''
            }
            post {
                always {
                    // Archive E2E test screenshots/videos if available
                    archiveArtifacts artifacts: 'cypress/screenshots/**, cypress/videos/**', allowEmptyArchive: true
                }
            }
        }
        
        stage('Bundle Analysis') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    echo "📈 Analyzing bundle size..."
                    npm run analyze || echo "Bundle analysis not available"
                '''
            }
        }
        
        stage('Package') {
            steps {
                script {
                    def packageName = readJSON file: 'package.json'
                    def appName = packageName.name
                    def version = packageName.version
                    
                    sh """
                        echo "📦 Creating deployment package..."
                        echo "App: ${appName}"
                        echo "Version: ${version}"
                        
                        # Create package with build artifacts
                        tar -czf ${appName}-${version}-${BUILD_NUMBER}.tar.gz \\
                            build/ \\
                            package.json \\
                            package-lock.json \\
                            server/ \\
                            public/ \\
                            --exclude='node_modules' \\
                            --exclude='.git' \\
                            --exclude='coverage' \\
                            --exclude='test'
                        
                        # Create deployment info
                        cat > deployment-info.json << EOF
{
  "name": "${appName}",
  "version": "${version}",
  "buildNumber": "${BUILD_NUMBER}",
  "gitCommit": "${GIT_COMMIT}",
  "gitBranch": "${GIT_BRANCH}",
  "buildDate": "\$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "nodeVersion": "\$(node --version)",
  "environment": "${params.NODE_ENV}"
}
EOF
                    """
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: '*.tar.gz, deployment-info.json', fingerprint: true
                }
            }
        }
        
        stage('Publish to npm') {
            when {
                allOf {
                    branch 'main'
                    expression { params.PUBLISH_NPM }
                }
            }
            steps {
                withCredentials([string(credentialsId: 'npm-token', variable: 'NPM_TOKEN')]) {
                    sh '''
                        echo "📤 Publishing to npm..."
                        echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
                        npm publish --access public
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Clean up
            sh 'rm -f ~/.npmrc'
            cleanWs()
        }
        
        success {
            echo '✅ Node.js build completed successfully!'
        }
        
        failure {
            echo '❌ Node.js build failed!'
        }
    }
}
```

## 5.4 Docker Integration

### 5.4.1 Basic Docker Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                    env.IMAGE_ID = image.id
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    docker.image("${IMAGE_NAME}:${IMAGE_TAG}").inside {
                        sh '''
                            echo "Testing application inside container..."
                            # Run application tests
                        '''
                    }
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-hub-credentials') {
                        def image = docker.image("${IMAGE_NAME}:${IMAGE_TAG}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
    }
}
```

### 5.4.2 Multi-stage Docker Build

```groovy
pipeline {
    agent any
    
    environment {
        REGISTRY = 'your-registry.com'
        IMAGE_NAME = 'myapp'
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Build Multi-stage Image') {
            steps {
                script {
                    // Create Dockerfile if it doesn't exist
                    writeFile file: 'Dockerfile', text: '''
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production
WORKDIR /app

# Copy built application
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
CMD ["npm", "start"]
'''
                    
                    // Build the image
                    def image = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                    
                    // Tag for different environments
                    if (env.BRANCH_NAME == 'main') {
                        image.tag('latest')
                        image.tag('production')
                    } else if (env.BRANCH_NAME == 'develop') {
                        image.tag('staging')
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    // Run container security scan (requires appropriate tools)
                    sh """
                        echo "Running security scan on ${IMAGE_NAME}:${IMAGE_TAG}"
                        # docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                        #   aquasec/trivy image ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Integration Test') {
            steps {
                script {
                    // Run integration tests using Docker Compose
                    sh '''
                        cat > docker-compose.test.yml << EOF
version: '3.8'
services:
  app:
    image: ''' + IMAGE_NAME + ''':''' + IMAGE_TAG + '''
    environment:
      - NODE_ENV=test
    ports:
      - "3000:3000"
  
  test:
    image: ''' + IMAGE_NAME + ''':''' + IMAGE_TAG + '''
    command: npm run test:integration
    depends_on:
      - app
    environment:
      - APP_URL=http://app:3000
EOF

                        docker-compose -f docker-compose.test.yml up --abort-on-container-exit
                    '''
                }
            }
            post {
                always {
                    sh 'docker-compose -f docker-compose.test.yml down || true'
                }
            }
        }
        
        stage('Push Images') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${REGISTRY}", 'registry-credentials') {
                        def image = docker.image("${IMAGE_NAME}:${IMAGE_TAG}")
                        image.push()
                        
                        if (env.BRANCH_NAME == 'main') {
                            image.push('latest')
                            image.push('production')
                        } else if (env.BRANCH_NAME == 'develop') {
                            image.push('staging')
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images and containers
            sh '''
                docker image prune -f
                docker container prune -f
            '''
        }
    }
}
```

## Hands-on Exercise 5.1: Multi-language Build Pipeline

### Create a Sample Multi-language Project

```groovy
pipeline {
    agent any
    
    stages {
        stage('Detect Project Types') {
            steps {
                script {
                    def projectTypes = []
                    
                    if (fileExists('pom.xml')) {
                        projectTypes.add('maven')
                    }
                    
                    if (fileExists('build.gradle') || fileExists('build.gradle.kts')) {
                        projectTypes.add('gradle')
                    }
                    
                    if (fileExists('package.json')) {
                        projectTypes.add('nodejs')
                    }
                    
                    if (fileExists('requirements.txt') || fileExists('setup.py')) {
                        projectTypes.add('python')
                    }
                    
                    if (fileExists('Dockerfile')) {
                        projectTypes.add('docker')
                    }
                    
                    env.PROJECT_TYPES = projectTypes.join(',')
                    echo "Detected project types: ${env.PROJECT_TYPES}"
                }
            }
        }
        
        stage('Build Projects') {
            parallel {
                stage('Maven Build') {
                    when {
                        expression { env.PROJECT_TYPES.contains('maven') }
                    }
                    steps {
                        sh '''
                            echo "🔨 Building Maven project..."
                            mvn clean compile test package
                        '''
                    }
                }
                
                stage('Gradle Build') {
                    when {
                        expression { env.PROJECT_TYPES.contains('gradle') }
                    }
                    steps {
                        sh '''
                            echo "🔨 Building Gradle project..."
                            ./gradlew clean build
                        '''
                    }
                }
                
                stage('Node.js Build') {
                    when {
                        expression { env.PROJECT_TYPES.contains('nodejs') }
                    }
                    steps {
                        sh '''
                            echo "🔨 Building Node.js project..."
                            npm ci
                            npm run build
                        '''
                    }
                }
                
                stage('Python Build') {
                    when {
                        expression { env.PROJECT_TYPES.contains('python') }
                    }
                    steps {
                        sh '''
                            echo "🔨 Building Python project..."
                            pip install -r requirements.txt
                            python -m pytest
                        '''
                    }
                }
                
                stage('Docker Build') {
                    when {
                        expression { env.PROJECT_TYPES.contains('docker') }
                    }
                    steps {
                        script {
                            def image = docker.build("multiproject:${env.BUILD_NUMBER}")
                        }
                    }
                }
            }
        }
    }
}
```

## Quiz: Module 5

1. What's the difference between `mvn clean compile` and `mvn clean install`?
2. When should you use `npm ci` instead of `npm install` in CI?
3. How do you run Gradle builds without the daemon in CI?
4. What are the benefits of multi-stage Docker builds?
5. How do you handle different build tools in the same pipeline?

## Key Takeaways

- Different build tools require specific configurations
- Parallel builds improve pipeline performance
- Proper caching strategies reduce build times
- Multi-stage builds optimize Docker images
- Tool-specific reporting enhances visibility

## Next Module

In [Module 6](../module-06-testing-quality/), we'll explore testing integration and quality gates in Jenkins pipelines.