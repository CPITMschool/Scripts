#!/bin/bash
set -euo pipefail

# Безпечніша локаль та IFS
export LC_ALL=C
IFS=$' \t\n'

install() {
  # ===== Утиліти для форматованого виводу =====
  # якщо utils.sh недоступний, визначимо мінімальні заглушки
  if ! curl -fsSL https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh >/tmp/utils.sh 2>/dev/null; then
    printColor() { echo -e "$2"; }
    logo() { echo "=== 0G Storage Installer ==="; }
    printLine() { printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' -; }
  else
    # shellcheck disable=SC1091
    source /tmp/utils.sh
  fi

  clear
  logo
  printColor blue "Оновлення пакетів та встановлення залежностей"

  sudo apt update && sudo apt upgrade -y
  sudo apt install -y curl git wget htop tmux build-essential jq make gcc tar clang \
    pkg-config libssl-dev ncdu cmake protobuf-compiler

  # ===== Встановлення Go =====
  printColor blue "Встановлення Go"
  cd "$HOME"
  VER="1.21.3"
  wget -q "https://golang.org/dl/go${VER}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go${VER}.linux-amd64.tar.gz"
  rm -f "go${VER}.linux-amd64.tar.gz"
  # додамо PATH, якщо його ще немає
  grep -q '/usr/local/go/bin' ~/.bash_profile 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin:~/go/bin' >> ~/.bash_profile
  # застосуємо PATH в поточній сесії
  export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
  mkdir -p "$HOME/go/bin"

  # ===== Встановлення Rust =====
  printColor blue "Встановлення Rust"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"

  # ===== Клонування та збірка =====
  printColor blue "Встановлення 0G Storage"
  cd "$HOME"
  if [[ -d "0g-storage-node" ]]; then
    echo "❗ Каталог 0g-storage-node вже існує. Видаліть або перейменуйте його для перевстановлення."
    exit 1
  fi

  git clone https://github.com/0glabs/0g-storage-node.git
  cd 0g-storage-node
  git fetch --all --tags
  git submodule update --init
  cargo build --release

  # ===== Збір даних користувача =====
  printColor blue "Налаштування ноди"

  # RPC вводимо завжди з /dev/tty (навіть якщо stdin перенаправлений)
  if ! read -r -p "Введіть будь-який RPC з https://www.astrostake.xyz/0g-status: " BLOCKCHAIN_RPC_ENDPOINT < /dev/tty; then
    echo -e "\033[31m✖ Не вдалося прочитати RPC з /dev/tty. Запустіть у інтерактивному терміналі.\033[0m"
    exit 1
  fi
  BLOCKCHAIN_RPC_ENDPOINT="${BLOCKCHAIN_RPC_ENDPOINT//[[:space:]]/}"
  if [[ -z "$BLOCKCHAIN_RPC_ENDPOINT" ]]; then
    echo -e "\033[31m✖ RPC не введено. Завершення.\033[0m"
    exit 1
  fi

  ENR_ADDRESS="$(wget -qO- eth0.me || true)"
  if [[ -z "${ENR_ADDRESS}" ]]; then
    echo -e "\033[33m⚠ Не вдалося визначити ENR адресу автоматично. Вкажіть вручну у конфігу пізніше.\033[0m"
  fi

  # Миттєві змінні для sed, а також збережемо в ~/.bashrc на майбутнє
  LOG_CONTRACT_ADDRESS="0xbD75117F80b4E22698D0Cd7612d92BDb8eaff628"
  MINE_CONTRACT="0x3A0d1d67497Ad770d6f72e7f4B8F0BAbaa2A649C"
  REWARD_CONTRACT="0xd3D4D91125D76112AE256327410Dd0414Ee08Cb4"
  ZGS_LOG_SYNC_BLOCK="326165"

  {
    echo "export ENR_ADDRESS=${ENR_ADDRESS}"
    echo "export LOG_CONTRACT_ADDRESS=${LOG_CONTRACT_ADDRESS}"
    echo "export MINE_CONTRACT=${MINE_CONTRACT}"
    echo "export REWARD_CONTRACT=${REWARD_CONTRACT}"
    echo "export ZGS_LOG_SYNC_BLOCK=${ZGS_LOG_SYNC_BLOCK}"
    echo "export BLOCKCHAIN_RPC_ENDPOINT=\"${BLOCKCHAIN_RPC_ENDPOINT}\""
  } >> "$HOME/.bashrc"

  # ===== Конфіг =====
  CONFIG_PATH="$HOME/0g-storage-node/run/config-testnet-turbo.toml"
  mkdir -p "$HOME/0g-storage-node/run"
  if ! wget -q -O "$CONFIG_PATH" "https://server-5.itrocket.net/testnet/og/storage/config-testnet-turbo.toml"; then
    echo -e "\033[31m✖ Не вдалося завантажити config-testnet-turbo.toml\033[0m"
    exit 1
  fi

  printColor blue "Оновлення конфігураційного файлу…"
  sed -i "s@^\s*#\?\s*network_dir.*@network_dir = \"network\"@g"                        "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_listen_address.*@network_listen_address = \"0.0.0.0\"@g"  "$CONFIG_PATH"
  [[ -n "$ENR_ADDRESS" ]] && sed -i "s@^\s*#\?\s*network_enr_address.*@network_enr_address = \"$ENR_ADDRESS\"@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_enr_tcp_port.*@network_enr_tcp_port = 1234@g"            "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_enr_udp_port.*@network_enr_udp_port = 1234@g"            "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_libp2p_port.*@network_libp2p_port = 1234@g"              "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_discovery_port.*@network_discovery_port = 1234@g"        "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_target_peers.*@network_target_peers = 100@g"              "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*rpc_listen_address.*@rpc_listen_address = \"0.0.0.0:5678\"@g"     "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*db_dir.*@db_dir = \"db\"@g"                                        "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*log_config_file.*@log_config_file = \"log_config\"@g"              "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*log_directory.*@log_directory = \"log\"@g"                         "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_boot_nodes.*@network_boot_nodes = \[\"/ip4/47.251.117.133/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps\",\"/ip4/47.76.61.226/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX\"]@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_private.*@network_private = false@g"                      "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*network_disable_discovery.*@network_disable_discovery = false@g"  "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*discv5_request_timeout_secs.*@discv5_request_timeout_secs = 10@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*discv5_query_peer_timeout_secs.*@discv5_query_peer_timeout_secs = 5@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*discv5_request_retries.*@discv5_request_retries = 3@g"            "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*log_contract_address.*@log_contract_address = \"$LOG_CONTRACT_ADDRESS\"@g" "$CONFIG_PATH"
  # ВАЖЛИВО: приберено некоректну заміну listen_address → rpc_listen_address
  sed -i "s@^\s*#\?\s*mine_contract_address.*@mine_contract_address = \"$MINE_CONTRACT\"@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*reward_contract_address.*@reward_contract_address = \"$REWARD_CONTRACT\"@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*log_sync_start_block_number.*@log_sync_start_block_number = $ZGS_LOG_SYNC_BLOCK@g" "$CONFIG_PATH"
  sed -i "s@^\s*#\?\s*blockchain_rpc_endpoint.*@blockchain_rpc_endpoint = \"$BLOCKCHAIN_RPC_ENDPOINT\"@g" "$CONFIG_PATH"
  sed -i "s@^# \[sync\]@\[sync\]@g"                                                     "$CONFIG_PATH"
  sed -i "s@^# auto_sync_enabled = false@auto_sync_enabled = true@g"                     "$CONFIG_PATH"
  sed -i "s@^# find_peer_timeout = .*@find_peer_timeout = \"30s\"@g"                     "$CONFIG_PATH"

  # ===== Приватний ключ (читання з /dev/tty, приховано) =====
  echo -e "\033[1;33m[6/9] Введіть ваш приватний ключ:\033[0m"
  if ! read -r -s -p "🔑 Private Key: " PRIVATE_KEY < /dev/tty; then
    echo -e "\n\033[31m✖ Не вдалось прочитати з /dev/tty. Запустіть скрипт у інтерактивній консолі.\033[0m"
    exit 1
  fi
  echo
  TRIMMED_KEY="${PRIVATE_KEY//[[:space:]]/}"
  if [[ -z "$TRIMMED_KEY" ]]; then
    echo -e "\033[31m✖ Приватний ключ не введено. Завершення.\033[0m"
    exit 1
  fi

  # Запис у конфіг (створить рядок, якщо його немає)
  if grep -q '^miner_key' "$CONFIG_PATH"; then
    sed -i "/^miner_key/c\miner_key = \"$PRIVATE_KEY\"" "$CONFIG_PATH"
  else
    printf '\nminer_key = "%s"\n' "$PRIVATE_KEY" >> "$CONFIG_PATH"
  fi
  echo -e "\033[32m✔ Private key added.\033[0m\n"

  # ===== Перевірка конфігу =====
  echo -e "\033[1;33m[7/9] Перевірка конфігурації...\033[0m"
  grep -E "^(miner_key|rpc_listen_address|blockchain_rpc_endpoint)" "$CONFIG_PATH" || true
  echo ""

  # ===== systemd сервіс =====
  echo -e "\033[1;33m[8/9] Створення systemd-сервісу…\033[0m"
  sudo tee /etc/systemd/system/zgs.service >/dev/null <<EOF
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
  printColor blue "Логи:                     >>> tail -f ~/0g-storage-node/run/log/zgs.log.\$(TZ=UTC date +%Y-%m-%d)"
  printColor blue "Версія ноди:              >>> \$HOME/0g-storage-node/target/release/zgs_node --version"
  printColor blue "Перегляд miner key:       >>> grep '^miner_key' $CONFIG_PATH | sed 's/miner_key = \"\\(.*\\)\"/\\1/'"
  printLine
}

install
