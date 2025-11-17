#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop stabled
  sudo systemctl disable stabled
  sudo rm -rf $HOME/.stabled
  sudo rm -rf $HOME/stabled
  sudo rm -rf /etc/systemd/system/stabled.service
  sudo rm -rf /usr/local/bin/stabled
  sudo systemctl daemon-reload
}

logo
delete

printGreen "Stable node видалено"
