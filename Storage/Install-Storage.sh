#!/bin/bash
set -e

function install() {
    # Завантажити базові функції
    source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

    clear
    logo
    printColor blue "Install, update, packages"

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git wget htop tmux build-essential jq make gcc tar clang pkg-config libssl-dev ncdu cmake

    # Встановлення Go
    printColor blue "Installing Go"
    cd $HOME
    VER="1.22.0"
    wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
    rm "go$VER.linux-amd64.tar.gz"

    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    source ~/.bashrc
    [ ! -d "$HOME/go/bin" ] && mkdir -p "$HOME/go/bin"
    go version

    # Встановлення Rust
    printColor blue "Installing Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env

    # Клонування і побудова ноди
    printColor blue "Installing 0G Storage"
    cd $HOME
    if [ -d "0g-storage-node" ]; then
        echo "❗ Directory 0g-storage-node already exists. Remove it to reinstall."
        exit 1
    fi

    git clone https://github.com/0glabs/0g-storage-node.git
    cd 0g-storage-node
    git checkout v1.0.0
    git submodule update --init
    cargo build --release

    # Завантаження конфігу та вставка ключа
    printColor blue "Configuring node"
    CONFIG_PATH="$HOME/0g-storage-node/run/config.toml"
    rm -f "$CONFIG_PATH"
    curl -o "$CONFIG_PATH" https://snapshots.unitynodes.app/0gchain-testnet/config-v3.toml

    echo -e "\033[1;33m[6/9] Введіть ваш приватний ключ:\033[0m"
    read -p "🔑 Private Key: " PRIVATE_KEY
    sed -i "s|miner_key = \"YOUR-PRIVATE-KEY\"|miner_key = \"$PRIVATE_KEY\"|" "$CONFIG_PATH"
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
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    sudo systemctl restart zgs

    printColor blue "Start 0G Storage node completed"
    echo ""
    printLine
    printColor blue "Перегляд логів:         >>> tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)"
    printColor blue "Версія ноди:            >>> $HOME/0g-storage-node/target/release/zgs_node --version"
    printColor blue "Перегляд miner key:     >>> grep '^miner_key' $CONFIG_PATH | sed 's/miner_key = \"\\(.*\\)\"/\\1/'"
    printLine
    printLine
}

install
