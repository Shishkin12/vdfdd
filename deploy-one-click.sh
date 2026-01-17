#!/bin/bash

# =============================================================================
# СКРИПТ "ОДНОЙ КНОПКИ" - ПОЛНОЕ РАЗВЕРТЫВАНИЕ AMLCHEK.EU
# Запустите этот скрипт на чистом Ubuntu/Debian сервере для полного развертывания
# =============================================================================

set -e

# ASCII арт заголовок
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════���═══════╗
║                    AMLCHEK.EU CLICKONCE DEPLOYER                     ║
║                    Security EdgeSync Agent v9.1.0                   ║
║                                                                       ║
║  🚀 Автоматическое развертывание полнофункционального                ║
║     ClickOnce приложения на домене amlchek.eu                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции логирования
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✓ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}"; }
error() { echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ✗ $1${NC}"; }
info() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ $1${NC}"; }
header() { echo -e "\n${PURPLE}╔═════════════════════════════════���════════════╗${NC}"; echo -e "${PURPLE}║  $1${NC}"; echo -e "${PURPLE}╚══════════════════════════════════════════════╝${NC}"; }

# Проверка root прав
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Запустите от root: sudo $0"
        exit 1
    fi
}

# Интерактивные вопросы
interactive_setup() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════╗"
    echo "║                        ПАРАМЕТРЫ РАЗВЕРТЫВАНИЯ                        ║"
    echo "╚═══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    read -p "Email для SSL сертификата (по умолчанию: admin@amlchek.eu): " SSL_EMAIL
    SSL_EMAIL=${SSL_EMAIL:-admin@amlchek.eu}
    
    read -p "Пропустить получение SSL сертификата? (y/N): " SKIP_SSL
    SKIP_SSL=${SKIP_SSL:-N}
    
    read -p "Установить мониторинг? (Y/n): " INSTALL_MONITORING
    INSTALL_MONITORING=${INSTALL_MONITORING:-Y}
    
    echo -e "\n${GREEN}Параметры установки:${NC}"
    echo "  Домен: amlchek.eu"
    echo "  Email SSL: $SSL_EMAIL"
    echo "  Пропустить SSL: $SKIP_SSL"
    echo "  Мониторинг: $INSTALL_MONITORING"
    echo ""
    
    read -p "Продолжить? (Y/n): " CONFIRM
    if [[ $CONFIRM =~ ^[Nn]$ ]]; then
        echo "Отменено пользователем"
        exit 0
    fi
}

