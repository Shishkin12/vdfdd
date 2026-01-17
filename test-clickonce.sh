#!/bin/bash

echo "🧪 Тестирую ClickOnce функциональность..."

echo "1. Проверяю главную страницу:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://69.62.126.191/

echo ""
echo "2. Проверяю ClickOnce манифест:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://69.62.126.191/deploy/whatsmaster.application

echo ""
echo "3. Проверяю MIME тип ClickOnce:"
curl -s -I http://69.62.126.191/deploy/whatsmaster.application | grep -i content-type || echo "MIME тип не найден"

echo ""
echo "4. Проверяю nginx статус:"
systemctl is-active nginx && echo "nginx работает" || echo "nginx не работает"

echo ""
echo "5. Проверя�� AppArmor для nginx:"
aa-status /usr/sbin/nginx 2>/dev/null || echo "AppArmor не настроен"

echo ""
echo "🎯 Инструкция по тестированию:"
echo "1. Откройте http://69.62.126.191"
echo "2. Нажмите кнопку '🚀 Запустить EdgeSync Agent'"
echo "3. Подтвердите переход в Microsoft Edge"
echo "4. Подтвердите установку Security EdgeSync Agent"
