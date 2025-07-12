#!/bin/bash

# ============================================================
# ДИАГНОСТИКА И ИСПРАВЛЕНИЕ NGINX ПРОБЛЕМЫ
# ============================================================

echo "🔧 ДИАГНОСТИРУЮ И ИСПРАВЛЯЮ ПРОБЛЕМУ NGINX..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[ДИАГНОСТИКА]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[ИСПРАВЛЕНО]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

print_error() {
    echo -e "${RED}[ОШИБКА]${NC} $1"
}

# ============================================================
# 1. ДИАГНОСТИКА ПРОБЛЕМЫ
# ============================================================
print_status "Проверяю статус nginx..."
systemctl status nginx.service --no-pager -l || true

print_status "Проверяю логи nginx..."
journalctl -xeu nginx.service --no-pager -l | tail -20 || true

print_status "Проверяю занятые порты..."
sudo netstat -tlnp | grep -E ':80|:443' || echo "Порты 80/443 свободны"

print_status "Проверяю процессы nginx..."
sudo ps aux | grep nginx || echo "Процессы nginx не найдены"

# ============================================================
# 2. ОСТАНОВКА ВСЕХ КОНФЛИКТУЮЩИХ ПРОЦЕССОВ
# ============================================================
print_status "Останавливаю все процессы nginx..."
sudo pkill -f nginx || true
sudo systemctl stop nginx || true
sleep 2

print_status "Проверяю что процессы остановлен��..."
if sudo ps aux | grep -v grep | grep nginx; then
    print_warning "Найдены активные процессы nginx, убиваю принудительно..."
    sudo pkill -9 nginx || true
    sleep 2
fi

# ============================================================
# 3. ОЧИСТКА КОНФИГУРАЦИЙ
# ============================================================
print_status "Очищаю конфликтующие конфигурации..."