# Прогресс бар
show_progress() {
    local current=$1
    local total=$2
    local desc="$3"
    local percentage=$((current * 100 / total))
    local completed=$((current * 50 / total))
    
    printf "\r${BLUE}[${NC}"
    for i in $(seq 1 $completed); do printf "█"; done
    for i in $(seq $((completed + 1)) 50); do printf "░"; done
    printf "${BLUE}] %d%% - %s${NC}" $percentage "$desc"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Основная функция развертывания
deploy_system() {
    local step=0
    local total_steps=15
    
    header "ШАГ $((++step))/$total_steps: ПРОВЕРКА СИСТЕМЫ"
    show_progress $step $total_steps "Проверка интернета и системы"
    
    # Проверка интернета
    if ! ping -c 1 google.com &> /dev/null; then
        error "Нет подключения к интернету"
        exit 1
    fi
    
    # Получение информации о системе
    OS_INFO=$(lsb_release -d | cut -f2 || echo "Unknown OS")
    CURRENT_IP=$(curl -s ifconfig.me || echo "Unknown IP")
    
    info "ОС: $OS_INFO"
    info "Внешний IP: $CURRENT_IP"
    log "Система проверена"
    
    header "ШАГ $((++step))/$total_steps: ОБНОВЛЕНИЕ СИСТЕМЫ"
    show_progress $step $total_steps "Обновление пакетов системы"
    
    apt-get update -qq
    apt-get upgrade -y -qq
    apt-get install -y -qq curl wget unzip git
    log "Система обновлена"
    
    header "ШАГ $((++step))/$total_steps: УСТАНОВКА NODE.JS"
    show_progress $step $total_steps "Установка Node.js и npm"
    
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &> /dev/null
        apt-get install -y -qq nodejs
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log "Node.js $NODE_VERSION и npm $NPM_VERSION установлены"
    
    header "ШАГ $((++step))/$total_steps: УСТАНОВКА WEB-СЕРВЕРА"
    show_progress $step $total_steps "Установка nginx и настройка"
    
    apt-get install -y -qq nginx
    systemctl enable nginx &> /dev/null
    systemctl start nginx &> /dev/null
    log "nginx установлен и запущен"
    
    header "ШАГ $((++step))/$total_steps: УСТАНОВКА SSL ИНСТРУМЕНТОВ"
    show_progress $step $total_steps "Установка certbot для SSL"
    
    if [[ $SKIP_SSL != [Yy] ]]; then
        apt-get install -y -qq certbot python3-certbot-nginx
        log "certbot установлен"
    else
        warn "SSL инструменты пропущены"
    fi
    
    header "ШАГ $((++step))/$total_steps: ПОДГОТОВКА ПРОЕКТА"
    show_progress $step $total_steps "Проверка файлов проекта"
    
    if [ ! -f package.json ]; then
        error "package.json не найден. Запустите скрипт из папки проекта."
        exit 1
    fi
    
    # Проверка обяза��ельных файлов
    REQUIRED_FILES=(
        "client/pages/Index.tsx"
        "index.html"
        "public/deploy/whatsmaster.application"
        "public/deploy/Whats Master-v9.1.0-win-x64.exe"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            error "Обязательный файл не найден: $file"
            exit 1
        fi
    done
    
    log "Все файлы проекта найдены"
    
    header "ШАГ $((++step))/$total_steps: УСТАНОВКА ЗАВИСИМОСТЕЙ"
    show_progress $step $total_steps "npm install"
    
    npm install --silent
    log "Зависимости установлены"
    
    header "ШАГ $((++step))/$total_steps: СБОРКА ПРОЕКТА"
    show_progress $step $total_steps "npm run build"
    
    npm run build --silent
    
    if [ ! -d "dist" ] || [ ! -f "dist/spa/index.html" ]; then
        error "Сборка проекта не удалась"
        exit 1
    fi
    
    log "Проект собран успешно"
    
    header "ШАГ $((++step))/$total_steps: НАСТРОЙКА NGINX"
    show_progress $step $total_steps "Создание конфигурации nginx"
    
    # Создани�� nginx конфигурации
    cat > /etc/nginx/sites-available/amlchek.eu << 'NGINXCONF'
server {
    listen 80;
    server_name amlchek.eu www.amlchek.eu;
    
    # Редирект на HTTPS
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
    index index.html;
    
    # SSL заглушки (будут заменены certbot)
    ssl_certificate /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
    
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
    
    # Основные файлы
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
    
    # Безопасность
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Логирование
    access_log /var/log/nginx/amlchek.eu.access.log;
    error_log /var/log/nginx/amlchek.eu.error.log;
}
NGINXCONF
    
    # Включение сайта
    ln -sf /etc/nginx/sites-available/amlchek.eu /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Проверка конфигурации
    if ! nginx -t &> /dev/null; then
        error "Ошибка в конфигурации nginx"
        exit 1
    fi
    
    log "nginx сконфигурирован"
    
    header "ШАГ $((++step))/$total_steps: РАЗВЕРТЫВАНИЕ ФАЙЛОВ"
    show_progress $step $total_steps "Копирование файлов на сервер"
    
    # Создание папок
    mkdir -p /var/www/html/deploy
    
    # Очистка старых ф��йлов
    rm -rf /var/www/html/*
    
    # Копирование файлов
    cp -r dist/spa/* /var/www/html/
    cp -r public/deploy/* /var/www/html/deploy/
    
    # Установка прав
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    
    # Проверка размера EXE файла
    EXE_PATH="/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe"
    if [ -f "$EXE_PATH" ]; then
        EXE_SIZE=$(stat -c%s "$EXE_PATH")
        if [ "$EXE_SIZE" -eq 79605750 ]; then
            log "EXE файл развернут (размер: $EXE_SIZE байт)"
        else
            warn "Размер EXE файла не соответствует ожидаемому: $EXE_SIZE != 79605750"
        fi
    else
        error "EXE файл не найден после развертывания"
        exit 1
    fi
    
    log "Файлы развернуты"
    
    header "ШАГ $((++step))/$total_steps: ПЕРЕЗАПУСК NGINX"
    show_progress $step $total_steps "Применение конфигурации"
    
    systemctl reload nginx
    log "nginx перезапущен"
    
    header "ШАГ $((++step))/$total_steps: НАСТРОЙКА SSL"
    show_progress $step $total_steps "Получени�� SSL сертификата"
    
    if [[ $SKIP_SSL != [Yy] ]]; then
        # Попытка получить SSL сертификат
        if certbot --nginx -d amlchek.eu -d www.amlchek.eu --non-interactive --agree-tos --email "$SSL_EMAIL" &> /dev/null; then
            log "SSL сертификат получен успешно"
        else
            warn "Не удалось получить SSL сертификат (возможно, DNS не настроен)"
            info "Сайт доступен по HTTP: http://amlchek.eu"
        fi
    else
        warn "SSL настройка пропущена"
    fi
    
    header "ШАГ $((++step))/$total_steps: НАСТРОЙКА FIREWALL"
    show_progress $step $total_steps "Конфигурация UFW"
    
    # Настройка firewall
    ufw --force enable &> /dev/null
    ufw allow ssh &> /dev/null
    ufw allow 'Nginx Full' &> /dev/null
    
    log "Firewall настроен"
    
    header "ШАГ $((++step))/$total_steps: ТЕСТИРОВАНИЕ СИСТЕМЫ"
    show_progress $step $total_steps "Проверка всех компонентов"
    
    # Проверка nginx
    if ! systemctl is-active --quiet nginx; then
        error "nginx не запущен"
        exit 1
    fi
    
    # Проверка файлов
    if [ ! -f /var/www/html/index.html ]; then
        error "index.html не найден на сервере"
        exit 1
    fi
    
    if [ ! -f /var/www/html/deploy/whatsmaster.application ]; then
        error "ClickOnce манифест не найден на сервере"
        exit 1
    fi
    
    # Проверка HTTP доступности
    sleep 2
    SITE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ || echo "000")
    if [[ "$SITE_STATUS" =~ ^(200|301|302)$ ]]; then
        log "Сайт отвечает (HTTP $SITE_STATUS)"
    else
        warn "Сайт не отвечает правильно (HTTP $SITE_STATUS)"
    fi
    
    # Проверка ClickOnce манифеста
    MANIFEST_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/whatsmaster.application || echo "000")
    if [ "$MANIFEST_STATUS" = "200" ]; then
        log "ClickOnce манифест доступен"
    else
        error "ClickOnce манифест недоступен (HTTP $MANIFEST_STATUS)"
    fi
    
    # Проверка MIME типа
    MIME_TYPE=$(curl -s -I http://localhost/deploy/whatsmaster.application 2>/dev/null | grep -i content-type | cut -d: -f2 | tr -d ' \r\n' || echo "unknown")
    if [[ "$MIME_TYPE" == *"application/x-ms-application"* ]]; then
        log "MIME тип манифеста корректен"
    else
        warn "MIME тип манифеста может быть неправильным: $MIME_TYPE"
    fi
    
    log "Тестирование завершено"
    
    if [[ $INSTALL_MONITORING == [Yy] ]]; then
        header "ШАГ $((++step))/$total_steps: УСТАНОВКА МОНИТОРИНГА"
        show_progress $step $total_steps "Настройка автоматического мониторинга"
        
        # Создание скрипта мониторинга
        cat > /usr/local/bin/amlchek-monitor.sh << 'MONITOR'
#!/bin/bash
echo "=== Мониторинг amlchek.eu $(date) ==="

# Проверка nginx
if systemctl is-active --quiet nginx; then
    echo "✓ nginx: работает"
else
    echo "✗ nginx: не работает"
    systemctl restart nginx
fi

# Проверка ClickOnce
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/whatsmaster.application)
if [ "$STATUS" = "200" ]; then
    echo "✓ ClickOnce: доступен"
else
    echo "✗ ClickOnce: недоступен (HTTP $STATUS)"
fi

# Проверка дискового пространства
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠ Диск заполнен на $DISK_USAGE%"
else
    echo "✓ Диск: $DISK_USAGE% использовано"
fi

echo "=== Мониторинг завершен ==="
MONITOR
        
        chmod +x /usr/local/bin/amlchek-monitor.sh
        
        # Создание cron задачи
        echo "*/30 * * * * /usr/local/bin/amlchek-monitor.sh >> /var/log/amlchek-monitor.log 2>&1" | crontab -
        
        log "Мониторинг установлен (проверка каждые 30 минут)"
    else
        show_progress $((++step)) $total_steps "Мониторинг пропущен"
    fi
    
    header "РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО"
    show_progress $total_steps $total_steps "Система готова к работе"
}

# Финальный отчет
show_final_report() {
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                          РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО                         ║${NC}"
    echo -e "${GREEN}╚═════════════════════════════════��════════════════════════════════════════╝${NC}"
    
    echo -e "\n${CYAN}📊 ИНФОРМАЦИЯ О СИСТЕМЕ:${NC}"
    echo -e "   🌐 Домен: ${YELLOW}amlchek.eu${NC}"
    echo -e "   🔗 IP адрес: ${YELLOW}$(curl -s ifconfig.me 2>/dev/null || echo 'неизвестен')${NC}"
    echo -e "   🔧 nginx: ${GREEN}$(systemctl is-active nginx)${NC}"
    echo -e "   📱 Приложение: ${YELLOW}Security EdgeSync Agent v9.1.0${NC}"
    echo -e "   📁 Размер EXE: ${YELLOW}$(stat -c%s '/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe' 2>/dev/null | numfmt --to=iec || echo 'неизвестен')${NC}"
    
    echo -e "\n${CYAN}🔗 ССЫЛКИ ДЛЯ ТЕСТИРОВАНИЯ:${NC}"
    
    # Определение протокола
    if [ -f /etc/letsencrypt/live/amlchek.eu/fullchain.pem ]; then
        PROTOCOL="https"
        echo -e "   🔒 Основной сайт: ${GREEN}https://amlchek.eu${NC}"
        echo -e "   🔒 ClickOnce манифест: ${GREEN}https://amlchek.eu/deploy/whatsmaster.application${NC}"
    else
        PROTOCOL="http"
        echo -e "   🌐 Основной сайт: ${YELLOW}http://amlchek.eu${NC}"
        echo -e "   ��� ClickOnce манифест: ${YELLOW}http://amlchek.eu/deploy/whatsmaster.application${NC}"
    fi
    
    echo -e "   🔧 Локальное тестирование: ${BLUE}http://localhost${NC}"
    
    echo -e "\n${CYAN}🧪 ИНСТРУКЦИИ ПО ТЕСТИРОВАНИЮ:${NC}"
    echo -e "   1. Откройте ${YELLOW}$PROTOCOL://amlchek.eu${NC} в любом браузере"
    echo -e "   2. Найдите кнопку ${GREEN}'🚀 Запустить EdgeSync Agent'${NC}"
    echo -e "   3. Нажмите на кнопку"
    echo -e "   4. Браузер должен переключиться на Microsoft Edge"
    echo -e "   5. ClickOnce должен автоматически запустить установку приложения"
    
    echo -e "\n${CYAN}⚙️  КОМАНДЫ УПРАВЛЕНИЯ:${NC}"
    echo -e "   • Перезапуск nginx: ${BLUE}sudo systemctl restart nginx${NC}"
    echo -e "   • Логи nginx: ${BLUE}sudo tail -f /var/log/nginx/amlchek.eu.error.log${NC}"
    echo -e "   • Проверка мониторинга: ${BLUE}sudo /usr/local/bin/amlchek-monitor.sh${NC}"
    echo -e "   • Обновление SSL: ${BLUE}sudo certbot renew${NC}"
    echo -e "   • Логи мониторинга: ${BLUE}sudo tail -f /var/log/amlchek-monitor.log${NC}"
    
    echo -e "\n${CYAN}🚨 ДИАГНОСТИКА ПРОБЛЕМ:${NC}"
    echo -e "   • Быстрое исправление: ${BLUE}./quick-fix-clickonce.sh${NC}"
    echo -e "   • Полная проверка: ${BLUE}./test-complete-system.sh${NC}"
    echo -e "   • Статус служб: ${BLUE}systemctl status nginx${NC}"
    
    echo -e "\n${GREEN}🎉 ПОЗДРАВЛЯЕМ!${NC}"
    echo -e "${GREEN}Система Security EdgeSync Agent полностью развернута и готова к использованию!${NC}"
    
    # Финальная проверка
    echo -e "\n${BLUE}Выполняется финальная проверка...${NC}"
    sleep 2
    
    FINAL_CHECK=0
    
    # Проверка nginx
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✓${NC} nginx работает"
        ((FINAL_CHECK++))
    else
        echo -e "${RED}✗${NC} nginx не работает"
    fi
    
    # Проверка файлов
    if [ -f "/var/www/html/deploy/whatsmaster.application" ]; then
        echo -e "${GREEN}✓${NC} ClickOnce манифест найден"
        ((FINAL_CHECK++))
    else
        echo -e "${RED}✗${NC} ClickOnce манифест не найден"
    fi
    
    # Проверка HTTP
    if curl -s --connect-timeout 3 http://localhost/ &>/dev/null; then
        echo -e "${GREEN}✓${NC} HTTP сервер отвечает"
        ((FINAL_CHECK++))
    else
        echo -e "${RED}✗${NC} HTTP сервер не отвечает"
    fi
    
    if [ $FINAL_CHECK -eq 3 ]; then
        echo -e "\n${GREEN}🌟 ВСЕ СИСТЕМЫ РАБОТАЮТ ИДЕАЛЬНО! 🌟${NC}"
    elif [ $FINAL_CHECK -eq 2 ]; then
        echo -e "\n${YELLOW}⚠️  Система работает, но требует внимания${NC}"
    else
        echo -e "\n${RED}❌ Обнаружены критические проблемы${NC}"
    fi
}

# =============================================================================
# ГЛАВНАЯ ФУНКЦИЯ
# =============================================================================
main() {
    # Проверка запуска
    check_root
    
    # Интерактивная настройка
    interactive_setup
    
    # Основное развертывание
    deploy_system
    
    # Финальный отчет
    show_final_report
}

# Запуск
main "$@"
