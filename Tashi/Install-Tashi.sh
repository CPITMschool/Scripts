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

  /bin/bash -c "$(curl -fsSL https://depin.tashi.network/install.sh)" -
}


### Useful commands
  printDelimiter
  printGreen "Переглянути журнал логів:         docker logs -f tashi-depin-worker"
  printGreen "Перезавантажити ноду:             docker restart tashi-depin-worker"
  printGreen "Запустити оновлення:             /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tashigg/tashi-depin-worker/refs/heads/main/install.sh)" - --update"
  
  printDelimiter


install