#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo

printColor blue "Stop node zgs" && sleep 1
sudo systemctl stop zgs

printColor blue "Backup config.toml" && sleep 1
cp $HOME/0g-storage-node/run/config-testnet-turbo.toml $HOME/0g-storage-node/run/config-testnet-turbo.toml.backup

printColor blue "Setup update" && sleep 1
cd $HOME/0g-storage-node
git fetch --all --tags
git checkout v0.7.3
git submodule update --init
cargo build --releas
cd $HOME
wget --show-progress https://snapshots-testnet.unitynodes.com/0gchain-testnet/storage_0gchain_snapshot.lz4
rm -rf $HOME/0g-storage-node/run/db
lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run
rm -rf $HOME/storage_0gchain_snapshot.lz4
mv $HOME/0g-storage-node/run/config-testnet-turbo.toml.backup $HOME/0g-storage-node/run/config-testnet-turbo.toml
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl restart zgs


echo ""
printLine
printColor blue "Переглянути логи        >>> tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) "
printColor blue 'Переглянути ваш блок    >>> curl -X POST http://localhost:5678 -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"zgs_getStatus\",\"params\":[],\"id\":1}" | jq'
printColor blue "Переглянути версію      >>> $HOME/0g-storage-node/target/release/zgs_node --version "
printColor blue "Переглянути miner key   >>> grep '^miner_key' $HOME/0g-storage-node/run/config.toml | sed 's/miner_key = "\(.*\)"/\1/' "
printLine
printLine
}
update
