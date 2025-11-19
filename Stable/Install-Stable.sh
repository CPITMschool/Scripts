#!/bin/bash

clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

function install() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" PORT
echo 'export PORT='$PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export STABLE_CHAIN_ID="stabletestnet_2201-1"" >> $HOME/.bash_profile
echo "export STABLE_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

printLine
echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$STABLE_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$STABLE_PORT\e[0m"
printLine
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.25.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

source <(curl -s https://raw.githubusercontent.com/itrocket-team/testnet_guides/main/utils/dependencies_install)

printGreen "4. Installing binary..." && sleep 1
# download binary
  rm -rf bin
  mkdir bin && cd bin
  wget https://snapshots.unitynodes.app/stable-1.1.1/stabled
  mkdir -p "$HOME/go/bin"
  chmod +x stabled
  sudo mv $PWD/stabled "$HOME/go/bin/"
  cd $HOME
  rm -rf bin

printGreen "5. Configuring and init app..." && sleep 1
# config and init app
stabled init $MONIKER --chain-id $STABLE_CHAIN_ID
  APP_TOML="$HOME/.stabled/config/app.toml"
  CONFIG_TOML="$HOME/.stabled/config/config.toml"


sed -i -e "s|^node *=.*|node = \"tcp://localhost:${STABLE_PORT}657\"|" $HOME/.stabled/config/client.toml
 # Download testnet genesis
  cd "$HOME"
  wget https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip
  unzip -o stable_testnet_genesis.zip

  # Move genesis to config directory
  cp genesis.json "$HOME/.stabled/config/genesis.json"

  # Verify genesis checksum
  sha256sum "$HOME/.stabled/config/genesis.json"
  # Expected: 66afbb6e57e6faf019b3021de299125cddab61d433f28894db751252f5b8eaf2
  sleep 2
  ### app.toml — JSON-RPC
  # enable = true
  sed -i.bak '/\[json-rpc\]/,/^\[/ s/^[[:space:]#]*enable[[:space:]]*=.*/enable = true/' "$APP_TOML"
  # address = "0.0.0.0:8545"
  sed -i '/\[json-rpc\]/,/^\[/ s|^[[:space:]#]*address[[:space:]]*=.*|address = "0.0.0.0:8545"|' "$APP_TOML"
  # ws-address = "0.0.0.0:8546"
  sed -i '/\[json-rpc\]/,/^\[/ s|^[[:space:]#]*ws-address[[:space:]]*=.*|ws-address = "0.0.0.0:8546"|' "$APP_TOML"
  # allow-unprotected-txs = true
  sed -i '/\[json-rpc\]/,/^\[/ s/^[[:space:]#]*allow-unprotected-txs[[:space:]]*=.*/allow-unprotected-txs = true/' "$APP_TOML"
  ### config.toml — P2P
  # max_num_inbound_peers = 50
  sed -i.bak '/\[p2p\]/,/^\[/ s/^[[:space:]#]*max_num_inbound_peers[[:space:]]*=.*/max_num_inbound_peers = 50/' "$CONFIG_TOML"
  # max_num_outbound_peers = 30
  sed -i '/\[p2p\]/,/^\[/ s/^[[:space:]#]*max_num_outbound_peers[[:space:]]*=.*/max_num_outbound_peers = 30/' "$CONFIG_TOML"
  # persistent_peers
  sed -i '/\[p2p\]/,/^\[/ s|^[[:space:]#]*persistent_peers[[:space:]]*=.*|persistent_peers = "5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"|' "$CONFIG_TOML"
  # pex = true
  sed -i '/\[p2p\]/,/^\[/ s/^[[:space:]#]*pex[[:space:]]*=.*/pex = true/' "$CONFIG_TOML"
  ### config.toml — RPC
  # laddr = "tcp://0.0.0.0:26657"
  sed -i '/\[rpc\]/,/^\[/ s|^[[:space:]#]*laddr[[:space:]]*=.*|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_TOML"
  # max_open_connections = 900
  sed -i '/\[rpc\]/,/^\[/ s/^[[:space:]#]*max_open_connections[[:space:]]*=.*/max_open_connections = 900/' "$CONFIG_TOML"
  # cors_allowed_origins = ["*"]
  sed -i '/\[rpc\]/,/^\[/ s/^[[:space:]#]*cors_allowed_origins[[:space:]]*=.*/cors_allowed_origins = ["*"]/' "$CONFIG_TOML"

  SEEDS="5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"
  PEERS="5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656,9d1150d557fbf491ec5933140a06cdff40451dee@164.68.97.210:26656,e33988e27710ee1a7072f757b61c3b28c922eb59@185.232.68.94:11656,ff4ff638cee05df63d4a1a2d3721a31a70d0debc@141.94.138.48:26664"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.stabled/config/config.toml

printGreen "7. Adding seeds, peers, configuring custom ports, pruning, minimum gas price..." && sleep 1

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${STABLE_PORT}317%g;
s%:8080%:${STABLE_PORT}080%g;
s%:9090%:${STABLE_PORT}090%g;
s%:9091%:${STABLE_PORT}091%g;
s%:8545%:${STABLE_PORT}545%g;
s%:8546%:${STABLE_PORT}546%g;
s%:6065%:${STABLE_PORT}065%g" $HOME/.stabled/config/app.toml


# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${STABLE_PORT}658%g;
s%:26657%:${STABLE_PORT}657%g;
s%:6060%:${STABLE_PORT}060%g;
s%:26656%:${STABLE_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${STABLE_PORT}656\"%;
s%:26660%:${STABLE_PORT}660%g" $HOME/.stabled/config/config.toml


# create service file
sudo tee /etc/systemd/system/stabled.service > /dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which stabled) start --chain-id stabletestnet_2201-1
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stabled

[Install]
WantedBy=multi-user.target
EOF

printGreen "8. Downloading snapshot and starting node..." && sleep 1
# Snapshot
  mkdir -p "$HOME/stable-backup"
  cp -r "$HOME/.stabled/data" "$HOME/stable-backup/" 2>/dev/null || true

  sudo apt update
  sudo apt install -y wget lz4 pv

  mkdir -p "$HOME/snapshot"
  cd "$HOME/snapshot"

  wget -O snapshot.tar.lz4 https://stable-snapshot.s3.eu-central-1.amazonaws.com/snapshot.tar.lz4

  rm -rf "$HOME/.stabled/data"/*
  pv snapshot.tar.lz4 | tar -I lz4 -xf - -C "$HOME/.stabled/"
  rm snapshot.tar.lz4

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable stabled
sudo systemctl restart stabled

  ### Useful commands
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u stabled -f -o cat"
  printGreen "Переглянути статус синхронізації: stabled status | jq | grep \"catching_up\""
  source "$HOME/.bash_profile"
  printDelimiter

}

install