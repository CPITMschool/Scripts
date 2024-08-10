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

cd $HOME
rm -rf 0g-chain
git clone -b v0.2.5 https://github.com/0glabs/0g-chain.git
cd 0g-chain
make install

# Build binary
make install

0gchaind config chain-id zgtendermint_16600-2
0gchaind config keyring-backend test
0gchaind config node tcp://localhost:26657
source $HOME/.bash_profile

0gchaind init "$NODE_MONIKER" --chain-id zgtendermint_16600-2

##CHANGE PORTS
sed -i.bak -e "s%:1317%:1417%g; 
s%:8080%:8180%g;
s%:9090%:9190%g;
s%:9091%:9191%g;
s%:8545%:8645%g;
s%:8546%:8646%g;
s%:6065%:6165%g" $HOME/.0gchain/config/app.toml	
sed -i.bak -e "s%:26658%:27658%g;
s%:26657%:27657%g;
s%:6060%:6160%g;
s%tcp://0.0.0.0:26656%tcp://0.0.0.0:27656%g;
s%:26660%:27660%g" $HOME/.0gchain/config/config.toml
sed -i.bak -e "s%:26657%:27657%g" $HOME/.0gchain/config/client.toml

### Download genesis and addrbook
curl -L https://snapshots-testnet.nodejumper.io/0g-testnet/genesis.json > $HOME/.0gchain/config/genesis.json
curl -L https://snapshots-testnet.nodejumper.io/0g-testnet/addrbook.json > $HOME/.0gchain/config/addrbook.json

sed -i -e 's|^seeds *=.*|seeds = "81987895a11f6689ada254c6b57932ab7ed909b6@54.241.167.190:26656,010fb4de28667725a4fef26cdc7f9452cc34b16d@54.176.175.48:26656,e9b4bc203197b62cc7e6a80a64742e752f4210d5@54.193.250.204:26656,68b9145889e7576b652ca68d985826abd46ad660@18.166.164.232:26656"|' $HOME/.0gchain/config/config.toml

### Minimum gas price
sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0025ua0gi"|' $HOME/.0gchain/config/app.toml

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
curl "https://snapshots-testnet.nodejumper.io/0g-testnet/0g-testnet_latest.tar.lz4" | lz4 -dc - | tar -xf - -C "$HOME/.0gchain"

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
