#!/bin/bash

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/logo.sh)

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

finalize_installation() {
    print "⏳ Перевіряємо встановлення Nexus Prover..."
    if [ -f "$HOME/nexus_prover/nexus.sh" ]; then
        print "✅ Успішно завершено! Використовуйте Nexus Prover за допомогою команди: ./nexus.sh"
    fi
}

main() {
    update_and_install_packages
    setup_environment
    install_nexus_prover
    finalize_installation
}

main