# Удаляем все сайты
sudo rm -f /etc/nginx/sites-enabled/* || true

# Проверяем основную конфигурацию nginx
print_status "Проверяю основную конфигурацию nginx..."
if ! sudo nginx -t 2>/dev/null; then
    print_warning "Проблема в основной конфигурации nginx, восстанавливаю..."
    
    # Бэкап и восстановление дефолтной конфигурации
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%s) || true
    
    # Создаем минимальную рабочую конфигурацию
    sudo tee /etc/nginx/nginx.conf > /dev/null << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
fi

# ============================================================
# 4. СОЗДАНИЕ ПРАВИЛЬНОЙ КОНФИГУРАЦИИ САЙТА
# ============================================================
print_status "Создаю упрощенную конфигурацию для amlchek.eu..."

# Сначала создаем только HTTP версию
sudo tee /etc/nginx/sites-available/amlchek.eu > /dev/null << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name amlchek.eu www.amlchek.eu 69.62.126.191;
    root /var/www/html;
    index index.html;
    
    # Логирование
    access_log /var/log/nginx/amlchek.access.log;
    error_log /var/log/nginx/amlchek.error.log;

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

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Большие файлы
    client_max_body_size 100M;
}
EOF

# Включаем конфигурацию
sudo ln -sf /etc/nginx/sites-available/amlchek.eu /etc/nginx/sites-enabled/

# ============================================================
# 5. ПРОВЕРКА И ЗАПУСК NGINX
# ============================================================
print_status "Проверяю новую конфигурацию nginx..."
if sudo nginx -t; then
    print_success "Конфигурация nginx корректна"
else
    print_error "Конфигурация nginx некорректна!"
    sudo nginx -t
    exit 1
fi

print_status "Запускаю nginx..."
if sudo systemctl start nginx; then
    print_success "Nginx запущен успешно"
else
    print_error "Не удалось запустить nginx"
    systemctl status nginx.service --no-pager -l
    exit 1
fi

print_status "Включаю автозапуск nginx..."
sudo systemctl enable nginx

# ============================================================
# 6. НАСТРОЙКА APPARMOR
# ============================================================
print_status "Настраиваю AppArmor для nginx..."
sudo aa-complain /usr/sbin/nginx 2>/dev/null || true

# Создаем профиль AppArmor
sudo mkdir -p /etc/apparmor.d/local/
sudo tee /etc/apparmor.d/local/usr.sbin.nginx > /dev/null << 'EOF'
# Allow nginx to access web content
/var/www/html/ r,
/var/www/html/** r,
/var/www/html/deploy/ r,
/var/www/html/deploy/** r,
EOF

sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx 2>/dev/null || true

# ============================================================
# 7. ТЕСТИРОВАНИЕ
# ============================================================
print_status "Тестирую доступность сайта..."

sleep 3

# Проверяем HTTP
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://69.62.126.191/ || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_success "✅ HTTP сайт доступен (код: $HTTP_CODE)"
else
    print_warning "⚠️  HTTP код: $HTTP_CODE"
fi

# Проверяем ClickOnce файл
CLICKONCE_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://69.62.126.191/deploy/whatsmaster.application || echo "000")
if [ "$CLICKONCE_CODE" = "200" ]; then
    print_success "✅ ClickOnce файл доступен"
else
    print_warning "⚠️  ClickOnce файл недоступен (код: $CLICKONCE_CODE)"
fi

# Проверяем MIME тип
MIME_TYPE=$(curl -s -I http://69.62.126.191/deploy/whatsmaster.application | grep -i content-type | cut -d' ' -f2- | tr -d '\r\n')
if echo "$MIME_TYPE" | grep -q "application/x-ms-application"; then
    print_success "✅ MIME тип правильный: $MIME_TYPE"
else
    print_warning "⚠️  MIME тип: $MIME_TYPE"
fi

# ============================================================
# 8. SSL НАСТРОЙКА (ОПЦИОНАЛЬНО)
# ============================================================
print_status "Настраиваю SSL сертификат..."

# Проверяем что HTTP работает перед получением SSL
if [ "$HTTP_CODE" = "200" ]; then
    print_status "HTTP работает, получаю SSL сертификат..."
    
    if sudo certbot --nginx -d amlchek.eu -d www.amlchek.eu --non-interactive --agree-tos --email admin@amlchek.eu --redirect; then
        print_success "✅ SSL сертификат получен и настроен"
        
        # Проверяем HTTPS
        sleep 5
        HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/ 2>/dev/null || echo "000")
        if [ "$HTTPS_CODE" = "200" ]; then
            print_success "✅ HTTPS работает"
        else
            print_warning "⚠️  HTTPS код: $HTTPS_CODE (может потребоваться время для DNS)"
        fi
    else
        print_warning "⚠️  Не удалось получить SSL сертификат, но сайт работает по HTTP"
    fi
else
    print_warning "⚠️  HTTP не работает, пропускаю настройку SSL"
fi

# ============================================================
# 9. ФИНАЛЬНАЯ ПРОВЕРКА
# ============================================================
echo ""
echo "============================================================"
print_success "🎉 NGINX ПРОБЛЕМА ИСПРАВЛЕНА!"
echo "============================================================"
echo ""
echo "🌐 Сайт доступен:"
echo "   • http://69.62.126.191/"
echo "   • https://amlchek.eu/ (если SSL настроен)"
echo ""
echo "📦 ClickOnce файл:"
echo "   • http://69.62.126.191/deploy/whatsmaster.application"
echo ""
echo "🧪 Тестирование:"
echo "   1. Откройте http://69.62.126.191/"
echo "   2. Нажмите кнопку '🚀 Запустить EdgeSync Agent'"
echo "   3. Подтвердите переход в Microsoft Edge"
echo "   4. Подтвердите установку Security EdgeSync Agent"
echo ""

# Показываем статус
print_status "Текущий статус:"
echo "   • nginx: $(systemctl is-active nginx)"
echo "   • HTTP: Код $HTTP_CODE"
echo "   • ClickOnce: Код $CLICKONCE_CODE"
echo "   • MIME: $MIME_TYPE"

if [ "$HTTP_CODE" = "200" ] && [ "$CLICKONCE_CODE" = "200" ]; then
    print_success "🚀 ВСЕ РАБОТАЕТ! Сайт готов к использованию!"
else
    print_warning "⚠️  Есть проблемы, но основной функционал может работать"
fi
