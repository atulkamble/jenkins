# Use official Jenkins LTS image as base
FROM jenkins/jenkins:lts

# Switch to root user to install additional packages
USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install Maven
RUN wget https://archive.apache.org/dist/maven/maven-3/3.9.4/binaries/apache-maven-3.9.4-bin.tar.gz \
    && tar xzf apache-maven-3.9.4-bin.tar.gz -C /opt \
    && ln -s /opt/apache-maven-3.9.4 /opt/maven \
    && rm apache-maven-3.9.4-bin.tar.gz

# Set Maven environment variables
ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Switch back to jenkins user
USER jenkins

# Install Jenkins plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy custom configuration files
COPY --chown=jenkins:jenkins configs/ /usr/share/jenkins/ref/

# Set environment variables
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV JENKINS_USER=admin
ENV JENKINS_PASS=admin123

# Expose ports
EXPOSE 8080 50000