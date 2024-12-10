#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

GREEN='\033[1;32m'

print() {
    echo -e "${GREEN}$1"
}

update_and_install_packages() {
    print "⏳ Оновлюємо список пакетів..."
    sudo apt update -y &>/dev/null
    print "✅ Список пакетів успішно оновлено."

    print "⏳ Встановлюємо необхідні пакети..."
    sudo apt install -y jq curl git build-essential &>/dev/null
    print "✅ Усі необхідні пакети встановлено."
}

setup_environment() {
    print "⏳ Налаштовуємо середовище..."
    mkdir -p $HOME/nexus_prover
    export PATH="$HOME/nexus_prover:$PATH"
    print "✅ Середовище успішно налаштовано."
}

install_nexus_prover() {
    print "⏳ Завантажуємо Nexus Prover..."
    curl -s https://raw.githubusercontent.com/cryptoforto/nexus-prover/main/nexus.sh -o $HOME/nexus_prover/nexus.sh
    chmod +x $HOME/nexus_prover/nexus.sh
    print "✅ Nexus Prover успішно завантажено та встановлено."
}

configure_service() {
    print "⏳ Налаштовуємо systemd-сервіс для Nexus Prover..."
    sudo bash -c "cat > /etc/systemd/system/nexus.service" <<EOF
[Unit]
Description=Nexus Prover Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/nexus_prover
ExecStart=$HOME/nexus_prover/nexus.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nexus.service
    sudo systemctl start nexus.service
    print "✅ Сервіс Nexus Prover успішно налаштовано та запущено."
}

finalize_installation() {
    print "✅ Успішно завершено! Перевіряйте логи за допомогою команди:"
    print "journalctl -u nexus.service -f -n 50"
}

main() {
    update_and_install_packages
    setup_environment
    install_nexus_prover
    configure_service
    finalize_installation
}

main
