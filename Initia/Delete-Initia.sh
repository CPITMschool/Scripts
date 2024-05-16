#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop initiad
  sudo systemctl disable initiad
  sudo rm -rf $HOME/.initia
  sudo rm -rf $HOME/initia
  sudo rm -rf /etc/systemd/system/initiad.service
  sudo rm -rf /usr/local/bin/initiad
  sudo systemctl daemon-reload
}

logo
delete

printGreen "Initia node видалено"
