#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function update() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
  printGreen "Оновлюємо Lava"
  echo ""
  sudo systemctl stop wardend

  cd $HOME
  rm -rf wardenprotocol
  git clone https://github.com/warden-protocol/wardenprotocol
  cd wardenprotocol
  git checkout v0.4.1

  sudo systemctl start wardend
  sleep 2
  printGreen "Версія вашої ноди:"
  wardend version
  echo ""
  
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u lavad -f -o cat"
  printGreen "Переглянути статус синхронізації: lavad status 2>&1 | jq .SyncInfo"
  printGreen "В журналі логів спочатку ви можете побачити помилку Connection is closed. Але за 5-10 секунд нода розпочне синхронізацію"
  printDelimiter
}

update
