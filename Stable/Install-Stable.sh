#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

# Dependencies & helpers (curl, jq, unzip, etc.)
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

CHAIN_ID="stabletestnet_2201-1"
GENESIS_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip"
GENESIS_SHA="66afbb6e57e6faf019b3021de299125cddab61d433f28894db751252f5b8eaf2"
BINARY_URL_AMD64="https://stable-testnet-data.s3.us-east-1.amazonaws.com/stabled-latest-linux-amd64-testnet.tar.gz"
CONFIG_ZIP_URL="https://stable-testnet-data.s3.us-east-1.amazonaws.com/rpc_node_config.zip"

# P2P peers from official guide
PERSISTENT_PEERS="5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"

function install() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

  echo -e "\e[30;47m Введіть ім'я moniker (Наприклад: Oliver):\e[0m"
  echo -en ">>> "
  read -r NODE_MONIKER

  printDelimiter
  printGreen "Встановлення вузла Stable (stabled) | chain-id: ${CHAIN_ID}"
  printDelimiter

  ### 1. Download & install stabled binary
  echo ""
  printColor blue "[1/5] Завантаження та встановлення binary stabled"

  cd "$HOME" || exit 1
  rm -rf stable_bin
  mkdir -p stable_bin && cd stable_bin || exit 1

  wget -O stabled-testnet-linux-amd64.tar.gz "$BINARY_URL_AMD64"
  tar -xvzf stabled-testnet-linux-amd64.tar.gz

  chmod +x stabled
  sudo mv stabled /usr/bin/stabled

  echo ""
  printColor blue "Перевірка версії stabled"
  stabled version || {
    echo "Помилка: stabled не встановлено коректно"
    exit 1
  }

  ### 2. Init node
  echo ""
  printColor blue "[2/5] Ініціалізація вузла"

  cd "$HOME" || exit 1
  stabled config set client chain-id "$CHAIN_ID"
  stabled config set client keyring-backend test
  stabled config set client node tcp://localhost:26657

  stabled init "$NODE_MONIKER" --chain-id "$CHAIN_ID"

  ### 3. Download genesis & config
  echo ""
  printColor blue "[3/5] Завантаження genesis та базового config"

  # Backup default genesis
  if [ -f "$HOME/.stabled/config/genesis.json" ]; then
    mv "$HOME/.stabled/config/genesis.json" "$HOME/.stabled/config/genesis.json.backup"
  fi

  cd "$HOME" || exit 1
  wget -O stable_testnet_genesis.zip "$GENESIS_URL"
  unzip -o stable_testnet_genesis.zip

  if [ -f "$HOME/genesis.json" ]; then
    mv "$HOME/genesis.json" "$HOME/.stabled/config/genesis.json"
  else
    echo "Помилка: genesis.json не знайдено після розпакування"
    exit 1
  fi

  echo ""
  printColor blue "Перевірка SHA256 genesis"
  ACTUAL_SHA=$(sha256sum "$HOME/.stabled/config/genesis.json" | awk '{print $1}')
  echo "Очікуваний: $GENESIS_SHA"
  echo "Фактичний : $ACTUAL_SHA"
  if [ "$ACTUAL_SHA" != "$GENESIS_SHA" ]; then
    echo "УВАГА: SHA256 genesis не співпадає з офіційним значенням!"
  fi

  # Download optimized config.toml для RPC/validator
  cd "$HOME" || exit 1
  wget -O rpc_node_config.zip "$CONFIG_ZIP_URL"
  unzip -o rpc_node_config.zip

  if [ -f "$HOME/config.toml" ]; then
    cp "$HOME/config.toml" "$HOME/.stabled/config/config.toml"
  fi

  # Оновлення moniker в config.toml
  sed -i "s/^moniker = \".*\"/moniker = \"$NODE_MONIKER\"/" "$HOME/.stabled/config/config.toml"

  ### 4. Конфігурація p2p, RPC та JSON-RPC
  echo ""
  printColor blue "[4/5] Налаштування p2p, RPC та JSON-RPC"

  CONFIG_TOML="$HOME/.stabled/config/config.toml"
  APP_TOML="$HOME/.stabled/config/app.toml"

  # P2P: peers, pex, limits
  sed -i "/^\[p2p\]/,/^\[/{s/^max_num_inbound_peers *=.*/max_num_inbound_peers = 50/}" "$CONFIG_TOML"
  sed -i "/^\[p2p\]/,/^\[/{s/^max_num_outbound_peers *=.*/max_num_outbound_peers = 30/}" "$CONFIG_TOML"
  sed -i "/^\[p2p\]/,/^\[/{s/^persistent_peers *=.*/persistent_peers = \"$PERSISTENT_PEERS\"/}" "$CONFIG_TOML"
  sed -i "/^\[p2p\]/,/^\[/{s/^pex *=.*/pex = true/}" "$CONFIG_TOML"

  # RPC
  sed -i "/^\[rpc\]/,/^\[/{s|^laddr *=.*|laddr = \"tcp://0.0.0.0:26657\"|}" "$CONFIG_TOML"
  sed -i "/^\[rpc\]/,/^\[/{s/^max_open_connections *=.*/max_open_connections = 900/}" "$CONFIG_TOML"
  sed -i "/^\[rpc\]/,/^\[/{s|^cors_allowed_origins *=.*|cors_allowed_origins = [\"*\"]|}" "$CONFIG_TOML"

  # JSON-RPC у app.toml (EVM RPC 8545/8546)
  if [ -f "$APP_TOML" ]; then
    sed -i "/\[json-rpc\]/,/^\[/{s/^enable *=.*/enable = true/}" "$APP_TOML"
    sed -i "/\[json-rpc\]/,/^\[/{s/^address *=.*/address = \"0.0.0.0:8545\"/}" "$APP_TOML"
    sed -i "/\[json-rpc\]/,/^\[/{s/^ws-address *=.*/ws-address = \"0.0.0.0:8546\"/}" "$APP_TOML"
    sed -i "/\[json-rpc\]/,/^\[/{s/^allow-unprotected-txs *=.*/allow-unprotected-txs = true/}" "$APP_TOML"
  else
    echo "УВАГА: $APP_TOML не знайдено, JSON-RPC доведеться ввімкнути вручну."
  fi

  ### 5. Створення та запуск systemd сервісу
  echo ""
  printColor blue "[5/5] Створення systemd сервісу та запуск вузла"

  sudo tee /etc/systemd/system/stabled.service > /dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=$USER
ExecStart=$(which stabled) start --chain-id ${CHAIN_ID}
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stabled

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable stabled.service
  sudo systemctl start stabled.service

  ### Корисні команди
  echo ""
  printDelimiter
  printGreen "Вузол Stable запущено як сервіс stabled.service"
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u stabled -f -o cat"
  printGreen "Перевірити статус сервісу:        sudo systemctl status stabled"
  printGreen "Перевірити статус синхронізації:  curl -s localhost:26657/status | jq '.result.sync_info'"
  printGreen "Кількість пірів:                  curl -s localhost:26657/net_info | jq '.result.n_peers'"
  printGreen "Останній блок:                    curl -s localhost:26657/status | jq '.result.sync_info.latest_block_height'"
  printGreen "Перевірити EVM JSON-RPC (локально): curl -s http://localhost:8545"
  printDelimiter
}

install
