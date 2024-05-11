#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop 0gchaind
  sudo systemctl disable 0gchaind
  sudo rm -rf $HOME/.0gchain
  sudo rm -rf $HOME/0gchain
  sudo rm -rf /etc/systemd/system/0gchaind.service
  sudo rm -rf /usr/local/bin/0gchaind
  sudo systemctl daemon-reload
}

logo
delete

printGreen "0G node видалено"
