#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop zgs.service
  sudo systemctl disable zgs.service
  sudo rm -rf /etc/systemd/system/zgs.service
  sudo rm -rf $HOME/0g-storage-node
  sudo rm -rf /usr/local/bin/zgs_node
}

logo
delete

printDelimiter
printGreen "✅ 0G Storage node видалено"
printDelimiter