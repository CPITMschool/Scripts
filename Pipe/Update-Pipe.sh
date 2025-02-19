#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

function update() {
clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

### Вибір методу оновлення
echo ""
printGreen "Оберіть метод оновлення:"
echo "1) Оновлення через screen"
echo "2) Оновлення через service"
echo -en ">>> "
read -r METHOD

if [[ "$METHOD" == "1" ]]; then
  ### Оновлення через screen
  printGreen "[1/6] Вхід у screen-сесію"
  screen -r pipe || echo "Screen pipe не знайдено. Можливо, нода не запущена в screen."

  printGreen "[2/6] Завантаження оновленого бінарного файлу"
  cd && mkdir -p $HOME/pipe && wget -O $HOME/pipe/pop https://dl.pipecdn.app/v0.2.8/pop && cd pipe

  printGreen "[3/6] Налаштування прав доступу"
  chmod +x pop

  printGreen "[4/6] Переміщення бінарного файлу"
  mv $HOME/pop $HOME/pipe/pop

  printGreen "[5/6] Оновлення ноди"
  cd $HOME/pipe && ./pop --refresh

  printGreen "[6/6] Перевірка версії та статусу"
  ./pop --version
  $HOME/pipe/pop --status

elif [[ "$METHOD" == "2" ]]; then
  ### Оновлення через systemd-сервіс
  printGreen "[1/7] Зупинка сервісу"
  sudo systemctl stop pipe

  printGreen "[2/7] Завантаження оновленого бінарного файлу"
  cd && mkdir -p $HOME/pipe && wget -O $HOME/pipe/pop https://dl.pipecdn.app/v0.2.8/pop && cd pipe

  printGreen "[3/7] Налаштування прав доступу"
  chmod +x pop

  printGreen "[4/7] Переміщення бінарного файлу"
  mv $HOME/pop $HOME/pipe/pop

  printGreen "[5/7] Оновлення ноди"
  cd $HOME/pipe && ./pop --refresh

  printGreen "[6/7] Запуск сервісу"
  sudo systemctl restart pipe

  printGreen "[7/7] Перевірка версії та статусу"
  ./pop --version
  $HOME/pipe/pop --status

else
  printGreen "❌ Невірний вибір. Спробуйте ще раз."
  exit 1
fi

printDelimiter
printGreen "✅ Оновлення завершено!"
printGreen "Переглянути статус: $HOME/pipe/pop --status"
printGreen "Перевірити версію:  $HOME/pipe/pop --version"
printGreen "Щоб увійти у screen: screen -r pipe"
printDelimiter
}

update
