#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

# Install dependencies
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

function install() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

  printGreen "Updating packages and installing dependencies..."
  sudo apt update && sudo apt upgrade -y
  sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

  printGreen "Installing Go..."
  cd $HOME && \
  ver="1.22.0" && \
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
  sudo rm -rf /usr/local/go && \
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
  rm "go$ver.linux-amd64.tar.gz" && \
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
  source ~/.bash_profile && \
  go version

  printGreen "Setting environment variables..."
  read -p "Enter your moniker name: " MONIKER
  echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile
  echo "export OG_PORT=\"55\"" >> $HOME/.bash_profile
  echo 'export PATH=$PATH:$HOME/galileo/bin' >> $HOME/.bash_profile
  source $HOME/.bash_profile

  printGreen "Downloading Galileo..."
  cd $HOME
  rm -rf galileo
  wget https://github.com/0glabs/0gchain-NG/releases/download/v1.1.1/galileo-v1.1.1.tar.gz
  tar -xzvf galileo-v1.1.1.tar.gz -C $HOME
  rm galileo-v1.1.1.tar.gz
  chmod +x $HOME/galileo/bin/geth
  chmod +x $HOME/galileo/bin/0gchaind

  sudo cp $HOME/galileo/bin/geth /usr/local/bin/geth
  sudo cp $HOME/galileo/bin/0gchaind /usr/local/bin/0gchaind

  printGreen "Initializing the chain..."
  mkdir -p $HOME/.0gchaind
  cp -r $HOME/galileo $HOME/.0gchaind/
  geth init --datadir $HOME/.0gchaind/galileo/0g-home/geth-home $HOME/.0gchaind/galileo/genesis.json
  0gchaind init $MONIKER --home $HOME/.0gchaind/tmp

  cp $HOME/.0gchaind/tmp/data/priv_validator_state.json $HOME/.0gchaind/galileo/0g-home/0gchaind-home/data/
  cp $HOME/.0gchaind/tmp/config/node_key.json $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/
  cp $HOME/.0gchaind/tmp/config/priv_validator_key.json $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/

  printGreen "Downloading and extracting snapshot..."
  mkdir -p ~/snapshot
  cd ~/snapshot

  wget https://vault.astrostake.xyz/0g-labs/validator-snapshot/0gchaind_snapshot_20250520-223437.tar.gz
  wget https://vault.astrostake.xyz/0g-labs/validator-snapshot/geth_snapshot_20250520-223437.tar.gz

  sudo systemctl stop 0gchaind || true
  sudo systemctl stop geth || sudo systemctl stop 0ggeth || true

  mv ~/.0gchaind/0g-home/0gchaind-home/data ~/.0gchaind/0g-home/0gchaind-home/data.bak.$(date +%s) || true
  mv ~/.0gchaind/0g-home/geth-home/geth ~/.0gchaind/0g-home/geth-home/geth.bak.$(date +%s) || true

  rm -rf ~/.0gchaind/0g-home/0gchaind-home/data
  rm -rf ~/.0gchaind/0g-home/geth-home/geth

  tar -xzvf 0gchaind_snapshot_20250520-223437.tar.gz -C ~/.0gchaind/0g-home/
  tar -xzvf geth_snapshot_20250520-223437.tar.gz -C ~/.0gchaind/0g-home/

  printGreen "Configuring ports and systemd services..."

  CONFIG="$HOME/.0gchaind/galileo/0g-home/0gchaind-home/config"

  sed -i -e "s/^moniker *=.*/moniker = \"$MONIKER\"/" $CONFIG/config.toml
  sed -i "s/laddr = \"tcp:\/\/0.0.0.0:26656\"/laddr = \"tcp:\/\/0.0.0.0:${OG_PORT}656\"/" $CONFIG/config.toml
  sed -i "s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/127.0.0.1:${OG_PORT}657\"/" $CONFIG/config.toml
  sed -i "s/^proxy_app = .*/proxy_app = \"tcp:\/\/127.0.0.1:${OG_PORT}658\"/" $CONFIG/config.toml
  sed -i "s/^pprof_laddr = .*/pprof_laddr = \"0.0.0.0:${OG_PORT}060\"/" $CONFIG/config.toml
  sed -i "s/prometheus_listen_addr = \".*\"/prometheus_listen_addr = \"0.0.0.0:${OG_PORT}660\"/" $CONFIG/config.toml

  sed -i "s/address = \".*:3500\"/address = \"127.0.0.1:${OG_PORT}500\"/" $CONFIG/app.toml
  sed -i "s/^rpc-dial-url *=.*/rpc-dial-url = \"http:\/\/localhost:${OG_PORT}551\"/" $CONFIG/app.toml
  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $CONFIG/config.toml

  sed -i "s/HTTPPort = .*/HTTPPort = ${OG_PORT}545/" $HOME/.0gchaind/galileo/geth-config.toml
  sed -i "s/WSPort = .*/WSPort = ${OG_PORT}546/" $HOME/.0gchaind/galileo/geth-config.toml
  sed -i "s/AuthPort = .*/AuthPort = ${OG_PORT}551/" $HOME/.0gchaind/galileo/geth-config.toml
  sed -i "s/ListenAddr = .*/ListenAddr = \":${OG_PORT}303\"/" $HOME/.0gchaind/galileo/geth-config.toml

  sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=$USER
Environment=CHAIN_SPEC=devnet
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/0gchaind start \
  --chain-spec devnet \
  --home $HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --kzg.trusted-setup-path=$HOME/.0gchaind/galileo/kzg-trusted-setup.json \
  --engine.jwt-secret-path=$HOME/.0gchaind/galileo/jwt-secret.hex \
  --kzg.implementation=crate-crypto/go-kzg-4844 \
  --home=$HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --p2p.seeds=85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
  --p2p.external_address=$(curl -4 -s ifconfig.me):${OG_PORT}656
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/geth.service > /dev/null <<EOF
[Unit]
Description=0g Geth Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/geth \
  --config $HOME/.0gchaind/galileo/geth-config.toml \
  --datadir $HOME/.0gchaind/galileo/0g-home/geth-home \
  --networkid 16601 \
  --http.port ${OG_PORT}545 \
  --ws.port ${OG_PORT}546 \
  --authrpc.port ${OG_PORT}551 \
  --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
  --port ${OG_PORT}303 \
  --networkid 16601
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  printGreen "Starting node..."
  sudo systemctl daemon-reload
  sudo systemctl enable 0gchaind
  sudo systemctl enable geth
  sudo systemctl start 0gchaind
  sudo systemctl start geth

  printGreen "✅ Installation complete."
}

install