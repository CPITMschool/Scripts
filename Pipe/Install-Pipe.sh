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

### Вибір методу встановлення
echo ""
printGreen "Оберіть метод встановлення:"
echo "1) Встановлення через service"
echo "2) Встановлення через screen"
echo -en ">>> "
read -r METHOD

### Запит параметрів
echo ""
printGreen "Введіть значення для налаштувань ноди:"
echo -en "Виділена RAM (GB) [4]: "
read -r RAM
RAM=${RAM:-4}

echo -en "Максимальний розмір диску (GB) [100]: "
read -r MAX_DISK
MAX_DISK=${MAX_DISK:-100}

echo -en "Введіть ваш Solana публічний ключ: "
read -r PUBKEY

if [[ "$METHOD" == "1" ]]; then
  printGreen "[1/6] Оновлення системи"
  bash <(curl -s https://raw.githubusercontent.com/asapov01/Backup/main/server-upgrade.sh)

  printGreen "[2/6] Завантаження бінарного файлу"
  cd && mkdir -p $HOME/pipe && wget -O $HOME/pipe/pop https://dl.pipecdn.app/v0.2.8/pop && cd pipe

  printGreen "[3/6] Налаштування прав доступу"
  chmod +x pop

  printGreen "[4/6] Створення кеш-папки"
  sudo mkdir -p $HOME/pipe/download_cache

  printGreen "[5/6] Створення systemd-сервісу"
  sudo tee /etc/systemd/system/pipe.service > /dev/null << EOF
[Unit]
Description=Pipe Node Service
After=network.target
Wants=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/pipe
ExecStart=$HOME/pipe/pop --ram $RAM --max-disk $MAX_DISK --cache-dir $HOME/pipe/download_cache --pubKey $PUBKEY
RestartSec=3600
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=pipe-node

[Install]
WantedBy=multi-user.target
EOF

  printGreen "[6/6] Запуск сервісу"
  sudo systemctl daemon-reload
  sudo systemctl restart pipe
  sudo systemctl enable pipe

elif [[ "$METHOD" == "2" ]]; then
  printGreen "[1/6] Оновлення системи"
  bash <(curl -s https://raw.githubusercontent.com/asapov01/Backup/main/server-upgrade.sh)

  printGreen "[2/6] Завантаження бінарного файлу"
  cd && mkdir -p $HOME/pipe && wget -O $HOME/pipe/pop https://dl.pipecdn.app/v0.2.8/pop && cd pipe

  printGreen "[3/6] Налаштування прав доступу"
  chmod +x pop

  printGreen "[4/6] Створення кеш-папки"
  sudo mkdir -p $HOME/pipe/download_cache

  printGreen "[5/6] Запуск у screen-сесії"
  screen -dmS pipe $HOME/pipe/pop --ram $RAM --max-disk $MAX_DISK --cache-dir $HOME/pipe/download_cache --pubKey $PUBKEY

else
  printGreen "❌ Невірний вибір. Спробуйте ще раз."
  exit 1
fi

printDelimiter
printGreen "✅ Встановлення завершено!"
printGreen "Переглянути статус: $HOME/pipe/pop --status"
printGreen "Перевірити версію:  $HOME/pipe/pop --version"
if [[ "$METHOD" == "1" ]]; then
  printGreen "Перезапустити сервіс: sudo systemctl restart pipe"
  printGreen "Переглянути логи сервісу: sudo journalctl -u pipe -f"
else
  printGreen "Приєднатися до screen: screen -r pipe"
  printGreen "Від'єднатися від screen: Ctrl + A + D"
fi
printDelimiter
}

install
