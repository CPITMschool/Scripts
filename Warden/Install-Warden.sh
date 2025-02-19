#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

function install() {
clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

echo -e "\e[30;47m Введіть ім'я moniker(Наприклад: Oliver):\e[0m"
echo -en ">>> "
read -r NODE_MONIKER

### Install Dependencies

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd $HOME
rm -rf bin
mkdir bin && cd bin
wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.5.4/wardend_Linux_x86_64.zip
unzip wardend_Linux_x86_64.zip
chmod +x wardend
mv $HOME/bin/wardend $HOME/go/bin

wardend config set client chain-id buenavista-1
wardend config set client keyring-backend test
wardend config set client node tcp://localhost:26657
source $HOME/.bash_profile

wardend init "$NODE_MONIKER" --chain-id buenavista-1

### Download genesis and addrbook
wget -O $HOME/.warden/config/genesis.json https://server-4.itrocket.net/testnet/warden/genesis.json
wget -O $HOME/.warden/config/addrbook.json  https://server-4.itrocket.net/testnet/warden/addrbook.json

# Set seeds and Peers
SEEDS="8288657cb2ba075f600911685670517d18f54f3b@warden-testnet-seed.itrocket.net:18656"
PEERS="b14f35c07c1b2e58c4a1c1727c89a5933739eeea@warden-testnet-peer.itrocket.net:18656,271f42834c69804887e887a3672105850cc8f1d3@135.181.215.60:12656,00c0b45d650def885fcbcc0f86ca515eceede537@152.53.18.245:19656,cd62842978a2a35207d6790494d69916a0f539f6@144.76.70.103:13656,1351dc805a024c762ba913fbb1c74839924bf40c@185.16.38.165:18656,42f57439739621cccdece7d92bf15a653471c0b7@163.172.64.81:26656,2d2c7af1c2d28408f437aef3d034087f40b85401@52.51.132.79:26656,29dfeed0f7933111c5452a1af4ca67b2fe4346f5@198.27.80.53:26656,2f99ac7e72cc8c1f951e027d6088b8a920163237@65.109.111.234:18656,de9e8c44039e240ff31cbf976a0d4d673d4e4734@188.165.213.192:26656,aabe02676fbc59f29a12ed5dc73468abd9caa05f@89.117.58.62:18656,208b9d568c787d9be1dfd4a6de663c852424f8f4@91.227.33.18:18656,a6889db081dd21407b0f4c5fc2f6816295a905ff@100.42.177.205:26656,9a08ee57be6a0a603d9c1f388c502a1838eca6d5@45.159.230.250:656,5c6e4b58ffdf77c4052419dd661ad76db276e992@2.58.82.159:11956,33afcd959a69de3f613955b383a6935846670a69@135.181.228.89:19656,8405984f8a96676bce6f45fee80ca65e42ae6511@65.109.69.117:10656,954ff2f073e8c1db596da47230a8904f480b2f16@65.108.100.31:11856,6262357abf6ebdf4ab4d68cd0452f06f2542c5b1@192.99.16.192:26656,d5126141e065986f97e568c360b7b517ed2dc52a@5.75.159.246:26656,fa924f15269701ca13f88046b97c56b3de26e173@46.4.94.60:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.warden/config/config.toml

# Config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.warden/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.warden/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.warden/config/app.toml

# Set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "25000000award"|g' $HOME/.warden/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.warden/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.warden/config/config.toml


### Create service
sudo tee /etc/systemd/system/wardend.service > /dev/null <<EOF
[Unit]
Description=Warden node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.warden
ExecStart=$(which wardend) start --home $HOME/.warden
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

### Download snapshot
echo ""
printColor blue "[5/6] Downloading snapshot for fast synchronization" 
wardend tendermint unsafe-reset-all --home $HOME/.warden
if curl -s --head curl https://server-4.itrocket.net/testnet/warden/warden_2025-02-18_1757147_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-4.itrocket.net/testnet/warden/warden_2025-02-18_1757147_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.warden
    else
  echo "no snapshot found"
fi

### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable wardend.service
sudo systemctl start wardend.service

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u wardend -f -o cat"
printGreen "Переглянути статус синхронізації: wardend status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}

install
