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
  # download binary
cd $HOME
rm -rf 0g-chain
wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.4.0/0gchaind-linux-v0.4.0
chmod +x $HOME/0gchaind
sudo mv $HOME/0gchaind $(which 0gchaind)

sudo systemctl stop 0gchaind
PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,16d33d0086c6f5d5a502e428ff3947980b00ecc6@37.27.172.60:26656,71e01e28fdf9c09dbd5229ecdf3d97c584c89385@149.50.96.112:26656,9a8da367ae4e31385cd00afe2315ea1910f50609@164.68.100.91:12656,63d519e5a5817cc6232c73b6d68e4a560ae10319@213.199.46.219:656,76cc5b9beaff9f33dc2a235e80fe2d47448463a7@95.216.114.170:26656,b396ffad15690cbc01267c3513176e7865d9cfa8@62.169.31.35:26656,d08764ae3f8c05297d905cffbf18a0d8ff93c169@37.27.127.220:16656,bad92a950179805d7962fff2edbeed9e85e0e9bb@159.69.72.177:12656,38bb09933a8f2175af407887fbb37945750ebd93@109.199.127.5:12656,13e74dd26858a94f9f87b1e2aeafcc6a5dbc3457@156.67.81.82:12656,da9ac9d516b1c2f788903b0e3ac7eb75de6eb9a1@144.91.116.117:12656,e9e76658a675aac816be5d8c2c93622bf2c0d4e8@161.97.117.185:12656,b5a3288693e5db00bf6fe46842a9cf591aa55811@37.27.134.110:51656,4e7e6e9a3bc116612644d11b43c9b32b4003bb2c@37.27.128.102:26656,0e8d6d513a37f93fa60143661c8b12ab92fe61e7@161.97.173.45:47656,a47046994182b9c1e71527dee7b3104699cc8024@184.174.32.235:12656,41cfcdd59edcd773560482e81b44bd3c5c0a15da@136.243.145.233:12656,23e96ba46f8120735e6b5646a755f32a65bf381b@146.59.118.198:29156,723cae01407afb7e1377ddacf6fc9e06e49d92eb@195.26.252.20:47656,102368751ef7abb363830bd7e48f8ada6245ab15@95.111.224.140:12656,0f25ec504b4ba0d0706338c0a4366ff44a6529e7@185.192.97.246:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchain/config/config.toml

sudo systemctl stop 0gchaind
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
rm -rf $HOME/.0gchain/data 
curl https://server-5.itrocket.net/testnet/og/og_2024-10-19_1547086_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain
mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json
sudo systemctl restart 0gchaind && sudo journalctl -u 0gchaind -f

sudo systemctl restart 0gchaind 
  echo ""
}

update
