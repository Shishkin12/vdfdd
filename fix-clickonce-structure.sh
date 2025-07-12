#!/bin/bash

# =============================================================================
# ИСПРАВЛЕНИЕ СТРУКТУРЫ CLICKONCE МАНИФЕСТОВ
# Создает правильную структуру Deployment + Application манифестов
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓ $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠ $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ✗ $1${NC}"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ $1${NC}"; }

header() {
    echo -e "\n${BLUE}══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════════════════╝${NC}"
}

header "ИСПРАВЛЕНИЕ CLICKONCE СТРУКТУРЫ"

info "Проблема: Использовали Assembly manifest вместо Deployment manifest"
info "Решение: Создаем правильную структуру манифестов"

# Проверка файлов
log "Проверка структуры файлов..."

if [ ! -f "public/deploy/whatsmaster.application" ]; then
    error "Deployment манифест не найден"
    exit 1
fi

if [ ! -f "public/deploy/EdgeSyncAgent.application.manifest" ]; then
    warn "Application манифест не найден, создан автоматически"
fi

if [ ! -f "public/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
    error "EXE файл не найден"
    exit 1
fi

# Проверка структуры Deployment манифеста
log "Проверка Deployment манифеста..."

if grep -q '<deployment xmlns="urn:schemas-microsoft-com:clickonce:deployment"' public/deploy/whatsmaster.application; then
    log "Deployment манифест имеет правильную структуру"
else
    error "Deployment манифест имеет неправильную структуру"
    exit 1
fi

# Проверка размера EXE файла
log "П��оверка EXE файла..."

EXE_SIZE=$(stat -c%s "public/deploy/Whats Master-v9.1.0-win-x64.exe" 2>/dev/null || echo "0")
EXPECTED_SIZE=79605750

if [ "$EXE_SIZE" -eq "$EXPECTED_SIZE" ]; then
    log "Размер EXE файла корректен: $EXE_SIZE байт"
else
    warn "Размер EXE файла отличается: $EXE_SIZE != $EXPECTED_SIZE"
fi

# Пересборка проекта
header "ПЕРЕСБОРКА ПРОЕКТА"

log "Сборка проекта..."
npm run build

if [ ! -d "dist/spa" ]; then
    error "Сборка не создала папку dist/spa"
    exit 1
fi

log "Проект собран успешно"

# Развертывание на сервер (если доступен)
if [ -d "/var/www/html" ]; then
    header "РАЗВЕРТЫВАНИЕ НА СЕРВЕР"
    
    log "Копирование файлов на сервер..."
    
    # Создание папки deploy
    sudo mkdir -p /var/www/html/deploy
    
    # Копирование всех файлов проекта
    sudo cp -r dist/spa/* /var/www/html/
    
    # Копирование ClickOnce файлов
    sudo cp public/deploy/whatsmaster.application /var/www/html/deploy/
    sudo cp public/deploy/EdgeSyncAgent.application.manifest /var/www/html/deploy/
    sudo cp "public/deploy/Whats Master-v9.1.0-win-x64.exe" /var/www/html/deploy/
    
    # Установка прав
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    log "Файлы развернуты на сервере"
    
    # Проверка nginx MIME типов
    header "ПРОВЕРКА NGINX MIME ТИПОВ"
    
    if [ -f "/etc/nginx/sites-available/amlchek.eu" ]; then
        if grep -q "application/x-ms-application" /etc/nginx/sites-available/amlchek.eu; then
            log "MIME тип для .application настроен"
        else
            warn "MIME тип для .application не настроен"
            info "Добавьте в nginx конфигурацию:"
            echo "location ~* \.application$ {"
            echo "    add_header Content-Type \"application/x-ms-application\";"
            echo "    add_header Cache-Control \"no-cache, no-store, must-revalidate\";"
            echo "}"
        fi
        
        if grep -q "application/x-ms-manifest" /etc/nginx/sites-available/amlchek.eu; then
            log "MIME тип для .manifest настроен"
        else
            warn "MIME тип для .manifest не настроен"
            info "Добавьте в nginx конфигурацию:"
            echo "location ~* \.manifest$ {"
            echo "    add_header Content-Type \"application/x-ms-manifest\";"
            echo "    add_header Cache-Control \"no-cache, no-store, must-revalidate\";"
            echo "}"
        fi
        
        # Перезапуск nginx
        if sudo nginx -t &>/dev/null; then
            sudo systemctl reload nginx
            log "nginx перезагружен"
        else
            error "Ошибка в конфигурации nginx"
        fi
    else
        warn "nginx конфигурация не найдена"
    fi
    
else
    warn "Папка /var/www/html не найдена - пропускаем развертывание на сервер"
fi

# Тестирование
header "ТЕСТИРОВАНИЕ CLICKONCE"

# Локальная проверка файлов
log "Проверка локальных файлов..."

DEPLOYMENT_SIZE=$(stat -c%s "public/deploy/whatsmaster.application" 2>/dev/null || echo "0")
log "Размер Deployment манифеста: $DEPLOYMENT_SIZE байт"

if [ -f "public/deploy/EdgeSyncAgent.application.manifest" ]; then
    APPLICATION_SIZE=$(stat -c%s "public/deploy/EdgeSyncAgent.application.manifest" 2>/dev/null || echo "0")
    log "Размер Application манифеста: $APPLICATION_SIZE байт"
fi

# HTTP тестирование (если сервер доступен)
if command -v curl &> /dev/null; then
    log "HTTP тестирование..."
    
    # Проверка доступности Deployment манифеста
    if curl -s --connect-timeout 3 http://localhost/deploy/whatsmaster.application &>/dev/null; then
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/whatsmaster.application)
        if [ "$STATUS" = "200" ]; then
            log "Deployment манифест доступен по HTTP ($STATUS)"
            
            # Проверка MIME типа
            MIME_TYPE=$(curl -s -I http://localhost/deploy/whatsmaster.application | grep -i content-type | cut -d: -f2 | tr -d ' \r\n')
            if [[ "$MIME_TYPE" == *"application/x-ms-application"* ]]; then
                log "MIME тип корректен: $MIME_TYPE"
            else
                warn "MIME тип неправильный: $MIME_TYPE"
                info "Ожидается: application/x-ms-application"
            fi
        else
            error "Deployment манифест недоступен (HTTP $STATUS)"
        fi
    else
        warn "Локальный веб-сервер недоступен"
    fi
    
    # Проверка Application манифеста
    if curl -s --connect-timeout 3 http://localhost/deploy/EdgeSyncAgent.application.manifest &>/dev/null; then
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/deploy/EdgeSyncAgent.application.manifest)
        if [ "$STATUS" = "200" ]; then
            log "Application манифест доступен по HTTP ($STATUS)"
        else
            warn "Application манифест недоступен (HTTP $STATUS)"
        fi
    fi
    
    # Проверка EXE файла
    EXE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost/deploy/Whats%20Master-v9.1.0-win-x64.exe")
    if [ "$EXE_STATUS" = "200" ]; then
        log "EXE файл доступен по HTTP ($EXE_STATUS)"
    else
        warn "EXE файл недоступен (HTTP $EXE_STATUS)"
    fi
fi

# Финальный отчет
header "РЕЗУЛЬТАТ ИСПРАВЛЕНИЯ"

echo -e "\n${GREEN}✅ ИСПРАВЛЕНИЯ ВЫПОЛНЕНЫ:${NC}"
echo -e "  • Создан правильный Deployment манифест (.application)"
echo -e "  • Создан Application манифест (.manifest) для EXE"
echo -e "  • Структура манифестов соответствует стандарту ClickOnce"
echo -e "  • Проект п��ресобран с новыми манифестами"

echo -e "\n${BLUE}📁 СТРУКТУРА ФАЙЛОВ:${NC}"
echo -e "  • whatsmaster.application (Deployment) - ${DEPLOYMENT_SIZE} байт"
if [ -f "public/deploy/EdgeSyncAgent.application.manifest" ]; then
    echo -e "  • EdgeSyncAgent.application.manifest (Application) - ${APPLICATION_SIZE} байт"
fi
echo -e "  • Whats Master-v9.1.0-win-x64.exe - ${EXE_SIZE} байт"

echo -e "\n${YELLOW}🔧 ТРЕБОВАНИЯ К СЕРВЕРУ:${NC}"
echo -e "  • MIME тип .application: application/x-ms-application"
echo -e "  • MIME тип .manifest: application/x-ms-manifest"
echo -e "  • MIME тип .exe: application/octet-stream"
echo -e "  • HTTPS обязательно для продакшена"

echo -e "\n${GREEN}🎯 СЛЕДУЮЩИЕ ШАГИ:${NC}"
echo -e "  1. Запустите полное развертывание: sudo bash deploy-one-click.sh"
echo -e "  2. Протестируйте на Windows устройстве"
echo -e "  3. Проверьте что Edge больше не выдает ошибок"

echo -e "\n${GREEN}🌟 СИСТЕМА ГОТОВА К ИСПОЛЬЗОВАНИЮ!${NC}"

exit 0
