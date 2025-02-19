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

### Встановлення screen
echo ""
printGreen "[2/6] Встановлення screen"
sudo apt install screen -y

### Перевірка системи
echo ""
printGreen "[3/6] Перевірка ресурсів та конфігурації серверу"
bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/server_status.sh)

### Завантаження файлів для синхронізації
echo ""
printGreen "[4/6] Завантаження конфігурацій та файлів ноди"
curl https://binaries.hyperliquid.xyz/Testnet/initial_peers.json > ~/initial_peers.json
echo '{"chain": "Testnet"}' > ~/visor.json
curl https://binaries.hyperliquid.xyz/Testnet/non_validator_config.json > ~/non_validator_config.json
curl https://binaries.hyperliquid.xyz/Testnet/hl-visor > ~/hl-visor && chmod a+x ~/hl-visor
echo '{"root_node_ips": [{"Ip":"13.231.52.81"}], "chain": "Testnet", "try_new_peers": true}' > ~/override_gossip_config.json
wget meria-hyperliquid-service.s3.eu-west-3.amazonaws.com/testnet/override_gossip_config.json -O ~/override_gossip_config.json

### Запуск скріну та запуск ноди
echo ""
printGreen "[5/6] Запуск ноди у screen-сесії"
screen -dmS hyperliquid ~/hl-visor run-non-validator

### Завершення встановлення
printDelimiter
printGreen "[6/6]✅ Встановлення завершено!"
printGreen "Щоб приєднатися до логів ноди, використовуйте: screen -r hyperliquid"
printGreen "Щоб відключитися від сесії без зупинки ноди, натисніть: Ctrl + A + D"
printGreen "Перевірити версію ноди: ./hl-visor --version"
printGreen "Перевірити файли ноди: ls | grep 'hl'"
printGreen "Перезапустити ноду: ~/hl-visor run-non-validator"
printDelimiter
}

install
