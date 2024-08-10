#!/bin/bash

function install() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo
printColor blue "Install, update, package"
sudo apt update && sudo apt upgrade -y && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y && sleep 1
sudo apt -qy upgrade -y
sudo apt install jq -y

printColor blue "Remove and install Go" && sleep 1
sudo rm -rf /usr/local/go
sudo rm /etc/paths.d/go || true
sudo apt-get remove -y golang-go || true
sudo apt-get remove --auto-remove -y golang-go || true
VER="1.22.0"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=\$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

cd $HOME

printColor blue "Install, update, package"
sudo apt update && sudo apt upgrade -y

printColor blue "Install rust" && sleep 1
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

rustup default stable
rustup update
rustup update nightly
rustup target add wasm32-unknown-unknown --toolchain nightly

printColor blue "Install 0G Storage"
cd $HOME
if [ -d "0g-storage-node" ]; then
  echo "Directory 0g-storage-node already exists. Please remove it if you want to reinstall."
  exit 1
fi

git clone -b v0.4.1 https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git submodule update --init
cargo build --release
sudo cp $HOME/0g-storage-node/target/release/zgs_node /usr/local/bin
cd $HOME

printColor blue "Node Configuration"
echo ""
echo 'export NETWORK_LISTEN_ADDRESS="$(wget -qO- eth0.me)"' >> ~/.bash_profile
echo 'export BLOCKCHAIN_RPC_ENDPOINT="https://evm-rpc.0gchain-testnet.unitynodes.com"' >> ~/.bash_profile
source ~/.bash_profile
config_file="$HOME/0g-storage-node/run/config.toml"
network_height=$(curl -s https://rpc.0gchain-testnet.unitynodes.com/status | jq -r '.result.sync_info.latest_block_height')

sed -i '
s|^\s*#\s*network_dir = "network"|network_dir = "network"|
s|^\s*#\s*rpc_enabled = true|rpc_enabled = true|
s|^\s*#\s*network_listen_address = "0.0.0.0"|network_listen_address = "'"$NETWORK_LISTEN_ADDRESS"'"|
s|^\s*#\s*network_libp2p_port = 1234|network_libp2p_port = 1234|
s|^\s*#\s*network_discovery_port = 1234|network_discovery_port = 1234|
s|^\s*#\s*blockchain_rpc_endpoint = "http://127.0.0.1:8545"|blockchain_rpc_endpoint = "'"$BLOCKCHAIN_RPC_ENDPOINT"'"|
s|^\s*#\s*log_contract_address = ""|log_contract_address = "0xB7e39604f47c0e4a6Ad092a281c1A8429c2440d3"|
s|^\s*#\s*log_sync_start_block_number = 0|log_sync_start_block_number = 401178|
s|^\s*#\s*rpc_listen_address = "0.0.0.0:5678"|rpc_listen_address = "0.0.0.0:5678"|
s|^\s*#\s*mine_contract_address = ""|mine_contract_address = "0x6176AA095C47A7F79deE2ea473B77ebf50035421"|
s|^\s*#\s*miner_key = ""|miner_key = ""|
' $HOME/0g-storage-node/run/config.toml
sed -i 's/debug,hyper=info,h2=info/info,hyper=info,h2=info/g' $HOME/0g-storage-node/run/log_config

read -p "Your Private KEY: " PRIVATE_KEY
sed -i 's|^miner_key = ""|miner_key = "'"$PRIVATE_KEY"'"|' $HOME/0g-storage-node/run/config.toml


sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=0G Storage Node
After=network.target

[Service]
User=$USER
Type=simple
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

printColor blue "Start 0G Storage Node"

sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl restart zgs
sudo systemctl status zgs

echo ""
printLine
printColor blue "Переглянути логи        >>> tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) "
printColor blue 'Переглянути ваш блок    >>> curl -X POST http://localhost:5678 -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"zgs_getStatus\",\"params\":[],\"id\":1}" | jq'
printColor blue "Переглянути версію      >>> $HOME/0g-storage-node/target/release/zgs_node --version "
printColor blue "Переглянути miner key   >>> grep '^miner_key' $HOME/0g-storage-node/run/config.toml | sed 's/miner_key = "\(.*\)"/\1/' "
printLine
printLine
}
install
