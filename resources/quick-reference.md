# Jenkins Course - Quick Reference Guide

## Course Overview

This comprehensive Jenkins course covers everything from basic concepts to advanced enterprise implementations. Each module builds upon the previous one, providing hands-on experience with real-world scenarios.

## Module Summary

| Module | Topic | Key Skills | Duration |
|--------|-------|------------|----------|
| 1 | Jenkins Fundamentals | Installation, UI navigation, basic jobs | 4-6 hours |
| 2 | Jobs and Builds | Build triggers, parameters, artifacts | 4-5 hours |
| 3 | Pipelines | Declarative/Scripted pipelines, Pipeline as Code | 6-8 hours |
| 4 | Source Code Management | Git integration, webhooks, multi-branch | 4-5 hours |
| 5 | Build Tools Integration | Maven, Gradle, Node.js, Docker | 5-7 hours |
| 6 | Testing and Quality | Test automation, code quality, reporting | 4-5 hours |
| 7 | Deployment | Deployment strategies, environments | 5-6 hours |
| 8 | Security | Authentication, authorization, best practices | 3-4 hours |
| 9 | Administration | Plugin management, backup, monitoring | 4-5 hours |
| 10 | Advanced Topics | JCasC, distributed builds, API | 6-8 hours |

## Quick Commands Reference

### Jenkins CLI
```bash
# Download Jenkins CLI
curl -O http://jenkins-url/jnlpJars/jenkins-cli.jar

# Basic commands
java -jar jenkins-cli.jar -s http://jenkins-url -auth user:token help
java -jar jenkins-cli.jar -s http://jenkins-url build job-name
java -jar jenkins-cli.jar -s http://jenkins-url list-jobs
```

### Pipeline Syntax

#### Basic Declarative Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}
```

#### Basic Scripted Pipeline
```groovy
node {
    stage('Build') {
        echo 'Building...'
    }
}
```

### Common Pipeline Steps
```groovy
// Shell commands
sh 'echo "Hello World"'
sh script: 'ls -la', returnStdout: true

// File operations
writeFile file: 'test.txt', text: 'content'
readFile 'test.txt'

// Git operations
checkout scm
sh 'git tag v${BUILD_NUMBER}'

// Docker operations
docker.build("image:${BUILD_NUMBER}")
docker.image('image').inside { }

// Artifacts
archiveArtifacts artifacts: '*.jar'
publishTestResults testResultsPattern: '*.xml'

// Parallel execution
parallel {
    'Branch A': { sh 'echo A' },
    'Branch B': { sh 'echo B' }
}
```

## Environment Variables

### Built-in Variables
| Variable | Description |
|----------|-------------|
| `BUILD_NUMBER` | Build number |
| `BUILD_URL` | Build URL |
| `JOB_NAME` | Job name |
| `WORKSPACE` | Workspace path |
| `NODE_NAME` | Node name |
| `JENKINS_URL` | Jenkins URL |
| `GIT_COMMIT` | Git commit hash |
| `GIT_BRANCH` | Git branch |

### Setting Custom Variables
```groovy
environment {
    MY_VAR = 'value'
    VERSION = "${env.BUILD_NUMBER}"
}
```

## Build Triggers

### Cron Syntax
```
# Field order: MINUTE HOUR DOM MONTH DOW
H/15 * * * *     # Every 15 minutes
H 2 * * *        # Daily at 2 AM
H 2 * * 1-5      # Weekdays at 2 AM
H 0 1 * *        # Monthly on 1st
```

### Webhook Configuration
```bash
# GitHub webhook URL
http://jenkins-url/github-webhook/

# Generic webhook URL
http://jenkins-url/generic-webhook-trigger/invoke?token=TOKEN
```

## Plugin Essentials

### Must-Have Plugins
- **Pipeline** - Pipeline as Code
- **Git** - Git SCM integration
- **Blue Ocean** - Modern UI
- **Docker Pipeline** - Docker integration
- **Credentials Binding** - Secure credential handling
- **Build Timeout** - Build timeouts
- **Timestamper** - Timestamp logs
- **Workspace Cleanup** - Clean workspaces

### Quality & Testing Plugins
- **JUnit** - Test result publishing
- **JaCoCo** - Code coverage
- **SonarQube Scanner** - Code quality
- **Checkstyle** - Static analysis
- **HTML Publisher** - HTML reports

### Notification Plugins
- **Email Extension** - Enhanced email
- **Slack Notification** - Slack integration
- **Microsoft Teams** - Teams integration

## Security Best Practices

### Authentication
1. Enable security in Jenkins
2. Use LDAP/Active Directory for enterprise
3. Implement strong password policies
4. Enable two-factor authentication

### Authorization
1. Use matrix-based security
2. Follow principle of least privilege
3. Create role-based access control
4. Regular permission audits

### Credentials Management
1. Use Jenkins Credential Store
2. Avoid hardcoded secrets
3. Rotate credentials regularly
4. Use credential binding in pipelines

### Pipeline Security
```groovy
// Use credentials safely
withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
    sh 'curl -H "Authorization: Bearer $API_KEY" api.example.com'
}

