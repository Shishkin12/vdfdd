#!/bin/bash

# ============================================================
# Fix npm installation conflicts
# ============================================================

echo "🔧 Fixing npm installation conflicts..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Method 1: Clean removal and reinstall
print_status "Method 1: Clean removal and reinstall..."

# Remove all Node.js and npm packages
sudo apt remove --purge -y nodejs npm
sudo apt autoremove -y
sudo apt autoclean

# Remove any leftover files
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node*
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*

# Install Node.js 20 with npm from nodesource
print_status "Installing Node.js 20 from nodesource..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
if command -v node > /dev/null && command -v npm > /dev/null; then
    print_success "Node.js and npm installed successfully!"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    exit 0
fi

# Method 2: Use snap if Method 1 failed
print_status "Method 1 failed, trying Method 2: Snap installation..."

# Install Node.js via snap
sudo snap install node --classic

if command -v node > /dev/null && command -v npm > /dev/null; then
    print_success "Node.js and npm installed via snap!"
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    exit 0
fi

# Method 3: Manual npm installation
print_status "Method 2 failed, trying Method 3: Manual npm installation..."

# Since Node.js is working, try to install npm manually
if command -v node > /dev/null; then
    # Download and install npm manually
    cd /tmp
    curl -L https://www.npmjs.com/install.sh | sh
    
    # Add npm to PATH if needed
    export PATH="/usr/local/bin:$PATH"
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    
    if command -v npm > /dev/null; then
        print_success "npm installed manually!"
        echo "npm version: $(npm --version)"
        exit 0
    fi
fi

# Method 4: Use yarn as alternative
print_status "All npm methods failed, installing yarn as alternative..."

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install -y yarn

if command -v yarn > /dev/null; then
    print_success "Yarn installed as npm alternative!"
    echo "Yarn version: $(yarn --version)"
    echo ""
    echo "You can use 'yarn' instead of 'npm' for the following commands:"
    echo "  yarn install  (instead of npm install)"
    echo "  yarn run build  (instead of npm run build)"
    exit 0
fi

print_error "All installation methods failed!"
print_status "Manual steps to try:"
echo "1. wget https://nodejs.org/dist/v20.18.0/node-v20.18.0-linux-x64.tar.xz"
echo "2. tar -xf node-v20.18.0-linux-x64.tar.xz"
echo "3. sudo cp -r node-v20.18.0-linux-x64/* /usr/local/"
echo "4. source ~/.bashrc"

exit 1
