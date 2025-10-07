#!/bin/bash

# Jenkins Installation Script for macOS
# Run with: bash install-jenkins-macos.sh

set -e

echo "🚀 Installing Jenkins on macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew found"
fi

# Update Homebrew
echo "📦 Updating Homebrew..."
brew update

# Install Java if not present
if ! command -v java &> /dev/null; then
    echo "☕ Installing Java..."
    brew install openjdk@11
    # Add Java to PATH
    echo 'export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"' >> ~/.zshrc
    export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"
else
    echo "✅ Java already installed"
fi

# Verify Java installation
java_version=$(java -version 2>&1 | head -n 1)
echo "☕ Java version: $java_version"

# Install Jenkins LTS
echo "🔧 Installing Jenkins LTS..."
brew install jenkins-lts

# Start Jenkins service
echo "🚀 Starting Jenkins service..."
brew services start jenkins-lts

# Wait a moment for Jenkins to start
echo "⏳ Waiting for Jenkins to start..."
sleep 10

# Get initial admin password
echo ""
echo "🔑 Jenkins initial admin password:"
if [ -f "/opt/homebrew/var/lib/jenkins/secrets/initialAdminPassword" ]; then
    cat /opt/homebrew/var/lib/jenkins/secrets/initialAdminPassword
elif [ -f "/usr/local/var/lib/jenkins/secrets/initialAdminPassword" ]; then
    cat /usr/local/var/lib/jenkins/secrets/initialAdminPassword
else
    echo "⚠️  Password file not found. Jenkins might still be starting..."
    echo "Check for the password file in:"
    echo "- /opt/homebrew/var/lib/jenkins/secrets/initialAdminPassword"
    echo "- /usr/local/var/lib/jenkins/secrets/initialAdminPassword"
fi

echo ""

# Display access information
echo "✅ Jenkins installation completed!"
echo "🌐 Access Jenkins at: http://localhost:8080"
echo ""
echo "📝 Commands for managing Jenkins:"
echo "  Start:   brew services start jenkins-lts"
echo "  Stop:    brew services stop jenkins-lts"
echo "  Restart: brew services restart jenkins-lts"
echo "  Status:  brew services list | grep jenkins"
echo ""
echo "📝 Next steps:"
echo "1. Open browser and navigate to http://localhost:8080"
echo "2. Enter the initial admin password shown above"
echo "3. Install suggested plugins"
echo "4. Create your first admin user"
echo "5. Start using Jenkins!"