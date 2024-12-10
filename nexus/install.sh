#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

GREEN='\033[1;32m'

print() {
    echo -e "${GREEN}$1"
}

install_rust() {
    print "⏳ Встановлюємо Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    print "✅ Rust успішно встановлено!"
}

update_and_install_packages() {
    print "⏳ Оновлюємо список пакетів..."
    sudo apt update -y &>/dev/null
    print "✅ Список пакетів успішно оновлено."

    print "⏳ Встановлюємо необхідні пакети..."
    sudo apt install -y jq curl git build-essential pkg-config libssl-dev &>/dev/null
    print "✅ Усі необхідні пакети встановлено."
}

clone_repository() {
    REPO_DIR="$HOME/network-api"
    print "⏳ Клонуємо репозиторій Nexus-XYZ network API..."
    if [ -d "$REPO_DIR" ]; then
        print "✅ Репозиторій уже існує. Видаляємо стару версію..."
        rm -rf "$REPO_DIR"
    fi
    git clone https://github.com/cryptoforto/network-api.git "$REPO_DIR"
    print "✅ Репозиторій успішно клоновано!"
}

configure_service() {
    print "⏳ Налаштовуємо systemd-сервіс для Nexus..."
    sudo bash -c "cat > /etc/systemd/system/nexus.service" <<EOF
[Unit]
Description=Nexus Prover Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
ExecStart=$HOME/.cargo/bin/cargo run --release
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nexus.service
    sudo systemctl restart nexus.service
    print "✅ Сервіс Nexus успішно налаштовано та запущено."
}

finalize_installation() {
    print "✅ Установка завершена! Для перевірки логів використовуйте команду:"
    print "journalctl -u nexus.service -f -n 50"
}

main() {
    install_rust
    update_and_install_packages
    clone_repository
    configure_service
    finalize_installation
}

main
