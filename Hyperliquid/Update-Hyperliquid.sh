#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function update() {
clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

### Оновлення конфігурації P2P
echo ""
printGreen "[1/4] Оновлення конфігурації P2P-мережі"
echo '{"root_node_ips": [{"Ip":"13.231.52.81"}], "chain": "Testnet", "try_new_peers": true}' > override_gossip_config.json

### Завантаження нового override_gossip_config.json
echo ""
printGreen "[2/4] Завантаження актуального override_gossip_config.json"
wget meria-hyperliquid-service.s3.eu-west-3.amazonaws.com/testnet/override_gossip_config.json -O override_gossip_config.json

### Зупинка ноди
echo ""
printGreen "[3/4] Зупинка ноди (входження в screen і зупинка логів)"
screen -r hyperliquid -X quit

### Перезапуск ноди
echo ""
printGreen "[4/4] Перезапуск ноди"
screen -dmS hyperliquid ~/hl-visor run-non-validator

### Завершення оновлення
printDelimiter
printGreen "✅ Оновлення завершено!"
printGreen "Щоб перевірити логи: screen -r hyperliquid"
printGreen "Якщо потрібно зупинити логування, натисніть: Ctrl + A + D"
printDelimiter
}

update
