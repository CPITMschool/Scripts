#!/bin/bash

# ================================
# POP Cache Node Auto Installer
# ================================

set -e

echo "[1/8] Updating system and installing dependencies..."
sudo apt update && sudo apt install -y libssl-dev ca-certificates curl nano ufw

echo "[2/8] Creating user and directory..."
sudo useradd -m -s /bin/bash popcache || true
sudo usermod -aG sudo popcache
sudo mkdir -p /opt/popcache/logs
sudo chown -R popcache:popcache /opt/popcache

echo "[3/8] Applying system optimizations..."
sudo bash -c 'cat > /etc/sysctl.d/99-popcache.conf << EOL
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
EOL'
sudo sysctl -p /etc/sysctl.d/99-popcache.conf

echo "[4/8] Setting file limits..."
sudo bash -c 'cat > /etc/security/limits.d/popcache.conf << EOL
* hard nofile 65535
* soft nofile 65535
EOL'

echo "[5/8] Downloading binary..."
sudo mkdir -p /opt/popcache
cd /opt/popcache
sudo wget https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz
sudo tar -xzf pop-v0.3.0-linux-x64.tar.gz
sudo chmod +x pop
sudo chown -R popcache:popcache /opt/popcache

# Запит на введення значень
echo "Enter POP name:"
read POP_NAME

echo "Enter POP location (City, Country):"
read POP_LOCATION

echo "Enter node name:"
read NODE_NAME

echo "Enter your name:"
read NAME

echo "Enter your email:"
read EMAIL

echo "Enter your website (or leave blank):"
read WEBSITE

echo "Enter your Discord username:"
read DISCORD

echo "Enter your Telegram handle:"
read TELEGRAM

echo "Enter your Solana wallet address for rewards:"
read SOLANA_PUBKEY

echo "Enter memory cache size in MB (recommended 4096):"
read MEMORY_CACHE_SIZE

echo "Enter disk cache size in GB (recommended 100):"
read DISK_CACHE_SIZE

# Створення конфігурації
sudo tee /opt/popcache/config.json > /dev/null <<EOF
{
  "pop_name": "$POP_NAME",
  "pop_location": "$POP_LOCATION",
  "server": {
    "host": "0.0.0.0",
    "port": 443,
    "http_port": 80,
    "workers": 40
  },
  "cache_config": {
    "memory_cache_size_mb": $MEMORY_CACHE_SIZE,
    "disk_cache_path": "./cache",
    "disk_cache_size_gb": $DISK_CACHE_SIZE,
    "default_ttl_seconds": 86400,
    "respect_origin_headers": true,
    "max_cacheable_size_mb": 1024
  },
  "api_endpoints": {
    "base_url": "https://dataplane.pipenetwork.com"
  },
  "identity_config": {
    "node_name": "$NODE_NAME",
    "name": "$NAME",
    "email": "$EMAIL",
    "website": "$WEBSITE",
    "discord": "$DISCORD",
    "telegram": "$TELEGRAM",
    "solana_pubkey": "$SOLANA_PUBKEY"
  }
}
EOF

echo "[6/8] Creating systemd service..."
sudo bash -c 'cat > /etc/systemd/system/popcache.service << EOL
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=popcache
Group=popcache
WorkingDirectory=/opt/popcache
ExecStart=/opt/popcache/pop
Restart=always
RestartSec=5
LimitNOFILE=65535
StandardOutput=append:/opt/popcache/logs/stdout.log
StandardError=append:/opt/popcache/logs/stderr.log
Environment=POP_CONFIG_PATH=/opt/popcache/config.json

[Install]
WantedBy=multi-user.target
EOL'

echo "[7/8] Enabling and starting service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable popcache
sudo systemctl start popcache

echo "[8/8] Configuring firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "✅ POP Cache Node installation complete!"
