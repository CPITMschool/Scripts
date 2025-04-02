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
wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.5.3/0gchaind-linux-v0.5.3
chmod +x $HOME/0gchaind
sudo mkdir -p "$HOME/go/bin" && sudo mv "$HOME/0gchaind" "$HOME/go/bin"
0gchaind version

0gchaind config chain-id zgtendermint_16600-2
0gchaind config keyring-backend test
0gchaind config node tcp://localhost:26657
source $HOME/.bash_profile

0gchaind init "$NODE_MONIKER" --chain-id zgtendermint_16600-2

### Download genesis and addrbook
wget -O $HOME/.0gchain/config/genesis.json https://server-5.itrocket.net/testnet/og/genesis.json
wget -O $HOME/.0gchain/config/addrbook.json  https://server-5.itrocket.net/testnet/og/addrbook.json

SEEDS="bac83a636b003495b2aa6bb123d1450c2ab1a364@og-testnet-seed.itrocket.net:47656"
PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,0b7f6b17f9c96705ccf12261f822af71deddaf47@75.119.152.114:26656,898a1aeb8b8fc47dddf8624bbc4199b9b9000ae8@62.169.29.104:12656,d0b72e81ad02869c94d71771cae303cbe1d92ba7@158.220.107.134:12656,6c04ced3f2ea5dbe53cd6021772f953f19904099@194.163.135.175:12656,a8eb33fc7928dbc72133b39cbe6be11cd730100f@62.171.128.133:12656,342c70d258f65cfa662a1a8e3215627d7c670053@84.46.248.204:26656,338933cdb9cbbc6f4f6195be722726706b2b7e70@194.163.187.249:47656,8e3f23df98376af21eb20fe30fe342395e1418f1@164.68.121.195:12656,fdd67e39de882dbdd43c3df752a96cff9176b56e@158.220.99.250:12656,571d4e154b4f9775904a9256da9d1e9eb36cd84b@185.209.228.106:12656,fd752d52b9b09f12801512119c8e4cc2b6b63501@38.242.140.38:12656,8c5013fcb40149567d38d4e9484586a85b2c1b49@62.171.153.87:12656,cb73a5dd8c6d93cd3223799fe62c03a444082ed1@185.237.253.52:47656,709311571412185ef643bd2773167a5e58d940f1@5.182.17.178:12656,c3fe952bd71aeaa640c432dea2efbf3226fa3208@45.67.216.248:12656,d9443e48bbe44fa711d04c00c7e109857be33381@217.76.52.206:12656,528fd49ac79811239695eb1c4c9eadc430bd2bf2@65.108.36.150:26656,870c7c5a08bc658b896f605e593dacbb23106efa@86.48.0.88:12656,d965c45e1e2ae18cb4db25dbf3159f3b5911e4f0@207.180.212.116:12656,897d11f1bb31aae0e788620768eec70117b2a026@144.91.106.32:12656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchain/config/config.toml

# Сonfig pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.0gchain/config/app.toml

# Set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0ua0gi"|g' $HOME/.0gchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.0gchain/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchain/config/config.toml


### Downoload snapshot
0gchaind tendermint unsafe-reset-all --home $HOME/.0gchain
if curl -s --head curl https://server-5.itrocket.net/testnet/og/og_2025-02-23_3356409_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-5.itrocket.net/testnet/og/og_2025-02-23_3356409_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain
    else
  echo "no snapshot found"
fi


### Create service
sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0G node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.0gchain
ExecStart=$(which 0gchaind) start --home $HOME/.0gchain --log_output_console
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable 0gchaind
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -fo cat

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         journalctl -u 0gchaind -fo cat "
printGreen "Переглянути статус синхронізації: 0gchaind status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}

install
