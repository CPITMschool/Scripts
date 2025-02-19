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
  rm -rf bin
  mkdir bin && cd bin
  wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.5.4/wardend_Linux_x86_64.zip
  unzip wardend_Linux_x86_64.zip
  chmod +x wardend
  sudo mv $HOME/bin/wardend $(which wardend)
  sudo systemctl restart wardend && sudo journalctl -u wardend -f

  sleep 2
  printGreen "Версія вашої ноди:"
  wardend version
  echo ""
  
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u wardend -f -o cat"
  printDelimiter
}

update
