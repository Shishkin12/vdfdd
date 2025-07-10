# 🚀 Deployment Instructions

## Автоматическая установка на сервер 69.62.126.191

### 1. Подключитесь к серверу и загрузите проект:

```bash
# Подключение к серверу
ssh root@69.62.126.191

# Клонирование проекта (если еще не загружен)
git clone <your-repo-url> whatsmaster-app
cd whatsmaster-app

# Или загрузите файлы через SCP/FTP
```

### 2. Запустите скрипт автоматической установки:

```bash
# Сделать скрипт исполняемым
chmod +x deploy.sh

# Запустить установку
sudo ./deploy.sh
```

### 3. Что делает скрипт:

✅ **Обновляет систему** - `apt update && apt upgrade`  
✅ **Устанавливает зависимости** - nginx, nodejs, npm  
✅ **Устанавливает Node.js 18+** - если нужно  
✅ **Устанавливает npm пакеты** - `npm install`  
✅ **Обновляет конфигурацию** - меняет URLs на ваш IP  
✅ **Собирает проект** - `npm run build`  
✅ **Настраивает Nginx** - с правильными MIME типами для ClickOnce  
✅ **Копирует файлы** - в `/var/www/html`  
✅ **Запускает веб-сервер** - nginx  
✅ **Настраивает файрволл** - открывает порты 80, 443  
✅ **Проверяет работу** - тестирует доступность сайта

### 4. После успешной установки:

🌐 **Сайт доступен по адресу:** `http://69.62.126.191`  
📦 **ClickOnce файл:** `http://69.62.126.191/deploy/whatsmaster.application`

### 5. Тестирование:

1. Откройте `http://69.62.126.191` в браузере
2. Нажмите кнопку "🚀 Запустить приложение"
3. Подтвердите переход в Microsoft Edge
4. Подтвердите установку ClickOnce приложения

### 6. Управление сервером:

```bash
# Перезапуск Nginx
sudo systemctl restart nginx

# Просмотр логов
sudo tail -f /var/log/nginx/error.log

# Проверка статуса
sudo systemctl status nginx

# Обновление сайта (повторный запуск)
sudo ./deploy.sh
```

### 7. Устранение проблем:

**Если сайт недоступен:**

```bash
sudo systemctl status nginx
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

**Если ClickOnce не работает:**

```bash
curl -I http://69.62.126.191/deploy/whatsmaster.application
# Должен вернуть: Content-Type: application/x-ms-application
```

**Если файлы не найдены:**

```bash
ls -la /var/www/html/deploy/
# Должны быть: whatsmaster.application и Whats Master-v9.1.0-win-x64.exe
```

---

## 🔧 Ручная установка (если скрипт не работает):

```bash
# 1. Установка пакетов
sudo apt update && sudo apt install -y nginx nodejs npm

# 2. Установка зависимостей проекта
npm install

# 3. Сборка проекта
npm run build

# 4. Копирование файлов
sudo cp -r dist/spa/* /var/www/html/

# 5. Настройка Nginx (скопировать конфигурацию из deploy.sh)
sudo nano /etc/nginx/sites-available/default

# 6. Перезапуск Nginx
sudo systemctl restart nginx
```

---

**📞 В случае проблем - проверьте логи и убедитесь что все файлы скопированы правильно!**
