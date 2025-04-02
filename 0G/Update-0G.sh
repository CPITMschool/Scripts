#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function update() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
  printGreen "Оновлюємо 0G"
  # download binary
# download binary
cd $HOME
rm -rf 0g-chain
wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.5.3/0gchaind-linux-v0.5.3
chmod +x $HOME/0gchaind
sudo mv $HOME/0gchaind $(which 0gchaind)
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -f
}

update
