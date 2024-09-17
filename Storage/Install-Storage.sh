#!/bin/bash

function install() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo
printColor blue "Install, update, package"
sudo apt update && sudo apt upgrade -y && sleep 1
sudo apt install curl tar wget clang pkg-config protobuf-compiler libssl-dev jq build-essential protobuf-compiler bsdmainutils git make ncdu gcc git jq chrony liblz4-tool lz4 aria2 -y && sleep 1
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

cd $HOME
rm -rf 0g-storage-node
git clone https://github.com/0glabs/0g-storage-node.git
cd 0g-storage-node
git checkout v0.5.0 
cargo build --release
sudo cp $HOME/0g-storage-node/target/release/zgs_node /usr/local/bin
cd $HOME

printColor blue "Download Snapshots"
cd $HOME
wget --show-progress https://josephtran.cc/1609_storage_0gchain_snapshot.lz4
rm -rf $HOME/0g-storage-node/run/{db,log,network}
lz4 -c -d 1609_storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run


printColor blue "Node Configuration"
echo ""
ENR_ADDRESS=$(wget -qO- eth0.me)
echo "export ENR_ADDRESS=${ENR_ADDRESS}" >> ~/.bash_profile
echo 'export ZGS_LOG_DIR="$HOME/0g-storage-node/run/log"' >> ~/.bash_profile
echo 'export ZGS_LOG_SYNC_BLOCK="1033320"' >> ~/.bash_profile
echo 'export LOG_CONTRACT_ADDRESS="0xbD2C3F0E65eDF5582141C35969d66e34629cC768"' >> ~/.bash_profile
echo 'export MINE_CONTRACT="0x6815F41019255e00D6F34aAB8397a6Af5b6D806f"' >> ~/.bash_profile
echo 'export REWARD_CONTRACT="0x51998C4d486F406a788B766d93510980ae1f9360"' >> ~/.bash_profile
echo 'export BLOCKCHAIN_RPC_ENDPOINT="https://evmrpc-testnet.0g.ai"' >> ~/.bash_profile
source ~/.bash_profile

read -p "Your Private KEY: " PRIVATE_KEY
sed -i '/^# miner_key = ""/c\miner_key = "'"$PRIVATE_KEY"'"' $HOME/0g-storage-node/run/config-testnet-turbo.toml

sed -i '
s|^\s*#\?\s*network_dir\s*=.*|network_dir = "network"|
s|^\s*#\?\s*network_enr_address\s*=.*|network_enr_address = "'"$ENR_ADDRESS"'"|
s|^\s*#\?\s*network_enr_tcp_port\s*=.*|network_enr_tcp_port = 1234|
s|^\s*#\?\s*network_enr_udp_port\s*=.*|network_enr_udp_port = 1234|
s|^\s*#\?\s*network_libp2p_port\s*=.*|network_libp2p_port = 1234|
s|^\s*#\?\s*network_discovery_port\s*=.*|network_discovery_port = 1234|
s|^\s*#\s*rpc_listen_address\s*=.*|rpc_listen_address = "0.0.0.0:5678"|
s|^\s*#\?\s*rpc_enabled\s*=.*|rpc_enabled = true|
s|^\s*#\?\s*db_dir\s*=.*|db_dir = "db"|
s|^\s*#\?\s*log_config_file\s*=.*|log_config_file = "log_config"|
s|^\s*#\?\s*log_directory\s*=.*|log_directory = "log"|
s|^\s*#\?\s*network_boot_nodes\s*=.*|network_boot_nodes = \["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS","/ip4/18.162.65.205/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX"]|
s|^\s*#\?\s*log_contract_address\s*=.*|log_contract_address = "'"$LOG_CONTRACT_ADDRESS"'"|
s|^\s*#\?\s*mine_contract_address\s*=.*|mine_contract_address = "'"$MINE_CONTRACT"'"|
s|^\s*#\?\s*reward_contract_address\s*=.*|reward_contract_address = "'"$REWARD_CONTRACT"'"|
s|^\s*#\?\s*log_sync_start_block_number\s*=.*|log_sync_start_block_number = '"$ZGS_LOG_SYNC_BLOCK"'|
s|^\s*#\?\s*blockchain_rpc_endpoint\s*=.*|blockchain_rpc_endpoint = "'"$BLOCKCHAIN_RPC_ENDPOINT"'"|
s|^# \[sync\]|\[sync\]|
s|^# auto_sync_enabled = false|auto_sync_enabled = true|
s|^# find_peer_timeout = .*|find_peer_timeout = "10s"|
' $HOME/0g-storage-node/run/config-testnet-turbo.toml && \
echo -e "\033[32mNode has been configured successfully.\033[0m"

grep -E "^(miner_key|network_dir|network_enr_address|network_enr_tcp_port|network_enr_udp_port|network_libp2p_port|network_discovery_port|rpc_listen_address|rpc_enabled|db_dir|log_config_file|log_contract_address|mine_contract_address|reward_contract_address|log_sync_start_block_number|auto_sync_enabled|find_peer_timeout)" $HOME/0g-storage-node/run/config-testnet-turbo.toml

echo -e "\033[33mIf all data has been saved correctly, please confirm by pressing Y\033[0m"
read -p "[Y/N] " confirmation

sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
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
