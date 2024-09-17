#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo

printColor blue "Stop node zgs" && sleep 1
sudo systemctl stop zgs

printColor blue "Setup update" && sleep 1
sudo apt-get update
sudo apt-get openssl libssl-dev pkg-config
sudo apt-get install wget lz4 aria2 pv -y

printColor blue "Backup config file" && sleep 1
mv $HOME/0g-storage-node/run/config-testnet-turbo.toml $HOME/config-testnet-turbo_backup.toml

printColor blue "Update 0G Storage"
cd $HOME/0g-storage-node
git fetch --all --tags
git checkout v0.5.0
git submodule update --init
cargo build --release

printColor blue "Download Snapshots"
cd $HOME
wget --show-progress https://snapshots-testnet.unitynodes.com/0gchain-testnet/storage_0gchain_snapshot.lz4
rm -rf $HOME/0g-storage-node/run/{db,log,network}
lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run

printColor blue "Restore backup"
mv $HOME/config-testnet-turbo_backup.toml $HOME/0g-storage-node/run/config-testnet-turbo.toml
BLOCKCHAIN_RPC_ENDPOINT="https://evm-rpc.0gchain-testnet.unitynodes.com"

sed -i "s|^blockchain_rpc_endpoint = \".*\"|blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"|" $HOME/0g-storage-node/run/config-testnet-turbo.toml

sudo systemctl restart zgs && sudo systemctl status zgs

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
