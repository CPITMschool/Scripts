#!/bin/bash


source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/utils.sh)

function printDelimiter {
  echo "==========================================="
}

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function install() {

clear
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)

echo -e "\e[30;47m Please enter the node moniker:\e[0m"
echo -en ">>> "
read -r NODE_MONIKER

### Install Dependencies
source <(curl -s https://raw.githubusercontent.com/UnityNodes/scripts/main/dependencies.sh)

### Building binaries
echo ""
printColor blue "[4/6] Building binaries"

cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.15
make install

initiad config node tcp://localhost:26657
initiad config keyring-backend os
initiad config chain-id initiation-1
source $HOME/.bash_profile

initiad init "$NODE_MONIKER" --chain-id=initiation-1

### Download genesis and addrbook
curl -Ls https://snapshots.aknodes.net/snapshots/initia/genesis.json > $HOME/.initia/config/genesis.json
curl -Ls https://snapshots.aknodes.net/snapshots/initia/addrbook.json > $HOME/.initia/config/addrbook.json

### Seed,Peers config
peers="bad45b64989234450a47786a2476dbaf35126d47@149.50.108.4:27656,97cb27fae552ebe055f25b8fe10af83d337d655e@195.26.255.73:46656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:17956,fc37e22ae9405cf00a775a014366d428376e47b3@37.27.48.77:29656,0244e6fd80ee6d3880412fe26b6a2a7ef09d035b@207.244.236.250:27656,42cd9d7a33f8250ad2dbe04634e7c7c23fca6657@5.9.80.214:26656,8c7585098b9f8689f8ac455f1bb6704edf5bc3b8@65.109.58.86:25756,a63a6f6eae66b5dce57f5c568cdb0a79923a4e18@168.119.10.134:26628,d952f8524f597ec1bca7f8d634f4630ac985b87c@65.109.113.233:25756,0ade03f733d802ec391b1c53ee2bfb4710cacd8a@1.53.252.54:26656,860319cc62c2d333b07c777b123ad2376823bae9@81.0.218.54:27656,279da7b0059aa22f0d60354fdd5a0c44f482fe61@81.0.219.123:27656,94d967dd96877f2db5558bb1a919a48ddde24524@64.44.90.136:27656,917cdc7c059c5eadf2629b5a6ab90733ca37e3fa@34.142.138.228:27656,a3484833e7a92443c6745d778f401959d3744e6a@38.242.231.170:27656,f5b18fb2b9dd614021b5c018bc494e8f81ebd1ac@109.199.124.148:27656,002f1c70403e7507093c852d55c8f69214ae921e@65.108.252.205:46656"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.initia/config/config.toml

### Minimum gas price
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml

### Set pruning
sed -i \
  -e 's|^pruning *=.*|pruning = "custom"|' \
  -e 's|^pruning-keep-recent *=.*|pruning-keep-recent = "100"|' \
  -e 's|^pruning-keep-every *=.*|pruning-keep-every = "0"|' \
  -e 's|^pruning-interval *=.*|pruning-interval = "19"|' \
  $HOME/.initia/config/app.toml

### Create service
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=initiad
After=network-online.target

[Service]
User=$USER
ExecStart=$(which initiad) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable initiad

### Download snapshot
echo ""
printColor blue "[5/6] Downloading snapshot for fast synchronization" 
initiad tendermint unsafe-reset-all --home $HOME/.initia --keep-addr-book 
curl https://snapshots.aknodes.net/snapshots/initia/snapshot-initia.AKNodes.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia


### Start service and run node
echo ""
printColor blue "[6/6] Start service and run node"

sudo systemctl daemon-reload
sudo systemctl enable initiad.service
sudo systemctl start initiad.service

### Useful commands
printDelimiter
printGreen "Переглянути журнал логів:         sudo journalctl -u initiad -f -o cat"
printGreen "Переглянути статус синхронізації: initiad status | jq | grep \"catching_up\""
source $HOME/.bash_profile
printDelimiter
}
install
