#!/bin/bash

# Jenkins Installation Script for Ubuntu/Debian
# Run with: sudo bash install-jenkins-ubuntu.sh

set -e

echo "🚀 Installing Jenkins on Ubuntu/Debian..."

# Update system packages
echo "📦 Updating system packages..."
apt-get update

# Install Java (OpenJDK 11)
echo "☕ Installing Java..."
apt-get install -y openjdk-11-jdk

# Verify Java installation
java_version=$(java -version 2>&1 | head -n 1)
echo "✅ Java installed: $java_version"

# Add Jenkins repository
echo "📋 Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list
apt-get update

# Install Jenkins
echo "🔧 Installing Jenkins..."
apt-get install -y jenkins

# Start and enable Jenkins service
echo "🚀 Starting Jenkins service..."
systemctl start jenkins
systemctl enable jenkins

# Check Jenkins status
echo "📊 Jenkins service status:"
systemctl status jenkins --no-pager

# Get initial admin password
echo ""
echo "🔑 Jenkins initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""

# Display access information
echo "✅ Jenkins installation completed!"
echo "🌐 Access Jenkins at: http://localhost:8080"
echo "🔑 Use the password above for initial setup"
echo ""
echo "📝 Next steps:"
echo "1. Open browser and navigate to http://localhost:8080"
echo "2. Enter the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create your first admin user"
echo "5. Start using Jenkins!"