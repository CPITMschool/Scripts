#!/bin/bash
set -e

echo "[1/7] Оновлення системи та встановлення залежностей..."
apt update && apt install -y libssl-dev ca-certificates curl nano ufw

echo "[2/7] Створення директорій і встановлення прав..."
mkdir -p /opt/popcache/logs
chown -R root:root /opt/popcache

echo "[3/7] Налаштування системних параметрів для мережі..."
cat > /etc/sysctl.d/99-popcache.conf <<EOL
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
EOL
sysctl -p /etc/sysctl.d/99-popcache.conf

echo "[4/7] Налаштування лімітів файлів..."
cat > /etc/security/limits.d/popcache.conf <<EOL
* hard nofile 65535
* soft nofile 65535
EOL

echo "[5/7] Завантаження та розпакування POP Cache Node..."
mkdir -p /opt/popcache
cd /opt/popcache
rm -rf pop pop-v0.3.0-linux-x64.tar.gz
wget https://download.pipe.network/static/pop-v0.3.0-linux-x64.tar.gz
tar -xzf pop-v0.3.0-linux-x64.tar.gz
chmod +x pop
chown -R root:root /opt/popcache
setcap 'cap_net_bind_service=+ep' /opt/popcache/pop

echo "Введіть назву POP вузла:"
read POP_NAME
echo "Введіть розташування (місто, країна):"
read POP_LOCATION
echo "Введіть invite code:"
read INVITE_CODE
echo "Введіть IP Server:"
read HOST
echo "Введіть назву ноди:"
read NODE_NAME
echo "Введіть ваше ім’я:"
read NAME
echo "Введіть email:"
read EMAIL
echo "Введіть вебсайт (або залиште порожнім):"
read WEBSITE
echo "Введіть Discord username:"
read DISCORD
echo "Введіть Telegram handle:"
read TELEGRAM
echo "Введіть Solana pubkey (адресу для винагород):"
read SOLANA_PUBKEY
echo "Введіть об’єм кешу в пам’яті (MB) (рекомендовано 4096):"
read MEMORY_CACHE_SIZE
echo "Введіть об’єм кешу на диску (GB) (рекомендовано 100):"
read DISK_CACHE_SIZE

tee /opt/popcache/config.json > /dev/null <<EOF
{
  "pop_name": "$POP_NAME",
  "pop_location": "$POP_LOCATION",
  "invite_code": "$INVITE_CODE",
  "server": {
    "host": "$HOST",
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

echo "[6/7] Створення systemd служби..."
cat > /etc/systemd/system/popcache.service <<EOL
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=root
Group=root
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
EOL

echo "[7/7] Активуємо та запускаємо службу..."
systemctl daemon-reload
systemctl enable popcache
systemctl restart popcache

echo "[8/8] Налаштування firewall..."
ufw allow 80/tcp
ufw allow 443/tcp

echo "✅ Встановлення POP Cache Node завершено!"
