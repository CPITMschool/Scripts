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
wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.5.1/0gchaind-linux-v0.5.1
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
PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,bf924ae011cb3f4f5c0c6a1993703fda2ed90661@194.163.160.15:26656,528fd49ac79811239695eb1c4c9eadc430bd2bf2@65.108.36.150:26656,f40437f2be5141371100cdda486c0723710144cd@88.198.70.23:27856,7cf4c84a6e44e919a74f26c04c3bf231fd2d4d03@162.55.98.31:26656,1a01f35a46c6545bc55a8b38f51aed123659f51a@95.216.98.122:11656,044a26f8b424eadc0509c503d3e902552789fef2@37.27.60.37:26656,021e5ca1ca04631790feda8142b05640916a3c6c@5.9.141.187:26656,8554b5583aa2773dd06138388bdfdc25b6038fc6@162.55.102.52:26656,78083fc2c1f98e849ff2969467b82ca154979cdd@135.181.231.88:26656,3fbd35d9137ce0e97a78f9797a5c76debe3f2384@95.217.205.92:26656,779acfc7fc7d45865c1f2652e8bd329e29f36b9f@135.181.57.240:26656,4c7b139e9ec5671887ba66e0f5ff8c1192cf8f43@65.21.82.218:26656,ff8534292b54e69db55f1486adeca9dde9335137@37.27.118.142:26656,2dcc4da1d33ab1db810eea82f978fa145b432d18@168.119.10.33:26656,0c2d883524434768b5df39c71749651acdd620c8@95.217.140.187:26656,8c8ff8aa063d3d2dbcd6a7bf121270aa5dbc12f8@65.109.49.115:27856"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchain/config/config.toml

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
if curl -s --head curl https://server-5.itrocket.net/testnet/og/og_2025-04-08_3908831_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-5.itrocket.net/testnet/og/og_2025-04-08_3908831_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain
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
