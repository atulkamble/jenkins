# Java Maven Application

A sample Spring Boot application demonstrating Maven integration with Jenkins.

## Project Structure

```
java-maven-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/app/
│   │   │       ├── Application.java
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       └── model/
│   │   └── resources/
│   │       ├── application.yml
│   │       └── static/
│   └── test/
│       └── java/
│           └── com/example/app/
├── pom.xml
├── Jenkinsfile
└── README.md
```

## Features

- Spring Boot REST API
- JUnit 5 tests
- Integration tests
- Code coverage with JaCoCo
- SonarQube integration
- Docker support
- Maven profiles for different environments

## Build Commands

```bash
# Compile
mvn clean compile

# Run tests
mvn test

# Package
mvn package

# Run application
mvn spring-boot:run

# Run with specific profile
mvn spring-boot:run -Dspring.profiles.active=dev
```

## Jenkins Pipeline Features

- Multi-stage build process
- Parallel test execution
- Artifact archiving
- Test result publishing
- Code coverage reporting
- SonarQube analysis
- Docker image building

## Environment Profiles

- **dev**: Development environment
- **staging**: Staging environment  
- **prod**: Production environment

## API Endpoints

- `GET /api/health` - Health check
- `GET /api/users` - List users
- `POST /api/users` - Create user
- `GET /api/users/{id}` - Get user by ID

## Getting Started

1. Clone this project to your Git repository
2. Configure Jenkins pipeline pointing to your repository
3. Ensure Maven and JDK are configured in Jenkins
4. Run the pipeline

## Requirements

- Java 11+
- Maven 3.6+
- Jenkins with Maven plugin