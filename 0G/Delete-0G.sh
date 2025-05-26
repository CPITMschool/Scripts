#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function delete() {
  printGreen "Stopping services..."
  sudo systemctl stop 0gchaind 0ggeth || true

  printGreen "Disabling services..."
  sudo systemctl disable 0gchaind 0ggeth || true

  printGreen "Removing systemd service files..."
  sudo rm -f /etc/systemd/system/0gchaind.service
  sudo rm -f /etc/systemd/system/0ggeth.service

  printGreen "Reloading systemd daemon..."
  sudo systemctl daemon-reload

  printGreen "Removing binaries..."
  rm -f $HOME/go/bin/0gchaind
  rm -f $HOME/go/bin/geth

  printGreen "Removing node data and configs..."
  rm -rf $HOME/.0gchaind
  rm -rf $HOME/galileo-used
  rm -rf $HOME/galileo
  rm -rf $HOME/galileo.tar.gz

  printGreen "Removing environment variables from .bash_profile..."
  sed -i '/MONIKER/d' $HOME/.bash_profile
  sed -i '/OG_PORT/d' $HOME/.bash_profile
  sed -i '/galileo-used\/bin/d' $HOME/.bash_profile

  printGreen "Uninstallation completed."
}


logo
delete

printGreen "0G node видалено"
