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
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd && rm -rf 0g-chain
git clone https://github.com/0glabs/0g-chain
cd 0g-chain
git checkout v0.2.3

# Build binary
make install

0gchaind config chain-id zgtendermint_16600-2
0gchaind config keyring-backend test
0gchaind config node tcp://localhost:26657
source $HOME/.bash_profile

0gchaind init "$NODE_MONIKER" --chain-id zgtendermint_16600-2

### Download genesis and addrbook
wget https://github.com/0glabs/0g-chain/releases/download/v0.1.0/genesis.json -O $HOME/.0gchain/config/genesis.json
wget https://snapshots-testnet.unitynodes.com/0gchain-testnet/addrbook.json -O $HOME/.0gchain/config/addrbook.json

PEERS="6dbb0450703d156d75db57dd3e51dc260a699221@152.53.47.155:13456,df4cc52fa0fcdd5db541a28e4b5a9c6ce1076ade@37.60.246.110:13456,54c269f44e1a9c3fd00fe62db52ac08e59b148f7@85.239.232.29:13456,dbfb5240845c8c7d2865a35e9f361cc42877721f@78.46.40.246:34656,386c82b09e0ec6a68e653a5d6c57f766ae73e0df@194.163.183.208:26656,d5e294d6d5439f5bd63d1422423d7798492e70fd@77.237.232.146:26656,48e3cab55ba7a1bc8ea940586e4718a857de84c4@178.63.4.186:26656,3bd6c0c825470d07cd49e57d0b650d490cc48527@37.60.253.166:26656,6efd3559f5d9d13e6442bc2fc9b17e50dc800970@91.205.104.91:13456,3b3ddcd4de429456177b29e5ca0febe4f4c21989@75.119.139.198:26656,58702cc91cc456e9beeb9b3e381f23fac39a3311@94.16.31.30:13456,e7c8f15c88ec1d6dc2b3a9ab619519fbd61182d6@217.76.54.13:26656,7e6124b7816c2fddd1e0f08bbaf0b6876230c5f4@37.27.120.13:26656,d82f58230074dccc8371f05df35c3e8d71ece034@69.67.150.107:23656,537abd857a3335e46e0f010cc01bde94854691a4@5.252.55.236:13456"
SEEDS="81987895a11f6689ada254c6b57932ab7ed909b6@54.241.167.190:26656,010fb4de28667725a4fef26cdc7f9452cc34b16d@54.176.175.48:26656,e9b4bc203197b62cc7e6a80a64742e752f4210d5@54.193.250.204:26656,68b9145889e7576b652ca68d985826abd46ad660@18.166.164.232:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.0gchain/config/config.toml

### Minimum gas price
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.0gchain/config/app.toml

### Set pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.0gchain/config/app.toml


### Downoload snapshot
curl "https://snapshots-testnet.unitynodes.com/0gchain-testnet/0gchain-testnet-latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.0gchain"

### Create service
sudo tee /etc/systemd/system/0gchaind.service > /dev/null << EOF
[Unit]
Description=0G node service
After=network-online.target
[Service]
User=$USER
ExecStart=$(which 0gchaind) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable 0gchaind.service
sudo systemctl start 0gchaind.service
sudo journalctl -u 0gchaind -f -o cat

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u 0gchaind -f -o cat"
printGreen "Переглянути статус синхронізації: 0gchaind status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}

install
