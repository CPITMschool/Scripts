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


### Оновлення системи
echo ""
printGreen "[1/6] Оновлення системи"
bash <(curl -s https://raw.githubusercontent.com/asapov01/Backup/main/server-upgrade.sh)

### Встановлення Docker та Docker Compose
echo ""
printGreen "[2/6] Встановлення Docker та Docker Compose"
sudo apt-get update && sudo apt-get install -y docker.io

### Встановлення NVM та Node.js
echo ""
printGreen "[3/6] Встановлення NVM та Node.js"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install 20

### Створення гаманця
echo ""
printGreen "[4/6] Створення гаманця"
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup
cast wallet new

### Встановлення CLI
echo ""
printGreen "[5/6] Встановлення CLI та ноди"
npm install -g @hyperlane-xyz/cli
npm install -g npm@11.0.0
docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

### Створення директорії для даних ноди
mkdir -p $HOME/hyperlane_db_base && chmod -R 777 $HOME/hyperlane_db_base

echo -e "\e[30;47m Введіть ваш приватний ключ (PRIVATE_KEY):\e[0m"
echo -en ">>> "
read -r PRIVATE_KEY

echo -e "\e[30;47m Введіть ваш RPC-ключ:\e[0m"
echo -en ">>> "
read -r RPC_KEY

### Запуск ноди
echo ""
printGreen "[6/6] Запуск ноди"
docker run -d \
  -it \
  --name hyperlane \
  --mount type=bind,source=/root/hyperlane_db_base,target=/hyperlane_db_base \
  gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
  ./validator \
  --db /hyperlane_db_base \
  --originChainName base \
  --reorgPeriod 1 \
  --validator.id "$NODE_MONIKER" \
  --checkpointSyncer.type localStorage \
  --checkpointSyncer.folder base \
  --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
  --validator.key "$PRIVATE_KEY" \
  --chains.base.signer.key "$PRIVATE_KEY" \
  --chains.base.customRpcUrls "$RPC_KEY"

### Корисні команди
printDelimiter
printGreen "Переглянути лог ноди:  sudo docker logs -f hyperlane"
printGreen "Зупинити ноду:         sudo docker stop hyperlane"
printGreen "Видалити ноду:         sudo docker rm -f hyperlane"
printDelimiter
}

install
