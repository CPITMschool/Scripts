#!/bin/bash


source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function install() {

clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

echo -e "\e[30;47m Please enter the node moniker:\e[0m"
echo -en ">>> "
read -r NODE_MONIKER

### Install Dependencies
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.15
make install

initiad config node tcp://localhost:26657
initiad config keyring-backend os
initiad config chain-id initiation-1
source $HOME/.bash_profile

initiad init "$NODE_MONIKER" --chain-id=initiation-1

### Download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/initia-testnet/genesis.json > $HOME/.initia/config/genesis.json
curl -s https://snapshots-testnet.nodejumper.io/initia-testnet/addrbook.json > $HOME/.initia/config/addrbook.json

### Seed,Peers config
sed -i -e 's|^seeds *=.*|seeds = "2eaa272622d1ba6796100ab39f58c75d458b9dbc@34.142.181.82:26656,c28827cb96c14c905b127b92065a3fb4cd77d7f6@testnet-seeds.whispernode.com:25756,cd69bcb00a6ecc1ba2b4a3465de4d4dd3e0a3db1@initia-testnet-seed.itrocket.net:51656,093e1b89a498b6a8760ad2188fbda30a05e4f300@35.240.207.217:26656,2c729d33d22d8cdae6658bed97b3097241ca586c@195.14.6.129:26019"|' $HOME/.initia/config/config.toml

### Minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml

### Set pruning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.initia/config/app.toml

### Create service
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=initiad
After=network-online.target

[Service]
User=$USER
ExecStart=$(which initiad) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable initiad

### Download snapshot
echo ""
printColor blue "[5/6] Downloading snapshot for fast synchronization" 
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book 
curl https://snapshots-testnet.nodejumper.io/initia-testnet/initia-testnet_latest.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia


### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable initiad.service
sudo systemctl start initiad.service

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u initiad -f -o cat"
printGreen "Переглянути статус синхронізації: initiad status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}
install
