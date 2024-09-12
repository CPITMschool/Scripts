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

# Clone project repository
cd $HOME
rm -rf 0g-chain
git clone https://github.com/0glabs/0g-chain.git
cd 0g-chain
git checkout v0.3.1
git submodule update --init
make install
0gchaind version

0gchaind config chain-id zgtendermint_16600-2
0gchaind config keyring-backend test
0gchaind config node tcp://localhost:26657
source $HOME/.bash_profile

0gchaind init "$NODE_MONIKER" --chain-id zgtendermint_16600-2

### Download genesis and addrbook
wget https://snapshots-testnet.unitynodes.com/0gchain-testnet/addrbook.json -O $HOME/.0gchain/config/addrbook.json
wget https://snapshots-testnet.unitynodes.com/0gchain-testnet/genesis.json -O $HOME/.0gchain/config/genesis.json

PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,e35e7fd0d24306a1bd1880cede7882fdb060087b@37.60.238.7:26656,8932538b172b16fad8058d0b3661c7168f8386a9@49.12.122.24:34656,d0a3d861d9b5f0d9aea19d372a738788bed82181@185.133.250.94:26646,cfdc5ae94fa5f36d4d4c9a9d09e09048806dccc0@95.217.120.205:27856,3439e019594d6a5199610c0276343c10a79c1a21@95.217.43.89:26656,928f42a91548484f35a5c98aa9dcb25fb1790a70@65.21.46.201:26656,829a2192dee46df728739266b8e72dd244b3b897@86.48.6.180:26656,61f94d8dc911f64a6f7e7e56da8614dfd59a803e@65.109.50.243:12656,b75bbb329a587e5c2044c6b96048717e8a15ec4f@185.218.125.192:12656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchain/config/config.toml

### Minimum gas price,pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.0gchain/config/app.toml

sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.00025ua0gi"|g' $HOME/.0gchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.0gchain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchain/config/config.toml


### Downoload snapshot
curl https://server-5.itrocket.net/testnet/og/og_2024-09-12_1039506_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain

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

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         tail -f /root/.0gchain/log/chain.log "
printGreen "Переглянути статус синхронізації: 0gchaind status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}

install
