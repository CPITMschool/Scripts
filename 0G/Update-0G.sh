#!/bin/bash

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function update() {
  clear
  source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
  printGreen "Оновлюємо 0G"
# stop 0gchaind and 0ggeth
sudo systemctl stop 0gchaind 0ggeth

# download binaries
cd $HOME
rm -rf galileo-v1.2.0
wget -O galileo.tar.gz https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz
tar -xzvf galileo.tar.gz -C $HOME
rm -rf $HOME/galileo.tar.gz
chmod +x $HOME/galileo-v1.2.0/bin/geth
chmod +x $HOME/galileo-v1.2.0/bin/0gchaind
mv $HOME/galileo-v1.2.0/bin/geth $HOME/go/bin/geth

# create service file
sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/galileo-used
ExecStart=$(which 0gchaind) start \
 --chaincfg.chain-spec devnet \
 --chaincfg.kzg.trusted-setup-path=$HOME/galileo-used/kzg-trusted-setup.json \
 --chaincfg.engine.jwt-secret-path=$HOME/galileo-used/jwt-secret.hex \
 --chaincfg.kzg.implementation=crate-crypto/go-kzg-4844 \
 --chaincfg.engine.rpc-dial-url=http://localhost:${OG_PORT}551 \
--chaincfg.node-api.address 127.0.0.1:${OG_PORT}500 \
 --p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
 --p2p.external_address $(wget -qO- eth0.me):${OG_PORT}656 \
 --home $HOME/.0gchaind/0g-home/0gchaind-home 
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# update and start 
sudo systemctl daemon-reload
sudo systemctl restart 0ggeth
sleep 5
sudo mv $HOME/galileo-v1.2.0/bin/0gchaind $(which 0gchaind)
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -f
}

update
