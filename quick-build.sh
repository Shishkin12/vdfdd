#!/bin/bash

# Quick build and test script

echo "🔨 Building project for production..."

# Update manifest for server IP
sed -i 's|https://ehamsterswap.online|http://69.62.126.191|g' public/deploy/whatsmaster.application
sed -i 's|http://localhost:8080|http://69.62.126.191|g' public/deploy/whatsmaster.application

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Build project
echo "🏗️ Building project..."
npm run build

if [ -d "dist/spa" ]; then
    echo "✅ Build successful!"
    echo "📁 Files ready in dist/spa/"
    echo ""
    echo "📋 Next steps:"
    echo "1. Upload dist/spa/* to your server at /var/www/html/"
    echo "2. Or run the full deploy.sh script on the server"
    echo ""
    echo "🌐 Files will be available at: http://69.62.126.191"
else
    echo "❌ Build failed!"
    exit 1
fi
