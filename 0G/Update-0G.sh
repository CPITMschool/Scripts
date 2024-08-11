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
wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.3.1.alpha.1/0gchaind-linux-v0.3.1.alpha.1
chmod +x $HOME/0gchaind
sudo mv $HOME/0gchaind $(which 0gchaind)
sudo systemctl restart 

sudo systemctl stop 0gchaind
PEERS="e371f26305869fd8294f6e57dc01ffbbd394a5ac@156.67.80.182:26656,f8e73164ef67ec5288f663b271d320f303832b49@149.102.147.164:12656,c45a79a6e28fbee2b35b55bc2e18644fe4d20bb8@62.171.131.80:12656,7baa9325f18259079d701d649d22221232dd7a8d@116.202.51.84:26656,cd1d5fc0f6f35d0ef7d640c33b5159d84d07bd5c@161.97.110.100:12656,dbb44850914d0507e082ea81efd32662f883b222@62.169.26.33:26656,3be5290378f4ef5a5793bde6f5b7cf198f215366@65.108.200.101:26656,908a7a4f23d8a0933dbf11cbb0dbfe36e16f7d03@185.209.228.241:26646,c0cfc7c9d0cab4562e1933adf9fcc62f659f1b78@94.16.105.248:13456,a9d070c0c5900c3734a57c985f06098088b46583@213.199.32.62:12656,ecd31d198e658512967d964d8b80c1c8cc29a1d4@5.189.182.240:12656,970dd4efd48e6e09cb82ad15d133b953e3832c6f@38.242.255.168:12656,0a827d0e1966731fd8680490601f49e5e9dc7130@158.220.109.21:26656,b517215f5542d9978981d63b7b926f8d70d9c9db@62.171.167.145:12656,276186e07dd59c28306286156ce8738d357e761a@109.199.100.144:12656"
sed -i "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml
cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup

rm -rf $HOME/.0gchain/data 
curl https://server-5.itrocket.net/testnet/og/og_2024-08-11_618878_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.0gchain

mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json

sudo systemctl restart 0gchaind 
  echo ""
 
  
}

update
