# Jenkins Docker Setup

This directory contains Docker configurations for running Jenkins in different scenarios.

## Quick Start with Docker

### Basic Jenkins Container

```bash
# Run Jenkins LTS with persistent data
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

### Jenkins with Docker Support

```bash
# Run Jenkins with Docker socket mounted (for Docker builds)
docker run -d \
  --name jenkins-docker \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  jenkins/jenkins:lts
```

### Using Docker Compose

Use the provided `docker-compose.yml` file:

```bash
# Start Jenkins stack
docker-compose up -d

# View logs
docker-compose logs -f

# Stop Jenkins stack
docker-compose down
```

## Getting Initial Password

```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Useful Docker Commands

```bash
# View running containers
docker ps

# Access Jenkins container shell
docker exec -it jenkins bash

# View Jenkins logs
docker logs jenkins

# Backup Jenkins data
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar czf /backup/jenkins-backup.tar.gz -C /data .

# Restore Jenkins data
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar xzf /backup/jenkins-backup.tar.gz -C /data
```

## Custom Jenkins Image

See `Dockerfile` for creating a custom Jenkins image with pre-installed plugins and configurations.

## Network Configuration

If you need Jenkins to communicate with other containers:

```bash
# Create custom network
docker network create jenkins-network

# Run Jenkins on custom network
docker run -d \
  --name jenkins \
  --network jenkins-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```