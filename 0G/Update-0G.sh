# Бекап приватного ключа валідатора (якщо існує)
echo "💾 Створення бекапу приватного ключа..."
BACKUP_DIR="$HOME/0g_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
if [ -f "$HOME/.0gchaind/0g-home/0gchaind-home/config/priv_validator_key.json" ]; then
    cp "$HOME/.0gchaind/0g-home/0gchaind-home/config/priv_validator_key.json" "$BACKUP_DIR/"
    echo "✅ Приватний ключ збережено в $BACKUP_DIR/priv_validator_key.json"
else
    echo "ℹ️ Приватний ключ не знайдено (можливо, перше встановлення)"
fi

# Зупинка та видалення старих сервісів
echo "🛑 Зупинка старих сервісів..."
sudo systemctl stop 0gchaind 0ggeth 2>/dev/null || true
sudo systemctl disable 0gchaind 0ggeth 2>/dev/null || true

# Видалення старих файлів та директорій
echo "🗑️ Видалення старих файлів..."
rm -rf $HOME/.0gchaind
sudo rm -f /etc/systemd/system/0gchaind.service /etc/systemd/system/0ggeth.service
sudo systemctl daemon-reload

# Встановлення всіх необхідних залежностей
echo "📦 Встановлення залежностей..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential jq lz4 unzip

