#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

printGreen "Зупинка ноди..."
sudo systemctl stop 0gchaind 0ggeth

printGreen "Перевірка існування директорії з конфігом..."
target_dir="/root/.0gchaind/0g-home/0gchaind-home/config"
if [ ! -d "$target_dir" ]; then
  echo "Помилка: Директорія $target_dir не існує. Переконайтесь, що шлях правильний і сконфігований."
  exit 1
fi

printDelimiter
printGreen "Вставте повний вміст priv_validator_key.json і натисніть Ctrl+D:"
key_content=$(cat)

tmpfile=$(mktemp)
echo "$key_content" > "$tmpfile"

printGreen "Заміна файлу priv_validator_key.json..."
sudo mv "$tmpfile" "$target_dir/priv_validator_key.json"

printGreen "Перевірка заміни файлу:"
sudo cat "$target_dir/priv_validator_key.json"


printDelimiter
printGreen "Перевірте чи все добре, нода запуститься через 5 секунд"

sleep 5

printGreen "Запуск ноди та перегляд логів..."
sudo systemctl restart 0gchaind 0ggeth
sudo journalctl -u 0gchaind -u 0ggeth -f
