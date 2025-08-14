#!/bin/bash
set -e

function install() {
    # Завантажити базові функції
    source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

    clear
    logo
    printColor blue "Оновлення пакетів та встановлення залежностей"

    sudo apt update && sudo apt upgrade -y
    sudo apt install curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu cmake -y
    sudo apt install protobuf-compiler -y

    # Встановлення Go
    printColor blue "Встановлення Go"
    cd $HOME
    VER="1.21.3"
    wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
    rm "go$VER.linux-amd64.tar.gz"
    [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    source $HOME/.bash_profile
    [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

    # Встановлення Rust
    printColor blue "Встановлення Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    # Клонування і побудова бінарників
    printColor blue "Встановлення 0G Storage"
    cd $HOME
    if [ -d "0g-storage-node" ]; then
        echo "❗ Каталог 0g-storage-node вже існує. Видаліть його, щоб перевстановити."
        exit 1
    fi

    git clone https://github.com/0glabs/0g-storage-node.git
    cd 0g-storage-node
    git fetch --all --tags
    git submodule update --init
    cargo build --release

    # Налаштування змінних та конфігурація
    printColor blue "Налаштування ноди"
    read -p "Введіть любий RPC з сайту https://www.astrostake.xyz/0g-status: " BLOCKCHAIN_RPC_ENDPOINT
    
    if [[ -z "$BLOCKCHAIN_RPC_ENDPOINT" ]]; then
        echo -e "\033[31m✖ RPC не введена. Завершення.\033[0m"
        exit 1
    fi

    ENR_ADDRESS=$(wget -qO- eth0.me)
    echo "export ENR_ADDRESS=$ENR_ADDRESS" >> ~/.bashrc
    echo 'export LOG_CONTRACT_ADDRESS="0xbD75117F80b4E22698D0Cd7612d92BDb8eaff628"' >> ~/.bashrc
    echo 'export MINE_CONTRACT="0x3A0d1d67497Ad770d6f72e7f4B8F0BAbaa2A649C"' >> ~/.bashrc
    echo 'export REWARD_CONTRACT="0xd3D4D91125D76112AE256327410Dd0414Ee08Cb4"' >> ~/.bashrc
    echo 'export ZGS_LOG_SYNC_BLOCK="326165"' >> ~/.bashrc
    echo "export BLOCKCHAIN_RPC_ENDPOINT=\"$BLOCKCHAIN_RPC_ENDPOINT\"" >> ~/.bashrc
    source ~/.bashrc

    # Завантаження конфігураційного файлу
    CONFIG_PATH="$HOME/0g-storage-node/run/config-testnet-turbo.toml"
    mkdir -p $HOME/0g-storage-node/run
    if ! wget -O "$CONFIG_PATH" https://server-5.itrocket.net/testnet/og/storage/config-testnet-turbo.toml; then
        echo -e "\033[31m✖ Не вдалося завантажити config-testnet-turbo.toml\033[0m"
        exit 1
    fi

    # Оновлення конфігурації за допомогою простих команд sed
    printColor blue "Оновлення конфігураційного файлу..."
    sed -i "s@^\s*#\?\s*network_dir.*@network_dir = \"network\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_listen_address.*@network_listen_address = \"0.0.0.0\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_enr_address.*@network_enr_address = \"$ENR_ADDRESS\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_enr_tcp_port.*@network_enr_tcp_port = 1234@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_enr_udp_port.*@network_enr_udp_port = 1234@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_libp2p_port.*@network_libp2p_port = 1234@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_discovery_port.*@network_discovery_port = 1234@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_target_peers.*@network_target_peers = 100@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*rpc_listen_address.*@rpc_listen_address = \"0.0.0.0:5678\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*db_dir.*@db_dir = \"db\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*log_config_file.*@log_config_file = \"log_config\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*log_directory.*@log_directory = \"log\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_boot_nodes.*@network_boot_nodes = \[\"/ip4/47.251.117.133/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps\",\"/ip4/47.76.61.226/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX\"]@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_private.*@network_private = false@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*network_disable_discovery.*@network_disable_discovery = false@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*discv5_request_timeout_secs.*@discv5_request_timeout_secs = 10@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*discv5_query_peer_timeout_secs.*@discv5_query_peer_timeout_secs = 5@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*discv5_request_retries.*@discv5_request_retries = 3@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*log_contract_address.*@log_contract_address = \"$LOG_CONTRACT_ADDRESS\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*listen_address.*@rpc_listen_address = \"0.0.0.0:5678\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*mine_contract_address.*@mine_contract_address = \"$MINE_CONTRACT\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*reward_contract_address.*@reward_contract_address = \"$REWARD_CONTRACT\"@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*log_sync_start_block_number.*@log_sync_start_block_number = $ZGS_LOG_SYNC_BLOCK@g" "$CONFIG_PATH"
    sed -i "s@^\s*#\?\s*blockchain_rpc_endpoint.*@blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"@g" "$CONFIG_PATH"
    sed -i "s@^# \[sync\]@\[sync\]@g" "$CONFIG_PATH"
    sed -i "s@^# auto_sync_enabled = false@auto_sync_enabled = true@g" "$CONFIG_PATH"
    sed -i "s@^# find_peer_timeout = .*@find_peer_timeout = \"30s\"@g" "$CONFIG_PATH"
    
    echo -e "\033[1;33m[6/9] Введіть ваш приватний ключ:\033[0m"
    read -p "🔑 Private Key: " PRIVATE_KEY

    if [[ -z "$PRIVATE_KEY" ]]; then
        echo -e "\033[31m✖ Приватний ключ не введено. Завершення.\033[0m"
        exit 1
    fi

    sed -i "/^miner_key/c\miner_key = \"$PRIVATE_KEY\"" "$CONFIG_PATH"
    echo -e "\033[32m✔ Private key added.\033[0m\n"

    # Перевірка конфігу
    echo -e "\033[1;33m[7/9] Перевірка конфігурації...\033[0m"
    grep -E "^(miner_key|rpc_listen_address|blockchain_rpc_endpoint)" "$CONFIG_PATH" || true
    echo ""

    # Створення systemd-сервісу
    echo -e "\033[1;33m[8/9] Створення systemd-сервісу...\033[0m"
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

    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    sudo systemctl restart zgs

    printColor blue "Встановлення 0G Storage node завершено"
    echo ""
    printLine
    printColor blue "Перегляд логів:            >>> tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)"
    printColor blue "Версія ноди:               >>> $HOME/0g-storage-node/target/release/zgs_node --version"
    printColor blue "Перегляд miner key:        >>> grep '^miner_key' $CONFIG_PATH | sed 's/miner_key = \"\(.*\)\"/\1/'"
    printLine
}

install
