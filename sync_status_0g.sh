#!/bin/bash

# Отримуємо порт RPC з конфігурації
rpc_port=$(grep -m 1 -oP '^laddr = "\K[^"]+' "$HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml" | cut -d ':' -f 3)

function print_progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local filled=$(( progress * width / total ))
  local empty=$(( width - filled ))

  printf "["
  printf "%0.s█" $(seq 1 $filled)
  printf "%0.s " $(seq 1 $empty)
  printf "] %d%%" $(( progress * 100 / total ))
}

while true; do
  local_height=$(curl -s "http://localhost:$rpc_port/status" | jq -r '.result.sync_info.latest_block_height')
  network_height=$(curl -s https://og-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height')

  # Перевірка на коректність отриманих даних
  if ! [[ "$local_height" =~ ^[0-9]+$ ]] || ! [[ "$network_height" =~ ^[0-9]+$ ]]; then
    echo -e "\e[1;31m[ERROR]\e[0m Некоректні дані про висоту блоків. Повтор...\n"
    sleep 5
    continue
  fi

  blocks_left=$((network_height - local_height))
  blocks_left=$(( blocks_left < 0 ? 0 : blocks_left ))

  # Обчислення прогресу синхронізації (0-100%)
  progress=$(( local_height * 100 / network_height ))
  progress=$(( progress > 100 ? 100 : progress ))

  # Вивід інформації з кольорами
  echo -e "\n\e[1;33m==== Стан ноди 0G RPC ====\e[0m"
  echo -e "🔷 Висота ноди:    \e[1;34m$local_height\e[0m"
  echo -e "🌐 Висота мережі:  \e[1;36m$network_height\e[0m"
  echo -e "⏳ Блоків залишилось: \e[1;31m$blocks_left\e[0m"
  echo -n "📊 Прогрес синхронізації: "
  print_progress_bar "$local_height" "$network_height"
  echo -e "\n\e[1;33m==========================\e[0m"

  sleep 5
done
