#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop wardend
  sudo systemctl disable wardend
  sudo rm -rf $HOME/.warden
  sudo rm -rf $HOME/warden
  sudo rm -rf /etc/systemd/system/wardend.service
  sudo rm -rf /usr/local/bin/warden
  sudo systemctl daemon-reload
}

logo
delete

printGreen "Warden node видалено"