// Sandbox untrusted code
@NonCPS
def untrustedFunction() {
    // Function body
}
```

## Troubleshooting Guide

### Common Issues

#### Build Fails with "No space left on device"
```bash
# Clean workspace
cleanWs()

# Clean Docker
docker system prune -f

# Check disk usage
df -h
```

#### Pipeline Stuck or Slow
```groovy
// Add timeout
timeout(time: 30, unit: 'MINUTES') {
    // Build steps
}

// Use parallel execution
parallel {
    'Test A': { /* tests */ },
    'Test B': { /* tests */ }
}
```

#### Permission Denied Errors
```bash
# Fix permissions
chmod +x script.sh

# Use correct user
USER jenkins
```

#### Git Authentication Issues
```groovy
// Use SSH keys
checkout([$class: 'GitSCM', 
    userRemoteConfigs: [[
        url: 'git@github.com:user/repo.git',
        credentialsId: 'ssh-key-id'
    ]]
])
```

### Debugging Techniques

#### Enable Debug Logging
```groovy
pipeline {
    options {
        timestamps()
    }
    stages {
        stage('Debug') {
            steps {
                sh 'env | sort'  // Print all environment variables
                sh 'pwd && ls -la'  // Show current directory
            }
        }
    }
}
```

#### Interactive Debugging
```groovy
// Add input step for debugging
input message: 'Debug point - check logs and continue'

// Use script blocks for complex debugging
script {
    echo "Current branch: ${env.BRANCH_NAME}"
    if (env.BRANCH_NAME == 'debug') {
        sh 'sleep 300'  // Hold for inspection
    }
}
```

## Performance Optimization

### Build Performance
1. Use parallel execution
2. Cache dependencies
3. Optimize Docker layers
4. Use incremental builds
5. Clean up artifacts regularly

### Jenkins Performance
1. Configure adequate heap size
2. Use SSD storage
3. Distribute builds across agents
4. Monitor system resources
5. Regular maintenance

### Pipeline Best Practices
```groovy
pipeline {
    options {
        // Skip checkout on agents
        skipDefaultCheckout()
        
        // Build timeout
        timeout(time: 1, unit: 'HOURS')
        
        // Retry failed builds
        retry(3)
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Shallow clone for speed
                checkout([$class: 'GitSCM',
                    extensions: [[$class: 'CloneOption', depth: 1, shallow: true]]
                ])
            }
        }
    }
}
```

## Backup and Recovery

### What to Backup
1. `JENKINS_HOME` directory
2. Job configurations
3. Plugin lists
4. User configurations
5. Build histories (optional)

### Backup Script
```bash
#!/bin/bash
JENKINS_HOME=/var/lib/jenkins
BACKUP_DIR=/backup/jenkins/$(date +%Y%m%d)

mkdir -p $BACKUP_DIR

# Stop Jenkins
systemctl stop jenkins

# Create backup
tar -czf $BACKUP_DIR/jenkins-backup.tar.gz -C $JENKINS_HOME .

# Start Jenkins
systemctl start jenkins

echo "Backup completed: $BACKUP_DIR/jenkins-backup.tar.gz"
```

## Monitoring and Maintenance

### Health Monitoring
1. System resource usage
2. Build queue length
3. Failed build rates
4. Plugin update status
5. Security advisories

### Regular Maintenance Tasks
1. Update Jenkins core
2. Update plugins
3. Clean old builds
4. Archive logs
5. Monitor disk space
6. Review security settings

### Monitoring Script
```bash
#!/bin/bash
# Basic Jenkins health check

JENKINS_URL="http://localhost:8080"

# Check if Jenkins is running
if curl -s "$JENKINS_URL" > /dev/null; then
    echo "✅ Jenkins is running"
else
    echo "❌ Jenkins is not responding"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df -h /var/lib/jenkins | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "⚠️ Disk usage is high: ${DISK_USAGE}%"
fi

echo "Jenkins health check completed"
```

## Additional Resources

### Documentation
- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Pipeline Syntax Reference](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Plugin Index](https://plugins.jenkins.io/)

### Community
- [Jenkins Community](https://www.jenkins.io/community/)
- [Jenkins Users Mailing List](https://groups.google.com/g/jenkinsci-users)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/jenkins)

### Training
- [CloudBees University](https://www.cloudbees.com/jenkins/training)
- [Jenkins Certification](https://www.cloudbees.com/jenkins/certification)

---

**Congratulations on completing the Jenkins course!** 🎉

You now have the knowledge and skills to implement robust CI/CD pipelines using Jenkins. Remember to practice regularly and stay updated with the latest Jenkins features and best practices.

Happy building! 🚀