#!/bin/bash

# =============================================================================
# БЫСТРОЕ ИСПРАВЛЕНИЕ CLICKONCE
# Исправляет основные проблемы ClickOnce без полного переразвертывания
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] $1${NC}"; }

fix_manifest() {
    log "Исправление ClickOnce манифеста..."
    
    # Проверка существования файла
    if [ ! -f "public/deploy/whatsmaster.application" ]; then
        error "Манифест не найден: public/deploy/whatsmaster.application"
        exit 1
    fi
    
    # Копирование исправленного манифеста на сервер
    if [ -d "/var/www/html" ]; then
        sudo cp public/deploy/whatsmaster.application /var/www/html/deploy/
        sudo chown www-data:www-data /var/www/html/deploy/whatsmaster.application
        log "Манифест скопирован на сервер"
    fi
}

fix_nginx_mime() {
    log "Исправление MIME типов в nginx..."
    
    # Проверка существования конфигурации
    if [ ! -f "/etc/nginx/sites-available/amlchek.eu" ]; then
        warn "nginx конфигурация не найдена, создаем минимальную..."
        
        sudo tee /etc/nginx/sites-available/amlchek.eu > /dev/null << 'EOF'
server {
    listen 80;
    listen 443 ssl http2;
    server_name amlchek.eu www.amlchek.eu;
    
    root /var/www/html;
    index index.html;
    
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
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
        
        sudo ln -sf /etc/nginx/sites-available/amlchek.eu /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default
    fi
    
    # Проверка и перезапуск nginx
    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "nginx перезагружен"
    else
        error "Ошибка в конфигурации nginx"
        exit 1
    fi
}

rebuild_and_deploy() {
    log "Пересборка и развертывание..."
    
    # ��борка проекта
    npm run build
    
    # Развертывание
    if [ -d "/var/www/html" ]; then
        sudo cp -r dist/spa/* /var/www/html/
        sudo cp -r public/deploy/* /var/www/html/deploy/
        sudo chown -R www-data:www-data /var/www/html
        log "Файлы развернуты"
    else
        warn "Папка /var/www/html не существует, копируем в текущую папку"
        mkdir -p deployment
        cp -r dist/spa/* deployment/
        cp -r public/deploy/* deployment/deploy/
        log "Файлы скопированы в папку deployment/"
    fi
}

test_clickonce() {
    log "Тестирование ClickOnce..."
    
    # Локальная проверка
    if [ -f "/var/www/html/deploy/whatsmaster.application" ]; then
        log "Локальный манифест найден"
    else
        error "Локальный манифест не найден"
        return 1
    fi
    
    # Проверка через HTTP
    MANIFEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/whatsmaster.application 2>/dev/null || echo "000")
    if [ "$MANIFEST_STATUS" = "200" ]; then
        log "HTTP тест манифеста: OK ($MANIFEST_STATUS)"
    else
        warn "HTTP тест манифеста: FAILED ($MANIFEST_STATUS)"
    fi
    
    # Проверка MIME типа
    MIME_TYPE=$(curl -s -I http://localhost/deploy/whatsmaster.application 2>/dev/null | grep -i content-type | cut -d: -f2 | tr -d ' \r\n' || echo "unknown")
    if [[ "$MIME_TYPE" == *"application/x-ms-application"* ]]; then
        log "MIME тип: OK ($MIME_TYPE)"
    else
        warn "MIME тип: НЕПРАВИЛЬНЫЙ ($MIME_TYPE)"
    fi
    
    # Проверка exe файла
    if [ -f "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
        EXE_SIZE=$(stat -c%s "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe")
        log "EXE файл найден, размер: $EXE_SIZE байт"
    else
        error "EXE файл не найден"
        return 1
    fi
}

show_status() {
    log "=== СТАТУС СИСТЕМЫ ==="
    echo "nginx: $(systemctl is-active nginx 2>/dev/null || echo 'не установлен')"
    echo "Манифест: $([ -f '/var/www/html/deploy/whatsmaster.application' ] && echo 'найден' || echo 'не найден')"
    echo "EXE файл: $([ -f '/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe' ] && echo 'найден' || echo 'не найден')"
    echo "Д��мен: amlchek.eu"
    echo "Текущий IP: $(curl -s ifconfig.me 2>/dev/null || echo 'неизвестен')"
    
    echo ""
    log "=== ССЫЛКИ ДЛЯ ТЕСТИРОВАНИЯ ==="
    echo "Сайт: https://amlchek.eu"
    echo "Манифест: https://amlchek.eu/deploy/whatsmaster.application"
    echo "Локальное тестирование: http://localhost/deploy/whatsmaster.application"
}

main() {
    log "Быстрое исправление ClickOnce для amlchek.eu"
    
    # Проверка что мы в правильной папке
    if [ ! -f "package.json" ]; then
        error "Запустите скрипт из корня проекта (где находится package.json)"
        exit 1
    fi
    
    log "Шаг 1/5: Исправление манифеста"
    fix_manifest
    
    log "Шаг 2/5: Исправление nginx MIME типов"
    fix_nginx_mime
    
    log "Шаг 3/5: Пересборка и развертывание"
    rebuild_and_deploy
    
    log "Шаг 4/5: Тестирование ClickOnce"
    test_clickonce
    
    log "Шаг 5/5: Показ статуса"
    show_status
    
    echo ""
    log "БЫСТРОЕ ИСПРАВЛЕНИЕ ЗАВЕРШЕНО!"
    log "Теперь откройте https://amlchek.eu и нажмите кнопку '🚀 Запустить EdgeSync Agent'"
}

main "$@"
