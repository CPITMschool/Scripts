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

echo -e "\e[30;47m Введіть ім'я moniker(Наприклад: Oliver):\e[0m"
echo -en ">>> "
read -r NODE_MONIKER

### Install Dependencies

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd $HOME
rm -rf wardenprotocol
git clone https://github.com/warden-protocol/wardenprotocol
cd wardenprotocol
git checkout v0.3.0
make install-wardend
source .bash_profile

wardend config set client chain-id buenavista-1
wardend config set client keyring-backend test
wardend config set client node tcp://localhost:26657
source $HOME/.bash_profile

wardend init "$NODE_MONIKER" --chain-id buenavista-1

### Download genesis and addrbook
curl -L https://snapshots-testnet.unitynodes.com/warden-testnet/genesis.json > $HOME/.warden/config/genesis.json
curl -L https://snapshots-testnet.unitynodes.com/warden-testnet/addrbook.json > $HOME/.warden/config/addrbook.json

### Seed config
sed -i -e 's|^seeds *=.*|seeds = "ddb4d92ab6eba8363bab2f3a0d7fa7a970ae437f@sentry-1.buenavista.wardenprotocol.org:26656,c717995fd56dcf0056ed835e489788af4ffd8fe8@sentry-2.buenavista.wardenprotocol.org:26656,e1c61de5d437f35a715ac94b88ec62c482edc166@sentry-3.buenavista.wardenprotocol.org:26656"|' $HOME/.warden/config/config.toml

### Minimum gas price
sed -i -e 's|^seeds *=.*|seeds = "ddb4d92ab6eba8363bab2f3a0d7fa7a970ae437f@sentry-1.buenavista.wardenprotocol.org:26656,c717995fd56dcf0056ed835e489788af4ffd8fe8@sentry-2.buenavista.wardenprotocol.org:26656,e1c61de5d437f35a715ac94b88ec62c482edc166@sentry-3.buenavista.wardenprotocol.org:26656"|' $HOME/.warden/config/config.toml
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uward"|' $HOME/.warden/config/app.toml

### Set pruning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "10"|' \
  $HOME/.warden/config/app.toml


### Create service
sudo tee /etc/systemd/system/wardend.service > /dev/null << EOF
[Unit]
Description=Warden Protocol node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which wardend) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

### Download snapshot
echo ""
printColor blue "[5/6] Downloading snapshot for fast synchronization" 
curl "https://snapshots-testnet.unitynodes.com/warden-testnet/warden-testnet-latest.tar.lz4" | lz4 -dc - | tar -xf - -C $HOME/.warden

### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable wardend.service
sudo systemctl start wardend.service

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u wardend -f -o cat"
printGreen "Переглянути статус синхронізації: wardend status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}

install
