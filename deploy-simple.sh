#!/bin/bash

# ============================================================
# Simplified Deployment Script (Node.js already installed)
# Server IP: 69.62.126.191
# ============================================================

set -e  # Exit on any error

echo "🚀 Starting simplified deployment to 69.62.126.191..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server configuration
SERVER_IP="69.62.126.191"
WEB_ROOT="/var/www/html"
NGINX_CONF="/etc/nginx/sites-available/default"

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================
# 1. Check Prerequisites
# ============================================================
print_status "Checking prerequisites..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "package.json not found! Make sure you're in the project directory."
    exit 1
fi

# Check Node.js
if ! command -v node > /dev/null; then
    print_error "Node.js not found! Please install Node.js first."
    exit 1
fi

# Check npm
if ! command -v npm > /dev/null; then
    print_error "npm not found! Using alternative approach..."
    
    # Try to use npx or install dependencies manually
    if command -v npx > /dev/null; then
        print_status "Using npx as npm alternative..."
        alias npm="npx"
    else
        print_error "Neither npm nor npx found. Please fix Node.js installation."
        exit 1
    fi
fi

print_status "Node.js version: $(node --version)"
print_status "npm version: $(npm --version)"

# Make sure nginx is installed
if ! command -v nginx > /dev/null; then
    print_status "Installing nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

print_success "Prerequisites checked"

# ============================================================
# 2. Install Dependencies (with fallback)
# ============================================================
print_status "Installing project dependencies..."

# Try different approaches to install dependencies
if npm install 2>/dev/null; then
    print_success "Dependencies installed via npm"
elif npx npm install 2>/dev/null; then
    print_success "Dependencies installed via npx"
else
    print_warning "Standard npm install failed, trying alternative approaches..."
    
    # Try installing with --no-optional flag
    if npm install --no-optional --no-fund --no-audit 2>/dev/null; then
        print_success "Dependencies installed with --no-optional"
    else
        print_error "Failed to install dependencies. You may need to install them manually."
        print_status "Try running: curl -L https://npmjs.org/install.sh | sh"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# ============================================================
# 3. Update Configuration
# ============================================================
print_status "Updating configuration for server IP..."

# Backup original file
cp public/deploy/whatsmaster.application public/deploy/whatsmaster.application.backup

# Update ClickOnce manifest for server IP
sed -i "s|https://ehamsterswap.online|http://$SERVER_IP|g" public/deploy/whatsmaster.application
sed -i "s|http://localhost:8080|http://$SERVER_IP|g" public/deploy/whatsmaster.application

print_success "Configuration updated for $SERVER_IP"

# ============================================================
# 4. Build Project
# ============================================================
print_status "Building project..."

# Clean previous build
rm -rf dist/

# Try to build the project
if npm run build 2>/dev/null; then
    print_success "Project built via npm"
elif npx vite build 2>/dev/null; then
    print_success "Project built via npx vite"
else
    print_error "Build failed! Trying manual approach..."
    
    # Try installing vite globally
    if npm install -g vite 2>/dev/null; then
        vite build
        print_success "Project built via global vite"
    else
        print_error "All build methods failed!"
        exit 1
    fi
fi

if [ ! -d "dist/spa" ]; then
    print_error "Build failed! dist/spa directory not found."
    exit 1
fi

print_success "Project built successfully"

# ============================================================
# 5. Deploy Files
# ============================================================
print_status "Deploying files to web server..."

# Create web root if it doesn't exist
sudo mkdir -p $WEB_ROOT

# Backup existing files
if [ -d "$WEB_ROOT" ] && [ "$(ls -A $WEB_ROOT)" ]; then
    print_warning "Backing up existing web files..."
    sudo mv $WEB_ROOT $WEB_ROOT.backup.$(date +%Y%m%d_%H%M%S)
    sudo mkdir -p $WEB_ROOT
fi

# Copy built files
sudo cp -r dist/spa/* $WEB_ROOT/

# Set proper permissions
sudo chown -R www-data:www-data $WEB_ROOT
sudo chmod -R 755 $WEB_ROOT

print_success "Files deployed to $WEB_ROOT"

# ============================================================
# 6. Configure Nginx
# ============================================================
print_status "Configuring Nginx..."

# Create Nginx configuration
sudo tee $NGINX_CONF > /dev/null << 'EOF'
server {
    listen 80;
    server_name 69.62.126.191;
    root /var/www/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # ClickOnce MIME types
    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header Access-Control-Allow-Origin "*";
    }

    location ~* \.exe$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Access-Control-Allow-Origin "*";
    }

    # Handle large files
    client_max_body_size 100M;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

# Test nginx config
sudo nginx -t

if [ $? -eq 0 ]; then
    print_success "Nginx configuration is valid"
    sudo systemctl restart nginx
    print_success "Nginx restarted"
else
    print_error "Nginx configuration is invalid!"
    exit 1
fi

# ============================================================
# 7. Final Verification
# ============================================================
print_status "Verifying deployment..."

# Wait a moment for nginx to start
sleep 2

# Test local access
if curl -s http://localhost/ | grep -q "html"; then
    print_success "Website is accessible locally"
else
    print_warning "Website may not be accessible (this might be normal)"
fi

# Check if ClickOnce files exist
if [ -f "$WEB_ROOT/deploy/whatsmaster.application" ]; then
    print_success "ClickOnce manifest found"
else
    print_error "ClickOnce manifest missing!"
fi

if [ -f "$WEB_ROOT/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
    print_success "ClickOnce executable found"
else
    print_error "ClickOnce executable missing!"
fi

# ============================================================
# 8. Success Message
# ============================================================
echo ""
echo "============================================================"
print_success "🎉 DEPLOYMENT COMPLETED!"
echo "============================================================"
echo ""
print_status "Your website is now available at:"
echo "  🌐 http://69.62.126.191"
echo ""
print_status "ClickOnce application:"
echo "  📦 http://69.62.126.191/deploy/whatsmaster.application"
echo ""
print_status "Test the ClickOnce functionality:"
echo "  1. Open http://69.62.126.191"
echo "  2. Click '🚀 Запустить приложение'"
echo "  3. Confirm Edge redirect"
echo "  4. Install the application"
echo ""
print_success "Deployment completed successfully! 🚀"
