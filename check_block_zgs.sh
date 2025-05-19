#!/bin/bash

# Basic functions from URL
source <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/utils.sh)

clear
logo


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

echo -e "🔗 RPC: \033[1;34m$RPC_URL\033[0m"

# === Node Version ===
cd "$HOME/0g-storage-node" || exit
VERSION=$(git describe --tags --abbrev=0 2>/dev/null)
[[ -n "$VERSION" ]] && echo -e "🧩 Storage Node Version: \033[1;32m$VERSION\033[0m" || echo -e "🧩 Storage Node Version: \033[31mUnknown\033[0m"
echo

# === Monitoring Loop ===
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
        lag=""
    fi

    echo -e "📦 Local Block: \033[32m$logSyncHeight\033[0m / 🌐 Network Block: \033[33m$latestBlock\033[0m $lag | 🤝 Peers: \033[34m$connectedPeers\033[0m $extra"
    sleep 5
done