# install go, if needed
echo "🔧 Встановлення Go..."
cd $HOME
VER="1.21.3"
if ! command -v go &> /dev/null; then
    wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
    rm "go$VER.linux-amd64.tar.gz"
    [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
    echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
    source $HOME/.bash_profile
    [ ! -d ~/go/bin ] && mkdir -p ~/go/bin
else
    echo "✅ Go вже встановлено"
fi

# set vars
echo "🔧 Налаштування змінних..."
echo "export MONIKER=\"test\"" >> $HOME/.bash_profile
echo "export OG_PORT=\"47\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

# set binaries
echo "📥 Завантаження бінарних файлів..."
cd $HOME
rm -rf galileo galileo-v1.2.1
wget -O galileo.zip https://github.com/0glabs/0gchain-NG/releases/download/v1.2.1/galileo-v1.2.1.zip
unzip galileo.zip -d $HOME
rm -rf $HOME/galileo.zip
mv galileo-v1.2.1 galileo

# Встановлення дозволів та копіювання бінарних файлів
echo "🔧 Налаштування бінарних файлів..."
chmod +x $HOME/galileo/bin/geth
chmod +x $HOME/galileo/bin/0gchaind
cp $HOME/galileo/bin/geth $HOME/go/bin/geth
cp $HOME/galileo/bin/0gchaind $HOME/go/bin/0gchaind
mv $HOME/galileo $HOME/galileo-used

#Create and copy directory
mkdir -p $HOME/.0gchaind
cp -r $HOME/galileo-used/0g-home $HOME/.0gchaind

# initialize Geth
geth init --datadir $HOME/.0gchaind/0g-home/geth-home $HOME/galileo-used/genesis.json

# Initialize 0gchaind
0gchaind init $MONIKER --home $HOME/.0gchaind/tmp
mv $HOME/.0gchaind/tmp/data/priv_validator_state.json $HOME/.0gchaind/0g-home/0gchaind-home/data/
mv $HOME/.0gchaind/tmp/config/node_key.json $HOME/.0gchaind/0g-home/0gchaind-home/config/
mv $HOME/.0gchaind/tmp/config/priv_validator_key.json $HOME/.0gchaind/0g-home/0gchaind-home/config/
rm -rf $HOME/.0gchaind/tmp

# Set moniker in config.toml file
sed -i -e "s/^moniker *=.*/moniker = \"$MONIKER\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

# set custom ports in geth-config.toml file
sed -i "s/HTTPPort = .*/HTTPPort = ${OG_PORT}545/" $HOME/galileo-used/geth-config.toml
sed -i "s/WSPort = .*/WSPort = ${OG_PORT}546/" $HOME/galileo-used/geth-config.toml
sed -i "s/AuthPort = .*/AuthPort = ${OG_PORT}551/" $HOME/galileo-used/geth-config.toml
sed -i "s/ListenAddr = .*/ListenAddr = \":${OG_PORT}303\"/" $HOME/galileo-used/geth-config.toml
sed -i "s/^# *Port = .*/# Port = ${OG_PORT}901/" $HOME/galileo-used/geth-config.toml
sed -i "s/^# *InfluxDBEndpoint = .*/# InfluxDBEndpoint = \"http:\/\/localhost:${OG_PORT}086\"/" $HOME/galileo-used/geth-config.toml

# set seed and peers in config.toml file
PEERS=3a11d0b48d7c477d133f959efb33d47d81aeae6d@og-testnet-peer.itrocket.net:47656
SEEDS=cfa49d6db0c9065e974bfdbc9e0f55712ee2b0b9@og-testnet-seed.itrocket.net:47656
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${OG_PORT}658%g;
s%:26657%:${OG_PORT}657%g;
s%:6060%:${OG_PORT}060%g;
s%:26656%:${OG_PORT}656%g;
s%:26660%:${OG_PORT}660%g" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

# set custom ports in app.toml file
sed -i "s/address = \".*:3500\"/address = \"127\.0\.0\.1:${OG_PORT}500\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
sed -i "s/^rpc-dial-url *=.*/rpc-dial-url = \"http:\/\/localhost:${OG_PORT}551\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml

# disable indexer
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/config.toml

# configure pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.0gchaind/0g-home/0gchaind-home/config/app.toml

# Create simlink
ln -sf $HOME/.0gchaind/0g-home/0gchaind-home/config/client.toml $HOME/.0gchaind/config/client.toml

# Відновлення приватного ключа з бекапу (якщо існує)
echo "🔑 Відновлення приватного ключа..."
if [ -f "$BACKUP_DIR/priv_validator_key.json" ]; then
    cp "$BACKUP_DIR/priv_validator_key.json" "$HOME/.0gchaind/0g-home/0gchaind-home/config/"
    echo "✅ Приватний ключ відновлено з бекапу"
else
    echo "ℹ️ Бекап приватного ключа не знайдено, буде використано новий ключ"
fi

# Create 0ggeth systemd file
sudo tee /etc/systemd/system/0ggeth.service > /dev/null <<EOF
[Unit]
Description=0g Geth Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/galileo-used
ExecStart=$HOME/go/bin/geth \
    --config $HOME/galileo-used/geth-config.toml \
    --datadir $HOME/.0gchaind/0g-home/geth-home \
    --networkid 16601 \
    --http.port ${OG_PORT}545 \
    --ws.port ${OG_PORT}546 \
    --authrpc.port ${OG_PORT}551 \
    --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
    --port ${OG_PORT}303
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# enable and start 0ggeth
sudo systemctl daemon-reload
sudo systemctl enable 0ggeth
sudo systemctl restart 0ggeth

# Create 0gchaind systemd file 
sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/galileo-used
ExecStart=$(which 0gchaind) start \
--rpc.laddr tcp://0.0.0.0:${OG_PORT}657 \
--chaincfg.chain-spec devnet \
--chaincfg.kzg.trusted-setup-path $HOME/galileo-used/kzg-trusted-setup.json \
--chaincfg.engine.jwt-secret-path $HOME/galileo-used/jwt-secret.hex \
--chaincfg.kzg.implementation=crate-crypto/go-kzg-4844 \
--chaincfg.block-store-service.enabled \
--chaincfg.node-api.enabled \
--chaincfg.node-api.logging \
--chaincfg.node-api.address 0.0.0.0:${OG_PORT}500 \
--chaincfg.engine.rpc-dial-url http://localhost:${OG_PORT}551 \
--pruning=nothing \
--p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
--p2p.external_address $(wget -qO- eth0.me):${OG_PORT}656 \
--home $HOME/.0gchaind/0g-home/0gchaind-home
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# enable and start 0gchaind
sudo systemctl daemon-reload
sudo systemctl enable 0gchaind
sudo systemctl restart 0gchaind
sudo journalctl -u 0gchaind -u 0ggeth -f --no-hostname -o cat
