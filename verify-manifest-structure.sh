#!/bin/bash

# =============================================================================
# ПРОВЕРКА СТРУКТУРЫ CLICKONCE МАНИФЕСТОВ
# Проверяет правильность структуры Deployment и Application манифестов
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

test_pass() { echo -e "${GREEN}✓ PASS${NC}: $1"; ((PASS++)); }
test_fail() { echo -e "${RED}✗ FAIL${NC}: $1"; ((FAIL++)); }

header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
}

header "ПРОВЕРКА СТРУКТУРЫ CLICKONCE МАНИФЕСТОВ"

# 1. Проверка Deployment манифеста (.application)
echo -e "\n${YELLOW}1. Проверка Deployment манифеста (.application)${NC}"

DEPLOYMENT_FILE="public/deploy/whatsmaster.application"

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    test_fail "Deployment манифест не найден: $DEPLOYMENT_FILE"
else
    test_pass "Deployment манифест найден"
    
    # Проверка начала файла
    if grep -q '^<deployment xmlns="urn:schemas-microsoft-com:clickonce:deployment"' "$DEPLOYMENT_FILE"; then
        test_pass "Правильная структура: начинается с <deployment>"
    else
        test_fail "Неправильная структура: НЕ начинается с <deployment>"
        echo "  Текущее начало:"
        head -3 "$DEPLOYMENT_FILE" | sed 's/^/    /'
        echo "  Должно быть:"
        echo '    <deployment xmlns="urn:schemas-microsoft-com:clickonce:deployment" manifestVersion="1.0">'
    fi
    
    # Проверка окончания файла
    if grep -q '</deployment>$' "$DEPLOYMENT_FILE"; then
        test_pass "Правильное окончание: </deployment>"
    else
        test_fail "Неправильное окончание: НЕ заканчивается на </deployment>"
    fi
    
    # Проверка обязательных элементов
    if grep -q '<assemblyIdentity' "$DEPLOYMENT_FILE"; then
        test_pass "assemblyIdentity присутствует"
    else
        test_fail "assemblyIdentity отсутствует"
    fi
    
    if grep -q '<deploymentProvider codebase="https://amlchek.eu' "$DEPLOYMENT_FILE"; then
        test_pass "deploymentProvider с правильным codebase"
    else
        test_fail "deploymentProvider отсутству��т или неправильный"
    fi
    
    if grep -q '<dependency>' "$DEPLOYMENT_FILE"; then
        test_pass "dependency секция присутствует"
    else
        test_fail "dependency секция отсутствует"
    fi
fi

# 2. Проверка Application манифеста (.manifest)
echo -e "\n${YELLOW}2. Проверка Application манифеста (.manifest)${NC}"

APPLICATION_FILE="public/deploy/EdgeSyncAgent.application.manifest"

if [ ! -f "$APPLICATION_FILE" ]; then
    test_fail "Application манифест не найден: $APPLICATION_FILE"
    echo "  Это файл описывает структуру самого приложения"
else
    test_pass "Application манифест найден"
    
    # Проверка начала файла
    if grep -q '^<asmv1:assembly' "$APPLICATION_FILE"; then
        test_pass "Правильная структура: начинается с <asmv1:assembly>"
    else
        test_fail "Неправильная структура: НЕ начинается с <asmv1:assembly>"
    fi
    
    # Проверка обязательных элементов
    if grep -q '<entryPoint>' "$APPLICATION_FILE"; then
        test_pass "entryPoint присутствует"
    else
        test_fail "entryPoint отсутствует"
    fi
    
    if grep -q '<trustInfo>' "$APPLICATION_FILE"; then
        test_pass "trustInfo присутствует"
    else
        test_fail "trustInfo отсутствует (может потребоваться для безопасности)"
    fi
    
    # Проверка ссылки на EXE файл
    if grep -q 'Whats Master-v9.1.0-win-x64.exe' "$APPLICATION_FILE"; then
        test_pass "Ссылка на EXE файл найдена"
    else
        test_fail "Ссылка на EXE файл отсутствует"
    fi
fi

# 3. Проверка EXE файла
echo -e "\n${YELLOW}3. Проверка EXE файла${NC}"

EXE_FILE="public/deploy/Whats Master-v9.1.0-win-x64.exe"

if [ ! -f "$EXE_FILE" ]; then
    test_fail "EXE файл не найден: $EXE_FILE"
else
    test_pass "EXE файл найден"
    
    # Проверка размера
    EXE_SIZE=$(stat -c%s "$EXE_FILE" 2>/dev/null || echo "0")
    if [ "$EXE_SIZE" -eq 79605750 ]; then
        test_pass "Размер EXE файла корректен: $EXE_SIZE байт"
    else
        test_fail "Размер EXE файла неправильный: $EXE_SIZE (ожидается: 79605750)"
    fi
    
    # Проверка что это исполняемый файл
    if command -v file &> /dev/null; then
        FILE_TYPE=$(file "$EXE_FILE" 2>/dev/null || echo "unknown")
        if [[ "$FILE_TYPE" == *"PE32"* ]] || [[ "$FILE_TYPE" == *"executable"* ]]; then
            test_pass "Тип файла: Windows исполняемый"
        else
            test_fail "Файл не является Windows исполняемым: $FILE_TYPE"
        fi
    fi
fi

# 4. Проверка соответствия размеров в манифестах
echo -e "\n${YELLOW}4. Проверка соответствия размеров${NC}"

