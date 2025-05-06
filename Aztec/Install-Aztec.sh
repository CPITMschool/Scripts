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
printGreen "[2/6] Встановлення додаткових залежностей"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y build-essential git jq lz4 make nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev clang bsdmainutils ncdu unzip

    if ! command -v docker &>/dev/null; then
      curl -fsSL https://get.docker.com | sh
      sudo usermod -aG docker "$USER"
    fi
    sudo systemctl start docker
    sudo chmod 666 /var/run/docker.sock

    sudo iptables -I INPUT -p tcp --dport 40400 -j ACCEPT
    sudo iptables -I INPUT -p udp --dport 40400 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"

    mkdir -p "$HOME/aztec-sequencer/data" && cd "$HOME/aztec-sequencer"

    echo -e "${YELLOW}Завантажується остання версія Aztec (без ARM64)...${NC}"
    LATEST=$(curl -s "https://registry.hub.docker.com/v2/repositories/aztecprotocol/aztec/tags?page_size=100" \
      | jq -r '.results[].name' \
      | grep -E '^0\..*-alpha-testnet\.[0-9]+$' \
      | grep -v 'arm64' \
      | sort -V | tail -1)

    if [ -z "$LATEST" ]; then
      echo -e "${RED}❌ Невдалось знайти останю версію. Використовується alpha-testnet.${NC}"
      LATEST="alpha-testnet"
    fi

    echo -e "${GREEN}Використовується: $LATEST${NC}"
    docker pull aztecprotocol/aztec:"$LATEST"

    read -p "RPC Sepolia URL: " RPC_URL
    read -p "Beacon Sepolia URL: " CONS_URL
    read -p "Приватний ключ EVM: " PRIV_KEY
    read -p "Адреса гаманця: " WALLET_ADDR

    SERVER_IP=$(curl -s https://api.ipify.org)
    cat > .env <<EOF
ETHEREUM_HOSTS=$RPC_URL
L1_CONSENSUS_HOST_URLS=$CONS_URL
VALIDATOR_PRIVATE_KEY=$PRIV_KEY
P2P_IP=$SERVER_IP
WALLET=$WALLET_ADDR
EOF

    printGreen "Запускаем контейнер..."
    docker run --platform linux/amd64 -d \
      --name aztec-sequencer \
      --network host \
      --env-file "$HOME/aztec-sequencer/.env" \
      -e DATA_DIRECTORY=/data \
      -e LOG_LEVEL=debug \
      -v "$HOME/aztec-sequencer/data":/data \
      aztecprotocol/aztec:"$LATEST" \
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer'

    if [ $? -ne 0 ]; then
      echo -e "${RED}❌ Контейнер не запустився. Перевірте логи:${NC}"
      echo "docker logs aztec-sequencer"
    else
      echo -e "${GREEN}✅ Нода встановлена та запущена.${NC}"
      docker logs --tail 100 -f aztec-sequencer
    fi

    give_ack
    ;;

### Корисні команди
printDelimiter
printGreen "Переглянути логи ноди:  sudo docker logs aztec-sequencer"
printGreen "Зупинити ноду:          sudo docker stop aztec-sequencer"
printGreen "Рестарт ноди:          sudo docker restart aztec-sequencer"
printDelimiter
}

install
