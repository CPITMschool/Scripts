#!/bin/bash

# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

# Function to print progress bar
function print_progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local filled=$(( progress * width / total ))
  local empty=$(( width - filled ))

  printf "["
  printf "%0.s█" $(seq 1 $filled)
  printf "%0.s " $(seq 1 $empty)
  printf "] %d%%" $(( progress * 100 / total ))
}

# Function to print visual information
function print_info {
  echo -e "\n\e[1;33m==== Стан ноди ====\e[0m"
  echo -e "🔷 Висота ноди:    \e[1;34m$1\e[0m"
  echo -e "🌐 Висота мережі:  \e[1;36m$2\e[0m"
  echo -e "⏳ Блоків залишилось: \e[1;31m$3\e[0m"
  echo -n "📊 Прогрес синхронізації: "
  print_progress_bar "$1" "$2"
  
  # Move RPC URL to a new line
  echo -e "\n🔗 Використовуваний RPC: \033[1;34m$RPC_URL\033[0m"
}

# === RPC Detection ===
SYSTEMD_SERVICE="/etc/systemd/system/zgs.service"
CONFIG_TOML="$HOME/0g-storage-node/run/config.toml"
DEFAULT_RPC="https://0g-testnet-rpc.astrostake.xyz"

if [[ -f "$SYSTEMD_SERVICE" ]]; then
    RPC_URL=$(grep -oP '(?<=--rpc\s)[^ ]+|(?<=--blockchain_rpc_endpoint\s)[^ ]+' "$SYSTEMD_SERVICE" | head -n 1)
fi

[[ -z "$RPC_URL" && -f "$CONFIG_TOML" ]] && \
RPC_URL=$(grep 'blockchain_rpc_endpoint' "$CONFIG_TOML" | cut -d '"' -f2)

[[ -z "$RPC_URL" ]] && {
    RPC_URL="$DEFAULT_RPC"
    echo -e "❌ RPC not found in systemd or config. Using default: \033[1;34m$RPC_URL\033[0m"
}

# Monitoring Loop
prev_block=0
prev_time=0

while true; do
    # Local node info
    LOCAL_JSON=$(curl -s -X POST http://127.0.0.1:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    logSyncHeight=$(echo "$LOCAL_JSON" | jq '.result.logSyncHeight')
    connectedPeers=$(echo "$LOCAL_JSON" | jq '.result.connectedPeers')

    [[ ! "$logSyncHeight" =~ ^[0-9]+$ ]] && logSyncHeight="N/A"
    [[ ! "$connectedPeers" =~ ^[0-9]+$ ]] && connectedPeers=0

    # Network block
    RPC_JSON=$(curl -s -m 5 -X POST "$RPC_URL" -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
    latestBlockHex=$(echo "$RPC_JSON" | jq -r '.result')
    [[ "$latestBlockHex" =~ ^0x[0-9a-fA-F]+$ ]] && latestBlock=$((16#${latestBlockHex:2})) || latestBlock="N/A"

    # Block diff & ETA
    if [[ "$logSyncHeight" =~ ^[0-9]+$ && "$latestBlock" =~ ^[0-9]+$ ]]; then
        diff=$((latestBlock - logSyncHeight))
        now=$(date +%s)
        [[ "$prev_block" =~ ^[0-9]+$ && "$prev_time" =~ ^[0-9]+$ ]] && {
            db=$((logSyncHeight - prev_block))
            dt=$((now - prev_time))
            [[ $dt -gt 0 && $db -ge 0 ]] && {
                bps=$(echo "scale=2; $db / $dt" | bc)
                eta=$(echo "scale=0; $diff / $bps" | bc 2>/dev/null)
                if (( eta < 60 )); then eta_disp="$eta sec"
                elif (( eta < 3600 )); then eta_disp="$((eta / 60)) min"
                elif (( eta < 86400 )); then eta_disp="$((eta / 3600)) hr"
                else eta_disp="$((eta / 86400)) day(s)"
                fi
                extra="| Speed: ${bps} blk/s | ETA: $eta_disp"
            }
        }
        prev_block=$logSyncHeight
        prev_time=$now

        # Color by lag
        if (( diff <= 5 )); then color="\033[32m"
        elif (( diff <= 20 )); then color="\033[33m"
        else color="\033[31m"
        fi
        lag="(${color}Behind $diff\033[0m)"
    else
        lag="No data"
        extra=""
    fi

    # Display information
    print_info "$logSyncHeight" "$latestBlock" "$diff"
    echo -e "🤝 Connected Peers: \033[1;34m$connectedPeers\033[0m | Speed: \033[1;34m$bps blk/s\033[0m | ETA: \033[1;34m$eta_disp\033[0m"
    echo -e "\e[1;33m===================\e[0m"


    sleep 5
done
