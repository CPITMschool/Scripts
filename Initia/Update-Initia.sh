 printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function install() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
  printGreen "Оновлюємо Initia"
  echo ""
  sudo systemctl stop initiad

  cd && rm -rf initia
  git clone https://github.com/initia-labs/initia
  cd initia
  git checkout v0.2.15

  make install

  sudo systemctl restart initiad
  sudo journalctl -u initiad -f --no-hostname -o cat
  printGreen "Версія вашої ноди:"
  initiad version
  echo ""
  
  printDelimiter
  printGreen "Переглянути журнал логів:         sudo journalctl -u initiad -f -o cat"
  printGreen "Переглянути статус синхронізації: initiad status 2>&1 | jq .SyncInfo"
  printGreen "В журналі логів спочатку ви можете побачити помилку Connection is closed. Але за 5-10 секунд нода розпочне синхронізацію"
  printDelimiter
}

install
