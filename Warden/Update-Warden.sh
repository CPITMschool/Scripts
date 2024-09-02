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
  printGreen "Оновлюємо Warden"
  echo ""
  cd $HOME
  rm -rf download
  mkdir download
  cd download
  wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.4.2/wardend_Linux_x86_64.zip
  unzip wardend_Linux_x86_64.zip
  rm wardend_Linux_x86_64.zip
  chmod +x $HOME/download/wardend
  sudo mv $HOME/download/wardend $(which wardend)
  sudo systemctl restart wardend

  sleep 2
  printGreen "Версія вашої ноди:"
  wardend version
  echo ""
  
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u wardend -f -o cat"
  printDelimiter
}

update
