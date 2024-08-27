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
  printGreen "Оновлюємо Fractal"
 sudo systemctl stop fractald
 wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.8/fractald-0.1.8-x86_64-linux-gnu.tar.gz
 cd fractald-0.1.8-x86_64-linux-gnu
 mkdir data
 cp ./bitcoin.conf ./data
 ./bin/bitcoind -datadir=./data/ -maxtipage=504576000
 sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/fractald-0.1.8-x86_64-linux-gnu/bin/bitcoind -datadir=$HOME/fractald-0.1.8-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl restart fractald

rm -rf $HOME/fractald-0.1.7-x86_64-linux-gnu.tar.gz*
rm -rf $HOME/fractald-0.1.8-x86_64-linux-gnu.tar.gz*


  echo ""
 
  
}

update
