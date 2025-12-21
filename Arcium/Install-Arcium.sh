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

printDelimiter
printGreen "Введіть ваші дані для налаштування ноди Arcium"
printDelimiter

read -p "Введіть унікальний Node Offset (число): " NODE_OFFSET
echo 'export NODE_OFFSET='$NODE_OFFSET >> $HOME/.bash_profile

DEFAULT_IP=$(curl -s https://ipecho.net/plain)
read -p "Введіть вашу IP адресу (за замовчуванням $DEFAULT_IP): " NODE_IP
NODE_IP=${NODE_IP:-$DEFAULT_IP}
echo 'export NODE_IP='$NODE_IP >> $HOME/.bash_profile

read -p "Введіть RPC URL (Devnet): " RPC_URL
RPC_URL=${RPC_URL:-https://api.devnet.solana.com}
echo 'export RPC_URL='$RPC_URL >> $HOME/.bash_profile

source $HOME/.bash_profile

printDelimiter
echo -e "Node Offset: \e[1m\e[32m$NODE_OFFSET\e[0m"
echo -e "IP Address: \e[1m\e[32m$NODE_IP\e[0m"
echo -e "RPC URL: \e[1m\e[32m$RPC_URL\e[0m"
printDelimiter

printGreen "1. Встановлення інструментів Arcium..."
mkdir -p $HOME/arcium-node-setup && cd $HOME/arcium-node-setup
curl --proto '=https' --tlsv1.2 -sSfL https://install.arcium.com/ | bash
export PATH="$HOME/.arcium/bin:$PATH"
source ~/.bashrc
sleep 1

printGreen "2. Генерація ключів безпеки..."
solana-keygen new --outfile node-keypair.json --no-bip39-passphrase
solana-keygen new --outfile callback-kp.json --no-bip39-passphrase
openssl genpkey -algorithm Ed25519 -out identity.pem
arcium gen-bls-key bls-keypair.json
sleep 1

printGreen "3. Запит тестових токенів SOL..."
solana config set --url "$RPC_URL"
solana airdrop 2 "$(solana address --keypair node-keypair.json)" -u devnet
solana airdrop 2 "$(solana address --keypair callback-kp.json)" -u devnet
sleep 2

printGreen "4. Реєстрація ноди в мережі..."
arcium init-arx-accs \
  --keypair-path node-keypair.json \
  --callback-keypair-path callback-kp.json \
  --peer-keypair-path identity.pem \
  --bls-keypair-path bls-keypair.json \
  --node-offset "$NODE_OFFSET" \
  --ip-address "$NODE_IP" \
  --rpc-url "$RPC_URL"

printGreen "5. Створення конфігураційного файлу..."
cat <<EOF > node-config.toml
[node]
offset = $NODE_OFFSET
hardware_claim = 0
starting_epoch = 0
ending_epoch = 9223372036854775807

[network]
address = "0.0.0.0"

[solana]
endpoint_rpc = "$RPC_URL"
endpoint_wss = "${RPC_URL/http/ws}"
cluster = "Devnet"
commitment.commitment = "confirmed"
EOF

printGreen "6. Запуск Docker контейнера..."
mkdir -p arx-node-logs
docker run -d \
  --name arx-node \
  -e NODE_IDENTITY_FILE=/usr/arx-node/node-keys/node_identity.pem \
  -e NODE_KEYPAIR_FILE=/usr/arx-node/node-keys/node_keypair.json \
  -e CALLBACK_AUTHORITY_KEYPAIR_FILE=/usr/arx-node/node-keys/callback_authority_keypair.json \
  -e BLS_PRIVATE_KEY_FILE=/usr/arx-node/node-keys/bls_keypair.json \
  -v "$(pwd)/node-config.toml:/usr/arx-node/arx/node_config.toml" \
  -v "$(pwd)/node-keypair.json:/usr/arx-node/node-keys/node_keypair.json:ro" \
  -v "$(pwd)/callback-kp.json:/usr/arx-node/node-keys/callback_authority_keypair.json:ro" \
  -v "$(pwd)/identity.pem:/usr/arx-node/node-keys/node_identity.pem:ro" \
  -v "$(pwd)/bls-keypair.json:/usr/arx-node/node-keys/bls_keypair.json:ro" \
  -v "$(pwd)/arx-node-logs:/usr/arx-node/logs" \
  -p 8001:8001 \
  -p 8002:8002 \
  arcium/arx-node

printDelimiter
printGreen "Встановлення завершено успішно!"
printGreen "Переглянути логи: docker logs -f arx-node"
printGreen "Перевірити статус: arcium arx-info $NODE_OFFSET --rpc-url $RPC_URL"
printDelimiter
}

install