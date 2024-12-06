#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo

#!/bin/bash

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
echo "Оновлення репозиторію 0g-storage-node..."
cd $HOME/0g-storage-node
git fetch --all --tags
git checkout v0.8.0
git submodule update --init

# Компіляція проекту
echo "Компіляція проекту..."
cargo build --release

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

# Оновлення файлу конфігурації
echo "Оновлення файлу конфігурації з новими вузлами та RPC-ендпоінтом..."
sed -i 's|^network_boot_nodes = .*|network_boot_nodes = ["/ip4/47.251.117.133/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/47.76.61.226/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX"]|g' $HOME/0g-storage-node/run/config-testnet-turbo.toml

BLOCKCHAIN_RPC_ENDPOINT="https://16600.rpc.thirdweb.com"
sed -i "s|^blockchain_rpc_endpoint = \".*\"|blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"|" $HOME/0g-storage-node/run/config-testnet-turbo.toml

# Перезапуск сервісу
echo "Перезапуск сервісу zgs..."
sudo systemctl restart zgs

# Перегляд логів
echo "Виведення логів сервісу zgs..."
tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)


update
