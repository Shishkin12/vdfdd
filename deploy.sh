#!/bin/bash

# ============================================================
# Deployment script for WhatsApp ClickOnce Application
# Server IP: 69.62.126.191
# ============================================================

set -e  # Exit on any error

echo "🚀 Starting deployment to 69.62.126.191..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Server configuration
SERVER_IP="69.62.126.191"
DOMAIN="$SERVER_IP"
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
# 1. System Update and Dependencies
# ============================================================
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

print_status "Installing basic packages..."
sudo apt install -y nginx git curl wget

# Fix Node.js and npm conflicts
print_status "Fixing Node.js and npm installation..."

# Remove conflicting packages
sudo apt remove -y npm || true
sudo apt autoremove -y

# Check if Node.js is already installed
if command -v node > /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    print_status "Found Node.js version: $NODE_VERSION"

    if [ "$NODE_VERSION" -lt 18 ]; then
        print_status "Node.js version is too old, installing latest..."
        # Remove old Node.js
        sudo apt remove -y nodejs || true
        # Install Node.js 20 from nodesource (includes npm)
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        print_status "Node.js version is adequate"
        # Make sure npm is available (it comes with Node.js from nodesource)
        if ! command -v npm > /dev/null; then
            print_status "npm not found, reinstalling Node.js..."
            sudo apt remove -y nodejs || true
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
    fi
else
    print_status "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Verify installation
print_status "Verifying Node.js and npm installation..."
node --version
npm --version

print_success "Node.js and npm are ready"

# ============================================================
# 2. Install Project Dependencies
# ============================================================
print_status "Installing project dependencies..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
    print_error "package.json not found! Make sure you're in the project directory."
    exit 1
fi

# Install dependencies
npm install

print_success "Dependencies installed"

# ============================================================
# 3. Update Configuration for Server IP
# ============================================================
print_status "Updating configuration for server IP..."

# Update ClickOnce manifest
sed -i "s|https://ehamsterswap.online|http://$SERVER_IP|g" public/deploy/whatsmaster.application
sed -i "s|http://localhost:8080|http://$SERVER_IP|g" public/deploy/whatsmaster.application

print_success "Configuration updated for $SERVER_IP"

# ============================================================
# 4. Build Project
# ============================================================
print_status "Building project..."

# Clean previous build
rm -rf dist/

# Build the project
npm run build

if [ ! -d "dist/spa" ]; then
    print_error "Build failed! dist/spa directory not found."
    exit 1
fi

print_success "Project built successfully"

# ============================================================
# 5. Setup Web Directory
# ============================================================
print_status "Setting up web directory..."

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

print_success "Web files deployed"

# ============================================================
# 6. Configure Nginx
# ============================================================
print_status "Configuring Nginx..."

# Create Nginx configuration
sudo tee $NGINX_CONF > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_IP;
    root $WEB_ROOT;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # ClickOnce MIME types
    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        
        # Allow cross-origin requests for ClickOnce
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    }

    location ~* \.exe$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        
        # Allow cross-origin requests
        add_header Access-Control-Allow-Origin "*";
    }

    # Handle large file uploads (for the EXE file)
    client_max_body_size 100M;

    # SPA routing - must be last
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Optional: Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Test Nginx configuration
sudo nginx -t

if [ $? -eq 0 ]; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration is invalid!"
    exit 1
fi

# ============================================================
# 7. Start Services
# ============================================================
print_status "Starting services..."

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl restart nginx

# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    print_success "Nginx is running"
else
    print_error "Failed to start Nginx"
    exit 1
fi

# ============================================================
# 8. Setup Firewall (if UFW is available)
# ============================================================
if command -v ufw > /dev/null; then
    print_status "Configuring firewall..."
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    print_success "Firewall configured"
fi

# ============================================================
# 9. Verification
# ============================================================
print_status "Verifying deployment..."

# Check if website is accessible
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)

if [ "$HTTP_CODE" = "200" ]; then
    print_success "Website is accessible locally"
else
    print_warning "Website returned HTTP code: $HTTP_CODE"
fi

# Check if deploy files exist
if [ -f "$WEB_ROOT/deploy/whatsmaster.application" ] && [ -f "$WEB_ROOT/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
    print_success "ClickOnce files are deployed"
else
    print_warning "ClickOnce files may be missing"
fi

# ============================================================
# 10. Final Instructions
# ============================================================
echo ""
echo "============================================================"
print_success "🎉 DEPLOYMENT COMPLETED!"
echo "============================================================"
echo ""
print_status "Your website is now available at:"
echo "  🌐 http://$SERVER_IP"
echo ""
print_status "ClickOnce application endpoint:"
echo "  📦 http://$SERVER_IP/deploy/whatsmaster.application"
echo ""
print_status "To test the ClickOnce functionality:"
echo "  1. Open http://$SERVER_IP in a browser"
echo "  2. Click the '🚀 Запустить приложение' button"
echo "  3. Choose to open with Microsoft Edge"
echo "  4. Confirm the ClickOnce installation"
echo ""
print_status "Useful commands:"
echo "  - Check Nginx status: sudo systemctl status nginx"
echo "  - View Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "  - Restart Nginx: sudo systemctl restart nginx"
echo ""

# Optional: Show current status
print_status "Current service status:"
sudo systemctl status nginx --no-pager -l

echo ""
print_success "Deployment script completed successfully! 🚀"
