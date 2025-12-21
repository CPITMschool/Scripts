#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  docker stop arx-node 2>/dev/null || true
  docker rm arx-node 2>/dev/null || true

  rm -rf "$HOME/arcium-node-setup"
  rm -rf "$HOME/.arcium"

  sed -i '/NODE_OFFSET/d' $HOME/.bash_profile
  sed -i '/NODE_IP/d' $HOME/.bash_profile
  sed -i '/RPC_URL/d' $HOME/.bash_profile
  
  source $HOME/.bash_profile 2>/dev/null || true
}

logo
delete

printGreen "Arcium node видалено"