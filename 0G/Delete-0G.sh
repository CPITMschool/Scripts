#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  printGreen "Зупинка ноди..."
  sudo systemctl stop 0gchaind 0ggeth || true

  printGreen "Выдключення сервісного файлу..."
  sudo systemctl disable 0gchaind 0ggeth || true

  printGreen "Видалення systemd сервісних файлів..."
  sudo rm -f /etc/systemd/system/0gchaind.service
  sudo rm -f /etc/systemd/system/0ggeth.service

  printGreen "Перезавантаження systemd daemon..."
  sudo systemctl daemon-reload

  printGreen "Видалення бінарних файлів"
  rm -f $HOME/go/bin/0gchaind
  rm -f $HOME/go/bin/geth

  printGreen "Видалення всіх данних..."
  rm -rf $HOME/.0gchaind
  rm -rf $HOME/galileo-used
  rm -rf $HOME/galileo
  rm -rf $HOME/galileo.tar.gz

  printGreen "Видалення значень .bash_profile..."
  sed -i '/MONIKER/d' $HOME/.bash_profile
  sed -i '/OG_PORT/d' $HOME/.bash_profile
  sed -i '/galileo-used\/bin/d' $HOME/.bash_profile

  printGreen "Uninstallation completed."
}

logo
delete
printGreen "0G node видалено"
