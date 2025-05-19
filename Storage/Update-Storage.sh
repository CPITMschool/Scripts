#!/bin/bash

function update() {
# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo


# Зупинка ноди
echo -e "\e[1;33m[1/6] Stopping Storage Node...\e[0m"
sudo systemctl stop zgs > /dev/null 2>&1 & spinner
echo -e "\e[32m✅ Node stopped successfully\e[0m"
sleep 1

# Оновлення системних пакетів
echo -e "\e[1;33m[2/6] Checking Rust and Cargo...\e[0m"
if ! command -v cargo &> /dev/null; then
    echo "🛠️  Cargo not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null 2>&1 & spinner
    export PATH="$HOME/.cargo/bin:$PATH"
    source "$HOME/.cargo/env"
    if ! command -v cargo &> /dev/null; then
        echo "❌ Cargo still not found. Please source ~/.cargo/env or restart shell."
        exit 1
    fi
else
    echo -e "\e[32m✅ Rust & Cargo already installed\e[0m"
fi
sleep 1

# Створення нового бінарного файлу
echo -e "\e[1;33m[3/6] Cloning and building binary...\e[0m"
cd "$HOME/0g-storage-node" || { echo "❌ Project directory not found."; exit 1; }
git stash > /dev/null 2>&1
git fetch --all --tags > /dev/null 2>&1
git checkout v1.0.0 > /dev/null 2>&1
git submodule update --init > /dev/null 2>&1
cargo build --release
echo -e "\e[32m✅ Build complete\e[0m"
sleep 1

# Replace config
echo -e "\e[1;33m[4/6] Updating config.toml...\e[0m"
rm -rf "$HOME/0g-storage-node/run/db" > /dev/null 2>&1
cp "$HOME/0g-storage-node/run/config.toml" "$HOME/zgs-config.toml.backup" > /dev/null 2>&1
curl -o "$HOME/0g-storage-node/run/config.toml" https://snapshots.unitynodes.app/0gchain-testnet/config-v3.toml > /dev/null 2>&1 & spinner
echo -e "\e[32m✅ Config updated\e[0m"
sleep 1

# Inject private key
echo -e "\e[1;33m[5/6] Injecting private key...\e[0m"
echo -n "🔑 Private Key: "
read PRIVATE_KEY
if [[ -z "$PRIVATE_KEY" ]]; then
    echo "❌ Private key cannot be empty. Exiting."
    exit 1
fi
sed -i "s|miner_key = \"YOUR-PRIVATE-KEY\"|miner_key = \"$PRIVATE_KEY\"|" "$HOME/0g-storage-node/run/config.toml"

echo -e "\e[32m✅ Private key injected\e[0m"


# Step 6: Recreate systemd service
echo -e "\e[1;33m[6/6] Recreating zgs.service...\e[0m"
sudo rm -f /etc/systemd/system/zgs.service

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
sudo systemctl enable zgs > /dev/null 2>&1
sudo systemctl start zgs > /dev/null 2>&1
sleep 1


# Перегляд логів
echo "-------------------------------------"
echo -e "\e[1;34m✅ Upgrade completed successfully! Node is running.\e[0m"
echo "-------------------------------------"
echo -e "\n🧾 To view logs:"
echo "  tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)"
echo -e "\n📡 To check block & peers:"
echo "  source <(curl -s https://astrostake.xyz/check_block.sh)"

}

update
