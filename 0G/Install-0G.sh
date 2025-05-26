#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

function install() {
  read -p "Enter your MONIKER (default: test): " MONIKER
  MONIKER=${MONIKER:-test}

  read -p "Enter your OG_PORT (default: 26): " OG_PORT
  OG_PORT=${OG_PORT:-26}

  printGreen "Installing Go..."
  cd $HOME
  VER="1.21.3"
  wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
  rm "go$VER.linux-amd64.tar.gz"
  [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
  echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
  source $HOME/.bash_profile
  [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

  printGreen "Setting environment variables..."
  echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile
  echo "export OG_PORT=\"$OG_PORT\"" >> $HOME/.bash_profile
  echo 'export PATH=$PATH:$HOME/galileo-used/bin' >> $HOME/.bash_profile
  source $HOME/.bash_profile

  printGreen "Downloading binaries..."
  cd $HOME
  rm -rf galileo
  wget -O galileo.tar.gz https://github.com/0glabs/0gchain-NG/releases/download/v1.1.1/galileo-v1.1.1.tar.gz
  tar -xzvf galileo.tar.gz -C $HOME
  rm -rf $HOME/galileo.tar.gz
  chmod +x $HOME/galileo/bin/geth
  chmod +x $HOME/galileo/bin/0gchaind
  sudo fuser -k $HOME/go/bin/geth 2>/dev/null
  sudo fuser -k $HOME/go/bin/0gchaind 2>/dev/null
  cp $HOME/galileo/bin/geth $HOME/go/bin/geth
  cp $HOME/galileo/bin/0gchaind $HOME/go/bin/0gchaind
  mv $HOME/galileo $HOME/galileo-used

  printGreen "Initializing node..."
  mkdir -p $HOME/.0gchaind
  cp -r $HOME/galileo-used/0g-home $HOME/.0gchaind

  geth init --datadir $HOME/.0gchaind/0g-home/geth-home $HOME/galileo-used/genesis.json
  0gchaind init $MONIKER --home $HOME/.0gchaind/tmp --chain-id 16601

  mv $HOME/.0gchaind/tmp/data/priv_validator_state.json $HOME/.0gchaind/0g-home/0gchaind-home/data/
  mv $HOME/.0gchaind/tmp/config/node_key.json $HOME/.0gchaind/0g-home/0gchaind-home/config/
  mv $HOME/.0gchaind/tmp/config/priv_validator_key.json $HOME/.0gchaind/0g-home/0gchaind-home/config/
  rm -rf $HOME/.0gchaind/tmp

  sed -i -e "s/^moniker *=.*/moniker = \"$MONIKER\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

  printGreen "Configuring ports..."
  sed -i "s/HTTPPort = .*/HTTPPort = ${OG_PORT}545/" $HOME/galileo-used/geth-config.toml
  sed -i "s/WSPort = .*/WSPort = ${OG_PORT}546/" $HOME/galileo-used/geth-config.toml
  sed -i "s/AuthPort = .*/AuthPort = ${OG_PORT}551/" $HOME/galileo-used/geth-config.toml
  sed -i "s/ListenAddr = .*/ListenAddr = \":${OG_PORT}303\"/" $HOME/galileo-used/geth-config.toml
  sed -i "s/^# *Port = .*/# Port = ${OG_PORT}901/" $HOME/galileo-used/geth-config.toml
  sed -i "s/^# *InfluxDBEndpoint = .*/# InfluxDBEndpoint = \"http:\/\/localhost:${OG_PORT}086\"/" $HOME/galileo-used/geth-config.toml

  sed -i.bak -e "s%:26658%:${OG_PORT}658%g; s%:26657%:${OG_PORT}657%g; s%:6060%:${OG_PORT}060%g; s%:26656%:${OG_PORT}656%g; s%:26660%:${OG_PORT}660%g" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

  sed -i "s/address = \".*:3500\"/address = \"127.0.0.1:${OG_PORT}500\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
  sed -i "s/^rpc-dial-url *=.*/rpc-dial-url = \"http:\/\/localhost:${OG_PORT}551\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml

  sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml
  sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml

  mkdir -p $HOME/.0gchaind/config
  ln -sf $HOME/.0gchaind/0g-home/0gchaind-home/config/client.toml $HOME/.0gchaind/config/client.toml

  printGreen "Creating systemd services..."

  sudo tee /etc/systemd/system/0ggeth.service > /dev/null <<EOF
[Unit]
Description=0g Geth Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/galileo-used
ExecStart=$HOME/go/bin/geth \
    --config $HOME/galileo-used/geth-config.toml \
    --datadir $HOME/.0gchaind/0g-home/geth-home \
    --networkid 16601 \
    --http.port ${OG_PORT}545 \
    --ws.port ${OG_PORT}546 \
    --authrpc.port ${OG_PORT}551 \
    --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
    --port ${OG_PORT}303
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/galileo-used
ExecStart=$(which 0gchaind) start \
--rpc.laddr tcp://0.0.0.0:${OG_PORT}657 \
--chain-spec devnet \
--kzg.trusted-setup-path $HOME/galileo-used/kzg-trusted-setup.json \
--engine.jwt-secret-path $HOME/galileo-used/jwt-secret.hex \
--kzg.implementation=crate-crypto/go-kzg-4844 \
--block-store-service.enabled \
--node-api.enabled \
--node-api.logging \
--node-api.address 0.0.0.0:${OG_PORT}500 \
--pruning=nothing \
--p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
--p2p.external_address $(wget -qO- eth0.me):${OG_PORT}656 \
--home $HOME/.0gchaind/0g-home/0gchaind-home \
--chain-spec devnet
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  printGreen "Enabling and starting services..."
  sudo systemctl daemon-reload
  sudo systemctl enable 0gchaind 0ggeth
  sudo systemctl restart 0gchaind 0ggeth

  printGreen "Downloading and applying snapshots..."

  # install dependencies, and disable statesync to avoid sync issues
  sudo apt install curl tmux jq lz4 unzip -y
  sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

  # stop node and backup priv_validator_state.json
  sudo systemctl stop 0gchaind 0ggeth
  cp $HOME/.0gchaind/0g-home/0gchaind-home/data/priv_validator_state.json $HOME/priv_validator_state.json.backup

  # remove old data and unpack 0G snapshot
  rm -rf $HOME/.0gchaind/0g-home/0gchaind-home/data
  curl https://server-3.itrocket.net/testnet/og/og_2025-05-26_901847_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchaind/0g-home/0gchaind-home

  # restore priv_validator_state.json
  mv $HOME/priv_validator_state.json.backup $HOME/.0gchaind/0g-home/0gchaind-home/data/priv_validator_state.json

  # delete geth data and unpack Geth snapshot
  rm -rf $HOME/.0gchaind/0g-home/geth-home/geth/chaindata
  curl https://server-3.itrocket.net/testnet/og/geth_og_2025-05-26_901847_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchaind/0g-home/geth-home/geth

  # restart node and check logs
  sudo systemctl restart 0gchaind 0ggeth
  sudo journalctl -u 0gchaind -u 0ggeth -f

    printGreen "Waiting for logs..."
  sudo journalctl -u 0gchaind -u 0ggeth -f --no-hostname -o cat
}

install
