#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

clear
printDelimiter
printGreen "🚀 Початок видалення Pipe Node..."
printDelimiter

### Перевірка чи нода була встановлена через systemd service
if systemctl list-units --type=service | grep -q "pipe.service"; then
  printGreen "[1/4] Зупинка та видалення systemd-сервісу"
  sudo systemctl stop pipe
  sudo systemctl disable pipe
  sudo rm /etc/systemd/system/pipe.service
  sudo systemctl daemon-reload
  sudo systemctl reset-failed
else
  printGreen "⚠️ Сервіс systemd не знайдено. Перевірка screen-сесії..."
fi

### Перевірка та завершення screen-сесії
if screen -list | grep -q "pipe"; then
  printGreen "[2/4] Завершення screen-сесії"
  screen -X -S pipe quit
else
  printGreen "⚠️ Screen-сесія не знайдена."
fi

### Видалення файлів та каталогів
printGreen "[3/4] Видалення файлів та кешу"
rm -rf $HOME/pipe

### Перевірка та видалення можливих залишків у процесах
printGreen "[4/4] Перевірка та примусове завершення процесів"
pkill -f "$HOME/pipe/pop"

printDelimiter
printGreen "✅ Видалення завершено!"
printGreen "Перевірити чи процеси ще запущені: ps aux | grep pipe"
printGreen "Якщо процеси ще є, завершіть їх вручну за допомогою команди: kill -9 <PID>"
printDelimiter