if [ -f "$DEPLOYMENT_FILE" ] && [ -f "$APPLICATION_FILE" ]; then
    # Размер Application манифеста в Deployment манифесте
    MANIFEST_SIZE_IN_DEPLOYMENT=$(grep 'codebase="EdgeSyncAgent.application.manifest"' "$DEPLOYMENT_FILE" | sed -n 's/.*size="\([0-9]*\)".*/\1/p')
    ACTUAL_MANIFEST_SIZE=$(stat -c%s "$APPLICATION_FILE" 2>/dev/null || echo "0")
    
    if [ "$MANIFEST_SIZE_IN_DEPLOYMENT" = "$ACTUAL_MANIFEST_SIZE" ]; then
        test_pass "Размер Application манифеста соответствует: $ACTUAL_MANIFEST_SIZE байт"
    else
        test_fail "Размер Application манифеста НЕ соответствует: указано $MANIFEST_SIZE_IN_DEPLOYMENT, фактически $ACTUAL_MANIFEST_SIZE"
    fi
fi

if [ -f "$APPLICATION_FILE" ] && [ -f "$EXE_FILE" ]; then
    # Размер EXE файла в Application манифесте
    EXE_SIZE_IN_MANIFEST=$(grep 'Whats Master-v9.1.0-win-x64.exe' "$APPLICATION_FILE" | sed -n 's/.*size="\([0-9]*\)".*/\1/p')
    ACTUAL_EXE_SIZE=$(stat -c%s "$EXE_FILE" 2>/dev/null || echo "0")
    
    if [ "$EXE_SIZE_IN_MANIFEST" = "$ACTUAL_EXE_SIZE" ]; then
        test_pass "Размер EXE файла соответствует: $ACTUAL_EXE_SIZE байт"
    else
        test_fail "Размер EXE файла НЕ соответствует: указано $EXE_SIZE_IN_MANIFEST, фактически $ACTUAL_EXE_SIZE"
    fi
fi

# 5. Проверка XML валидности
echo -e "\n${YELLOW}5. Проверка XML валидности${NC}"

if command -v xmllint &> /dev/null; then
    if [ -f "$DEPLOYMENT_FILE" ]; then
        if xmllint --noout "$DEPLOYMENT_FILE" 2>/dev/null; then
            test_pass "Deployment манифест XML валиден"
        else
            test_fail "Deployment манифест XML НЕ валиден"
            echo "  Ош��бки XML:"
            xmllint --noout "$DEPLOYMENT_FILE" 2>&1 | head -3 | sed 's/^/    /'
        fi
    fi
    
    if [ -f "$APPLICATION_FILE" ]; then
        if xmllint --noout "$APPLICATION_FILE" 2>/dev/null; then
            test_pass "Application манифест XML валиден"
        else
            test_fail "Application манифест XML НЕ валиден"
            echo "  Ошибки XML:"
            xmllint --noout "$APPLICATION_FILE" 2>&1 | head -3 | sed 's/^/    /'
        fi
    fi
else
    echo "  xmllint не установлен, пропускаем проверку XML"
fi

# 6. Проверка структуры файлов
echo -e "\n${YELLOW}6. Структура файлов ClickOnce${NC}"

echo "  Текущая структура:"
if [ -d "public/deploy" ]; then
    ls -la "public/deploy/" | sed 's/^/    /'
else
    echo "    Папка public/deploy/ не найдена"
fi

echo ""
echo "  Правильная структура должна быть:"
echo "    whatsmaster.application          - Deployment манифест (главный)"
echo "    EdgeSyncAgent.application.manifest - Application манифест"
echo "    Whats Master-v9.1.0-win-x64.exe  - Исполняемый файл"

# Финальный отчет
header "РЕЗУЛЬТАТ ПРОВЕРКИ"

TOTAL=$((PASS + FAIL))
if [ $TOTAL -gt 0 ]; then
    SUCCESS_RATE=$((PASS * 100 / TOTAL))
else
    SUCCESS_RATE=0
fi

echo -e "${GREEN}✓ Пройдено: $PASS${NC}"
echo -e "${RED}✗ Ошибок: $FAIL${NC}"
echo -e "${BLUE}Успешность: $SUCCESS_RATE%${NC}"

echo ""
if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ!${NC}"
    echo -e "${GREEN}Структура ClickOnce манифестов полностью корректна.${NC}"
    echo -e "${GREEN}Edge НЕ будет выдавать ошибки парсинга манифеста.${NC}"
    
    echo -e "\n${BLUE}Следующие шаги:${NC}"
    echo -e "  1. Запустите развертывание: ${YELLOW}sudo bash deploy-one-click.sh${NC}"
    echo -e "  2. Убедитесь что MIME типы настроены в nginx"
    echo -e "  3. Протестируйте на Windows устройстве"
    
    exit 0
else
    echo -e "${RED}❌ ОБНАРУЖЕНЫ ОШИБКИ!${NC}"
    echo -e "${RED}Исправьте ошибки перед развертыванием.${NC}"
    
    echo -e "\n${YELLOW}Рекомендации по исправлению:${NC}"
    echo -e "  • Убедитесь что Deployment манифест начинается с <deployment>"
    echo -e "  • Проверьте размеры файлов в манифестах"
    echo -e "  • Исправьте XML ошибки если есть"
    echo -e "  • Запустите: ${YELLOW}bash fix-clickonce-structure.sh${NC}"
    
    exit 1
fi
