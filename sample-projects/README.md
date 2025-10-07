# Sample Projects for Jenkins Course

This directory contains sample projects that demonstrate various Jenkins integration scenarios covered in the course modules.

## Project Structure

```
sample-projects/
├── java-maven-app/          # Maven-based Java application
├── java-gradle-app/         # Gradle-based Java application  
├── nodejs-express-app/      # Node.js Express application
├── python-flask-app/        # Python Flask application
├── multi-language-app/      # Mixed technology stack
├── docker-app/              # Dockerized application
└── microservices/           # Microservices architecture example
```

## How to Use These Projects

1. **Copy to your Git repository**: Each project can be copied to its own Git repository for pipeline testing
2. **Modify Jenkinsfiles**: Adapt the provided Jenkinsfiles to your specific needs
3. **Follow the modules**: Each project corresponds to specific course modules
4. **Practice exercises**: Use these as starting points for hands-on exercises

## Project Descriptions

### Java Maven App
- **Purpose**: Demonstrates Maven integration with Jenkins
- **Module**: Module 5 - Build Tools Integration
- **Features**: Unit tests, integration tests, code coverage, artifact publishing
- **Technologies**: Java 11, Maven, JUnit, Spring Boot

### Java Gradle App  
- **Purpose**: Shows Gradle build automation
- **Module**: Module 5 - Build Tools Integration
- **Features**: Multi-module build, static analysis, test reporting
- **Technologies**: Java 11, Gradle, Spring Boot, JUnit

### Node.js Express App
- **Purpose**: Node.js application CI/CD pipeline
- **Module**: Module 5 - Build Tools Integration
- **Features**: npm scripts, testing, linting, security audit
- **Technologies**: Node.js, Express, Jest, ESLint

### Python Flask App
- **Purpose**: Python application pipeline
- **Module**: Module 5 - Build Tools Integration
- **Features**: pip requirements, pytest, code quality, Docker
- **Technologies**: Python 3.9, Flask, pytest, black

### Multi-language App
- **Purpose**: Demonstrates handling multiple technologies
- **Module**: Module 5 - Build Tools Integration
- **Features**: Frontend (React), Backend (Spring Boot), Database migrations
- **Technologies**: React, Java, Maven, Docker Compose

### Docker App
- **Purpose**: Container-based application deployment
- **Module**: Module 5 - Build Tools Integration, Module 7 - Deployment
- **Features**: Multi-stage builds, container testing, registry publishing
- **Technologies**: Docker, Docker Compose

### Microservices
- **Purpose**: Complex multi-service application
- **Module**: Module 7 - Deployment, Module 10 - Advanced
- **Features**: Service orchestration, integration testing, deployment strategies
- **Technologies**: Spring Boot, Docker, Kubernetes

## Getting Started

1. Choose a sample project that matches your learning goals
2. Copy the project to your own Git repository
3. Configure Jenkins to point to your repository
4. Follow the corresponding module instructions
5. Experiment and modify as needed

## Prerequisites

- Git repository (GitHub, GitLab, etc.)
- Jenkins instance with appropriate plugins
- Required tools installed (Java, Node.js, Python, Docker)

## Support

Each project includes:
- README with setup instructions
- Jenkinsfile with detailed comments
- Sample configuration files
- Common troubleshooting tips

Happy learning! 🚀