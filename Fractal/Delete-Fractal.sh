#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
sudo systemctl stop fractald
sudo systemctl disable fractald
sudo rm -rf /root/fractald-0.1.7-x86_64-linux-gnu
sudo rm -f /etc/systemd/system/fractald.service
sudo rm -rf /root/.bitcoin
sudo systemctl daemon-reload
echo "Видалення завершено."
}

logo
delete

printGreen "Fractal node видалено"
