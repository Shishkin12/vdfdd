# 🔧 Исправление конфликтов npm

У вас конфликт между Node.js и npm. Вот несколько способов решения:

## ⚡ Быстрое решение №1 - Используйте упрощенный скрипт:

```bash
chmod +x deploy-simple.sh
sudo ./deploy-simple.sh
```

Этот скрипт обработает конфликты автоматически.

## 🛠️ Решение №2 - Исправьте npm вручную:

```bash
# Запустите скрипт исправления
chmod +x fix-npm.sh
sudo ./fix-npm.sh
```

## 🔄 Решение №3 - Полная переустановка Node.js:

```bash
# 1. Удалите все конфликтующие пакеты
sudo apt remove --purge -y nodejs npm
sudo apt autoremove -y

# 2. Установите Node.js 20 заново
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Проверьте установку
node --version
npm --version
```

## 🌟 Решение №4 - Используйте yarn:

```bash
# Установите yarn как альтернативу npm
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update
sudo apt install -y yarn

# Используйте yarn вместо npm
yarn install
yarn build
```

## 📁 Ручная установка (если ничего не помогло):

```bash
# 1. Соберите проект локально
npm install  # или yarn install
npm run build  # или yarn build

# 2. Скопируйте файлы на сервер
sudo mkdir -p /var/www/html
sudo cp -r dist/spa/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html

# 3. Настройте nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 80;
    server_name 69.62.126.191;
    root /var/www/html;
    index index.html;

    location ~* \.application$ {
        add_header Content-Type "application/x-ms-application";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    location ~* \.exe$ {
        add_header Content-Type "application/octet-stream";
        add_header Content-Disposition "attachment";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF

# 4. Перезапустите nginx
sudo nginx -t
sudo systemctl restart nginx
```

## ✅ Проверка результата:

После любого из решений:

```bash
# Проверьте что сайт работает
curl -I http://69.62.126.191/

# Проверьте ClickOnce файлы
ls -la /var/www/html/deploy/

# Проверьте nginx
sudo systemctl status nginx
```

## 🌐 Финальная проверка:

Откройте в браузере `http://69.62.126.191` и нажмите кнопку "🚀 Запустить приложение"

---

**💡 Рекомендуется начать с решения №1 (deploy-simple.sh) - оно должно решить большинство проблем автоматически!**
