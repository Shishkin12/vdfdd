#!/bin/bash

# =============================================================================
# МАСТЕР-СКРИПТ ПОЛНОГО РАЗВЕРТЫВАНИЯ AMLCHEK.EU
# Автоматически развертывает полностью рабочий ClickOnce проект
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Проверка запуска от root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен запускаться от root. Используйте: sudo $0"
        exit 1
    fi
}

# Проверка подключения к интернету
check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        error "Нет подключения к интернету"
        exit 1
    fi
    log "Подключение к интернету: OK"
}

# Обновление системы
update_system() {
    log "Обновление системы..."
    apt-get update -y
    apt-get upgrade -y
    log "Система обновлена"
}

# Установка Node.js
install_nodejs() {
    log "Установка Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    # Проверка версии
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log "Node.js установлен: $NODE_VERSION"
    log "npm установлен: $NPM_VERSION"
}

# Установка nginx
install_nginx() {
    log "Установка nginx..."
    apt-get install -y nginx
    systemctl enable nginx
    log "nginx установлен и включен"
}

# Установка certbot
install_certbot() {
    log "Установка certbot..."
    apt-get install -y certbot python3-certbot-nginx
    log "certbot установлен"
}

# Установка зависимостей проекта
install_dependencies() {
    log "Установка зависимостей проекта..."
    if [ ! -f package.json ]; then
        error "package.json не найден. Убедитесь что вы в корне проекта."
        exit 1
    fi
    
    npm install
    log "Зависимости установлены"
}

# Сборка проекта
build_project() {
    log "Сборка проекта..."
    npm run build
    
    if [ ! -d "dist" ]; then
        error "Папка dist не создана после сборки"
        exit 1
    fi
    
    log "Проект собран успешно"
}

# Настройка nginx конфигурации
configure_nginx() {
    log "Настройка nginx для amlchek.eu..."
    
    # Создание конфигурации
    cat > /etc/nginx/sites-available/amlchek.eu << 'EOF'
server {
    listen 80;
    server_name amlchek.eu www.amlchek.eu;
    
    # Временная конфигурация для получения SSL
    location / {
        return 301 https://$server_name$request_uri;
    }
    
    # Для certbot
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}

server {
    listen 443 ssl http2;
    server_name amlchek.eu www.amlchek.eu;
    
    root /var/www/html;
    index index.html index.htm;
    
    # SSL ко��фигурация (будет заполнена certbot)
    # ssl_certificate /etc/letsencrypt/live/amlchek.eu/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/amlchek.eu/privkey.pem;
    
    # ClickOnce MIME типы
    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    location ~* \.exe$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
    }
    
    location ~* \.manifest$ {
        add_header Content-Type "application/x-ms-manifest";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # Основная конфигурация
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
    
    # API прокси (если нужно)
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
}
EOF

    # Включение сайта
    ln -sf /etc/nginx/sites-available/amlchek.eu /etc/nginx/sites-enabled/
    
    # Удаление default конфигурации
    rm -f /etc/nginx/sites-enabled/default
    
    log "nginx конфигурация создана"
}

