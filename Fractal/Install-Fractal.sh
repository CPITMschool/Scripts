#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function install() {
clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
printGreen "Встановлюємо ноду Fractal Bitcoin"

wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.7/fractald-0.1.7-x86_64-linux-gnu.tar.gz
tar -zxvf fractald-0.1.7-x86_64-linux-gnu.tar.gz 


cd fractald-0.1.7-x86_64-linux-gnu/
mkdir data
cp ./bitcoin.conf ./data


sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target

[Service]
User=$USER
ExecStart=/root/fractald-0.1.7-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.1.7-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF


cd bin
./bitcoin-wallet -wallet=wallet -legacy create


cd /root/fractald-0.1.7-x86_64-linux-gnu/bin
./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump


cd && awk -F 'checksum,' '/checksum/ {print "Wallet Private Key:" $2}' .bitcoin/wallets/wallet/MyPK.dat


read -p "Ви зберегли приватний ключ від гаманця? [Y/N] " response
if [[ "$response" != "Y" && "$response" != "y" ]]; then
    echo "Будь ласка, збережіть приватний ключ перед продовженням."
    exit 1
fi


sudo systemctl daemon-reload
sudo systemctl enable fractald
sudo systemctl start fractald

sleep 10
echo "Запускаємо журнал логів"
sudo journalctl -u fractald -f -o cat


### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u fractald -f -o cat" 
source $HOME/.bash_profile
printDelimiter
}

install
