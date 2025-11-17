#!/bin/bash

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

echo -e "\e[30;47m Введіть ім'я moniker(Наприклад: Oliver):\e[0m"
echo -en ">>> "
read -r NODE_MONIKER

# Шлях до бінарного файлу
STABLED_BIN="$HOME/go/bin/stabled"

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd $HOME
rm -rf bin
mkdir bin && cd bin

DOWNLOAD_FILE="stabled-latest-linux-amd64-testnet.tar.gz"
wget https://stable-testnet-data.s3.us-east-1.amazonaws.com/$DOWNLOAD_FILE
tar -xvzf $DOWNLOAD_FILE
chmod +x stabled
mv $HOME/bin/stabled $STABLED_BIN
$STABLED_BIN version
$STABLED_BIN init "$NODE_MONIKER" --chain-id stabletestnet_2201-1

### Download genesis and addrbook

# Перевірка наявності ~/.stabled/config, яку вже створила команда init
if [ ! -d "$HOME/.stabled/config" ]; then
    echo "Помилка: Не вдалося створити каталог конфігурації. Перевірте команду init."
    return
fi

# Create backup of default genesis
mv ~/.stabled/config/genesis.json ~/.stabled/config/genesis.json.backup

# Download testnet genesis
wget https://stable-testnet-data.s3.us-east-1.amazonaws.com/stable_testnet_genesis.zip
unzip stable_testnet_genesis.zip

# Move genesis to config directory
cp genesis.json ~/.stabled/config/genesis.json

# Verify genesis checksum
sha256sum ~/.stabled/config/genesis.json
# Expected: 66afbb6e57e6faf019b3021de299125cddab61d433f28894db751252f5b8eaf2

# Download optimized configuration
wget https://stable-testnet-data.s3.us-east-1.amazonaws.com/rpc_node_config.zip
# --- ВИПРАВЛЕНО: Правильна назва файлу ---
unzip rpc_node_config.zip

# Backup original config
cp ~/.stabled/config/config.toml ~/.stabled/config/config.toml.backup

# Apply new configuration
cp config.toml ~/.stabled/config/config.toml

# Update moniker in config
# --- ВИПРАВЛЕНО: Використання правильної змінної NODE_MONIKER ---
sed -i "s/^moniker = \".*\"/moniker = \"$NODE_MONIKER\"/" ~/.stabled/config/config.toml

# Set seeds and Peers
SEEDS=""
PEERS="5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.stabled/config/config.toml

FILE_APP=~/.stabled/config/app.toml
FILE_CONFIG=~/.stabled/config/config.toml

# --- Редагування app.toml ---
echo "Редагування $FILE_APP..."
# Повне додавання/заміна блоку [json-rpc]
sed -i '/^# Enable JSON-RPC for EVM compatibility/,/^allow-unprotected-txs =/d; $a\# Enable JSON-RPC for EVM compatibility\n[json-rpc]\nenable = true\naddress = "0.0.0.0:8545"\nws-address = "0.0.0.0:8546"\nallow-unprotected-txs = true' $FILE_APP

# --- Редагування config.toml ---
echo "Редагування $FILE_CONFIG..."
# P2P
sed -i 's/^max_num_inbound_peers = .*/max_num_inbound_peers = 50/' $FILE_CONFIG
sed -i 's/^max_num_outbound_peers = .*/max_num_outbound_peers = 30/' $FILE_CONFIG
# Рядок, що дублює встановлення persistent_peers, видалено, оскільки він вже був встановлений вище:
# sed -i 's/persistent_peers = ""/persistent_peers = "5ed0f977a26ccf290e184e364fb04e268ef16430@37.187.147.27:26656,128accd3e8ee379bfdf54560c21345451c7048c7@37.187.147.22:26656"/' $FILE_CONFIG
sed -i 's/^pex = .*/pex = true/' $FILE_CONFIG

# RPC
sed -i 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' $FILE_CONFIG
sed -i 's/^max_open_connections = .*/max_open_connections = 900/' $FILE_CONFIG
sed -i 's/^cors_allowed_origins = .*/cors_allowed_origins = ["*"]/' $FILE_CONFIG

echo "Редагування завершено."


### Create service
sudo tee /etc/systemd/system/stabled.service > /dev/null <<EOF
[Unit]
Description=Stable Daemon Service
After=network-online.target

[Service]
User=$USER
# --- ВИПРАВЛЕНО: Використовуємо повний шлях до бінарника ---
ExecStart=$STABLED_BIN start --chain-id stabletestnet_2201-1
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stabled

[Install]
WantedBy=multi-user.target
EOF


### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable stabled.service
sudo systemctl start stabled.service

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u stabled -f -o cat"
# --- ВИПРАВЛЕНО: Використовуємо повний шлях до бінарника ---
printGreen "Переглянути статус синхронізації: $STABLED_BIN status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}


install