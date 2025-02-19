#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

clear
echo ""
screen -X -S hyperliquid quit || echo "⚠️ Screen hyperliquid не знайдено"

echo ""
rm -rf ~/hl-visor ~/hl-node ~/hl ~/initial_peers.json ~/visor.json ~/non_validator_config.json ~/override_gossip_config.json
echo "✅ Всі файли ноди видалені!"

echo ""
screen -wipe || echo "✅ Немає активних screen-сесій"

echo ""
docker stop hyperliquid 2>/dev/null && docker rm hyperliquid 2>/dev/null && echo "✅ Контейнер Docker видалений!" || echo "⚠️ Контейнер Docker не знайдено"

printDelimiter
printGreen "✅ Нода Hyperliquid повністю видалена!"
printDelimiter



