#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo


# Зупинка сервісу
echo "Зупинка сервісу zgs..."
sudo systemctl stop zgs

# Оновлення системних пакетів
echo "Оновлення системних пакетів..."
sudo apt-get update
sudo apt-get install -y openssl libssl-dev pkg-config

# Видалення старої бази даних
echo "Видалення старої бази даних..."
rm -rf $HOME/0g-storage-node/run/db

# Резервне копіювання файлу конфігурації
echo "Створення резервної копії файлу конфігурації..."
mv $HOME/0g-storage-node/run/config-testnet-turbo.toml $HOME/config-testnet-turbo_backup.toml

# Оновлення репозиторію
cd $HOME/0g-storage-node
git fetch --all --tags
git checkout v0.8.4
git submodule update --init
cargo build --release

# Компіляція проекту
echo "Компіляція проекту..."
cargo build --release
$HOME/0g-storage-node/target/release/zgs_node --version

# Відновлення файлу конфігурації
echo "Відновлення файлу конфігурації..."
mv $HOME/config-testnet-turbo_backup.toml $HOME/0g-storage-node/run/config-testnet-turbo.toml

# Оновлення та встановлення необхідних утиліт
echo "Встановлення необхідних утиліт..."
sudo apt-get update
sudo apt-get install -y wget lz4 aria2 pv

# Завантаження та розпаковування знімка
echo "Завантаження та розпакування знімка блокчейну..."
cd $HOME
rm -f storage_0gchain_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://josephtran.co/storage_0gchain_snapshot.lz4
rm -rf $HOME/0g-storage-node/run/db
lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run

# Перезапуск сервісу
echo "Перезапуск сервісу zgs..."
sudo systemctl restart zgs

# Перегляд логів
echo "Виведення логів сервісу zgs..."
tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)



}
update
