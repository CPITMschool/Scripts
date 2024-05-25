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
  
  sudo systemctl stop initiad

  cd && rm -rf initia
  git clone https://github.com/initia-labs/initia
  cd initia
  git checkout v0.2.15

  make install

  sudo systemctl restart initiad
  sudo journalctl -u initiad -f -o cat
  printGreen "Версія вашої ноди:"
  initiad version
  
  echo ""
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u initiad -f -o cat"
  printGreen "Переглянути статус синхронізації: initiad status 2>&1 | jq .SyncInfo"
  printDelimiter
}

update
