#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
  sudo systemctl stop stabled 2>/dev/null || true
  sudo systemctl disable stabled 2>/dev/null || true

  sudo rm -rf "$HOME/.stabled"
  sudo rm -rf "$HOME/stabled"
  sudo rm -rf "$HOME/stable-backup"
  sudo rm -rf "$HOME/snapshot"

  sudo rm -f /etc/systemd/system/stabled.service
  sudo rm -f "$HOME/go/bin/stabled"
  sudo rm -f /usr/local/bin/stabled

  sudo systemctl daemon-reload
  sudo systemctl reset-failed stabled 2>/dev/null || true
}

logo
delete

printGreen "Stable node видалено"