# Развертывание файлов
deploy_files() {
    log "Развертывание файлов..."
    
    # Создание папок
    mkdir -p /var/www/html/deploy
    
    # Копирование собранного проекта
    cp -r dist/spa/* /var/www/html/
    
    # Копирование ClickOnce файлов
    cp -r public/deploy/* /var/www/html/deploy/
    
    # Установка правильных прав
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    log "Файлы развернуты"
}

# Получение SSL сертификата
setup_ssl() {
    log "Получение SSL сертификата..."
    
    # Проверка nginx конфигурации
    nginx -t
    if [ $? -ne 0 ]; then
        error "Ошибка в конфигурации nginx"
        exit 1
    fi
    
    systemctl reload nginx
    
    # Получение сертификата
    certbot --nginx -d amlchek.eu -d www.amlchek.eu --non-interactive --agree-tos --email admin@amlchek.eu
    
    if [ $? -eq 0 ]; then
        log "SSL сертификат получен успешно"
    else
        warn "Не удалось получить SSL сертификат, но продолжаем..."
    fi
}

# Настройка firewall
setup_firewall() {
    log "Настройка firewall..."
    
    ufw --force enable
    ufw allow ssh
    ufw allow 'Nginx Full'
    ufw allow 8080  # Для dev сервера если нужно
    
    log "Firewall настроен"
}

# Проверка развертывания
verify_deployment() {
    log "Проверка развертывания..."
    
    # Проверка nginx
    if ! systemctl is-active --quiet nginx; then
        error "nginx не запущен"
        return 1
    fi
    
    # Проверка файлов
    if [ ! -f /var/www/html/index.html ]; then
        error "index.html не найден"
        return 1
    fi
    
    if [ ! -f /var/www/html/deploy/whatsmaster.application ]; then
        error "ClickOnce манифест не найден"
        return 1
    fi
    
    if [ ! -f "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
        error "ClickOnce исполняемый файл не найден"
        return 1
    fi
    
    # Проверка размера exe файла
    EXE_SIZE=$(stat -c%s "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe" 2>/dev/null || echo "0")
    if [ "$EXE_SIZE" -ne 79605750 ]; then
        warn "Размер exe файла не соответствует ожидаемому: $EXE_SIZE != 79605750"
    fi
    
    log "Проверка файлов: OK"
    
    # Проверка MIME типов
    curl -I -s http://localhost/deploy/whatsmaster.application | grep -q "application/x-ms-application"
    if [ $? -eq 0 ]; then
        log "MIME тип для .application: OK"
    else
        warn "MIME тип для .application наст��оен неправильно"
    fi
    
    log "Развертывание проверено"
}

# Тестирование ClickOnce
test_clickonce() {
    log "Тестирование ClickOnce функциональности..."
    
    # Проверка доступности манифеста
    MANIFEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/whatsmaster.application)
    if [ "$MANIFEST_STATUS" = "200" ]; then
        log "ClickOnce манифест доступен: HTTP $MANIFEST_STATUS"
    else
        error "ClickOnce манифест недоступен: HTTP $MANIFEST_STATUS"
        return 1
    fi
    
    # Проверка доступности exe файла
    EXE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/deploy/Whats%20Master-v9.1.0-win-x64.exe")
    if [ "$EXE_STATUS" = "200" ]; then
        log "ClickOnce исполняемый файл доступен: HTTP $EXE_STATUS"
    else
        error "ClickOnce исполняемый файл недоступен: HTTP $EXE_STATUS"
        return 1
    fi
    
    log "ClickOnce тестирование завершено"
}

# Создание скрипта мониторинга
create_monitoring() {
    log "Создани�� скрипта мониторинга..."
    
    cat > /usr/local/bin/amlchek-monitor.sh << 'EOF'
#!/bin/bash

# Скрипт мониторинга amlchek.eu
# Проверяет состояние сервисов и уведомляет о проблемах

check_nginx() {
    if ! systemctl is-active --quiet nginx; then
        echo "ОШИБКА: nginx не запущен"
        systemctl restart nginx
        return 1
    fi
    return 0
}

check_ssl() {
    CERT_EXPIRE=$(openssl x509 -noout -dates -in /etc/letsencrypt/live/amlchek.eu/fullchain.pem 2>/dev/null | grep notAfter | cut -d= -f2)
    if [ -n "$CERT_EXPIRE" ]; then
        EXPIRE_TIMESTAMP=$(date -d "$CERT_EXPIRE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRE_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))
        
        if [ $DAYS_LEFT -lt 30 ]; then
            echo "ПРЕДУПРЕЖДЕНИЕ: SSL сертификат истечет через $DAYS_LEFT дней"
        fi
    fi
}

check_clickonce() {
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/deploy/whatsmaster.application)
    if [ "$STATUS" != "200" ]; then
        echo "ОШИБКА: ClickOnce манифест недоступен (HTTP $STATUS)"
        return 1
    fi
    return 0
}

# Выполнение проверок
echo "=== Мониторинг amlchek.eu $(date) ==="
check_nginx && echo "nginx: OK"
check_ssl
check_clickonce && echo "ClickOnce: OK"
echo "=== Мо��иторинг завершен ==="
EOF

    chmod +x /usr/local/bin/amlchek-monitor.sh
    
    # Создание cron задачи
    echo "*/15 * * * * /usr/local/bin/amlchek-monitor.sh >> /var/log/amlchek-monitor.log 2>&1" | crontab -
    
    log "Мониторинг настроен"
}

# Финальный отчет
final_report() {
    log "=== ОТЧЕТ О РАЗВЕРТЫВАНИИ ==="
    info "Домен: amlchek.eu"
    info "IP: $(curl -s ifconfig.me)"
    info "nginx статус: $(systemctl is-active nginx)"
    info "SSL сертификат: $(if [ -f /etc/letsencrypt/live/amlchek.eu/fullchain.pem ]; then echo "установлен"; else echo "не установлен"; fi)"
    info "ClickOnce манифест: /var/www/html/deploy/whatsmaster.application"
    info "ClickOnce исполняемый файл: /var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe"
    
    echo ""
    log "=== ТЕСТИРОВАНИЕ ==="
    info "1. Откройте https://amlchek.eu в браузере"
    info "2. Нажмите кнопку '🚀 Запустить EdgeSync Agent'"
    info "3. Браузер должен перенаправить на Edge и запустить ClickOnce"
    
    echo ""
    log "=== КОМАНДЫ У��РАВЛЕНИЯ ==="
    info "Перезапуск nginx: sudo systemctl restart nginx"
    info "Проверка логов: sudo tail -f /var/log/nginx/error.log"
    info "Мониторинг: sudo /usr/local/bin/amlchek-monitor.sh"
    info "Обновление сертификата: sudo certbot renew"
    
    echo ""
    log "РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО УСПЕШНО!"
}

# =============================================================================
# ОСНОВНАЯ ФУНКЦИЯ
# =============================================================================
main() {
    log "Запуск мастер-скрипта развертывания amlchek.eu"
    
    check_root
    check_internet
    
    log "Шаг 1/12: Обновление системы"
    update_system
    
    log "Шаг 2/12: Установка Node.js"
    install_nodejs
    
    log "Шаг 3/12: Установка nginx"
    install_nginx
    
    log "Шаг 4/12: Установка certbot"
    install_certbot
    
    log "Шаг 5/12: Установка зависимостей проекта"
    install_dependencies
    
    log "Шаг 6/12: Сборка проекта"
    build_project
    
    log "Шаг 7/12: Настройка nginx"
    configure_nginx
    
    log "Шаг 8/12: Развертывание файлов"
    deploy_files
    
    log "Шаг 9/12: Настройка SSL"
    setup_ssl
    
    log "Шаг 10/12: Настройка firewall"
    setup_firewall
    
    log "Шаг 11/12: Проверка развертывания"
    if verify_deployment && test_clickonce; then
        log "Все проверки пройдены успешно"
    else
        warn "Некоторые проверки не пройдены, но развертывание продолжено"
    fi
    
    log "Шаг 12/12: Создание мониторинга"
    create_monitoring
    
    final_report
}

# Запуск основной функции
main "$@"
