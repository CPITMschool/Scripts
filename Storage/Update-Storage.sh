#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo

#!/bin/bash

set -e

# Зупиняємо ноду та оновлюємо залежності
echo "Зупиняємо ноду та оновлюємо залежності..."
sudo systemctl stop zgs
sudo apt-get update
sudo apt-get install -y openssl libssl-dev pkg-config

# Видаляємо старі дані і робимо бекап конфіг файлу
echo "Видаляємо старі дані і робимо бекап конфіг файлу..."
cd $HOME
rm -rf $HOME/0g-storage-node/run/db
mv $HOME/0g-storage-node/run/config-testnet-turbo.toml $HOME/config-testnet-turbo_backup.toml

# Клонуємо і створюємо новий бінарний файл
echo "Клонуємо і створюємо новий бінарний файл..."
cd $HOME/0g-storage-node
git fetch --all --tags
git checkout v0.7.3
git submodule update --init
cargo build --release

# Відновлюємо конфіг файл
echo "Відновлюємо конфіг файл..."
mv $HOME/config-testnet-turbo_backup.toml $HOME/0g-storage-node/run/config-testnet-turbo.toml

# Рестартимо ноду
echo "Рестартимо ноду..."
sudo systemctl restart zgs && sudo systemctl status zgs

# Перевіряємо версію сторедж ноди
echo "Перевіряємо версію сторедж ноди..."
cd $HOME/0g-storage-node
git log --decorate=short --oneline | grep "tag: v" | head -n 1
git log -1 --pretty=oneline

# Встановлюємо снепшот для сторедж ноди
echo "Встановлюємо снепшот для сторедж ноди..."
sudo systemctl stop zgs
sudo apt-get update
sudo apt-get install -y wget lz4 aria2 pv

# Завантажуємо дані Сторедж ноди
echo "Завантажуємо дані Сторедж ноди..."
cd $HOME
rm -f storage_0gchain_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://josephtran.co/storage_0gchain_snapshot.lz4

# Завантажуємо додаткові дані для Сторедж ноди
echo "Розпаковуємо дані Сторедж ноди..."
rm -rf $HOME/0g-storage-node/run/db
lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run

# Рестартимо ноду
echo "Рестартимо ноду..."
sudo systemctl restart zgs && sudo systemctl status zgs

# Міняємо RPC
echo "Міняємо RPC..."
BLOCKCHAIN_RPC_ENDPOINT="https://rpc.ankr.com/0g_newton"
sed -i "s|^blockchain_rpc_endpoint = \".*\"|blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"|" $HOME/0g-storage-node/run/config-testnet-turbo.toml

sudo systemctl restart zgs
tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) &

# Перевірка блоків синхронізації та пірів
echo "Очікуємо синхронізації блоків та підключення пірів..."
while true; do
    response=$(curl -s -X POST http://localhost:5678 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    
    logSyncHeight=$(jq -r '.result.logSyncHeight' <<< "$response")
    connectedPeers=$(jq -r '.result.connectedPeers' <<< "$response")
    
    echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m"
    sleep 5
done
}
update
