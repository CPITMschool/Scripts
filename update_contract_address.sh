#!/bin/bash

# Detect config file
if [ -f "$HOME/0g-storage-node/run/config.toml" ]; then
  CONFIG_FILE="$HOME/0g-storage-node/run/config.toml"
elif [ -f "$HOME/0g-storage-node/run/config-testnet-turbo.toml" ]; then
  CONFIG_FILE="$HOME/0g-storage-node/run/config-testnet-turbo.toml"
else
  echo "No config file found (config.toml or config-testnet-turbo.toml)."
  exit 1
fi

echo "Editing config file: $CONFIG_FILE"

# Define new contract addresses and block number
LOG_CONTRACT="0xbD75117F80b4E22698D0Cd7612d92BDb8eaff628"
LOG_BLOCK=326165
MINE_CONTRACT="0x3A0d1d67497Ad770d6f72e7f4B8F0BAbaa2A649C"
REWARD_CONTRACT="0xd3D4D91125D76112AE256327410Dd0414Ee08Cb4"

# Backup original config
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"


#Remove the db dir and stop the service 

sudo systemctl stop zgs
rm -rf $HOME/0g-storage-node/run/db


# Update values using sed
sed -i "s/^log_contract_address = \".*\"/log_contract_address = \"$LOG_CONTRACT\"/" "$CONFIG_FILE"
sed -i "s/^log_sync_start_block_number = .*/log_sync_start_block_number = $LOG_BLOCK/" "$CONFIG_FILE"
sed -i "s/^mine_contract_address = \".*\"/mine_contract_address = \"$MINE_CONTRACT\"/" "$CONFIG_FILE"
sed -i "s/^reward_contract_address = \".*\"/reward_contract_address = \"$REWARD_CONTRACT\"/" "$CONFIG_FILE"

echo "Contract addresses and start block updated successfully."

# Restart the service 


sudo systemctl restart zgs 