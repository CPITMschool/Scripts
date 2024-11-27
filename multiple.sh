#!/bin/bash

# Ensure curl is installed
if ! command -v curl &> /dev/null; then
    sudo apt update && sudo apt install curl -y
fi

# Load utility functions
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/refs/heads/main/utils.sh)

clear
logo

# Main menu function
function main_menu {
    while true; do
        clear
        anima
        clear
        logo
        printBlue "● MULTIPLE
│    
│
│ ┌───┬──────────────────────────────────────┐
├─┤ 1 │ Install                              │
│ ├───┼──────────────────────────────────────┤
├─┤ 2 │ Status check                         │
│ ├───┼──────────────────────────────────────┤
├─┤ 3 │ Delete                               │
│ ├───┼──────────────────────────────────────┤
└─┤ 0 │ Exit                                 │
  └───┴──────────────────────────────────────┘"

        # Prompt for user input
        read -p "Select an option: " choice

        case $choice in
            1)
                printBlue "Installing Multiple..."
                sudo apt update && sudo apt upgrade -y
                ARCH=$(uname -m)
                if [[ "$ARCH" == "x86_64" ]]; then
                    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
                elif [[ "$ARCH" == "aarch64" ]]; then
                    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
                else
                    printRed "Unsupported architecture: $ARCH${NC}"
                    exit 1
                fi
                wget $CLIENT_URL -O multipleforlinux.tar
                tar -xvf multipleforlinux.tar && cd multipleforlinux
                chmod +x multiple-cli multiple-node
                sudo echo "PATH=\$PATH:$(pwd)" >> ~/.bashrc
                source ~/.bashrc
                nohup ./multiple-node > output.log 2>&1 &
                read -p "Enter your Account ID: " IDENTIFIER
                read -p "Enter your PIN: " PIN
                ./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100
                printGreen "Installation completed successfully!"
                ./multiple-cli status
                ;;
            2)
                printBlue "Checking node status..."
                cd ~/multipleforlinux && ./multiple-cli status
                ;;
            3)
                printBlue "Deleting node..."
                pkill -f multiple-node
                sudo rm -rf $HOME/multipleforlinux
                printGreen "Node deleted successfully."
                ;;
            0)
                printBlue "Exiting..."
                break
                ;;
            *)
                printRed "Invalid choice, please try again."
                ;;
        esac

        read -p "Press Enter to return to the main menu..."
    done
}

# Run the main menu
main_menu
