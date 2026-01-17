#!/bin/bash

echo "🔍 БЫСТРАЯ ДИАГНОСТИКА NGINX ПРОБЛЕМЫ..."

echo ""
echo "1. Статус nginx:"
systemctl status nginx.service --no-pager -l | head -15

echo ""
echo "2. Последние ошибки nginx:"
journalctl -u nginx.service --no-pager -l | tail -10

echo ""
echo "3. Занятые порты 80/443:"
sudo netstat -tlnp | grep -E ':80|:443'

echo ""
echo "4. Процессы nginx:"
sudo ps aux | grep nginx

echo ""
echo "5. Тест конфигурации nginx:"
sudo nginx -t

echo ""
echo "6. Файлы конфигурации:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "7. Права на веб-директорию:"
ls -la /var/www/html/ | head -5

echo ""
echo "🔧 ВОЗМОЖНЫЕ РЕШЕНИЯ:"
echo "   • Запустите: chmod +x fix-nginx-issue.sh && sudo ./fix-nginx-issue.sh"
echo "   • Или ручные команды:"
echo "     sudo pkill nginx"
echo "     sudo systemctl stop nginx"
echo "     sudo systemctl start nginx"
