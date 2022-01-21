#!/bin/bash

sudo systemctl restart massad
sleep 10
massa_buy_rolls -mb


echo "waiting 10 mins after bying rolls, dont close script..."
sleep 600
massa_wallet_info
massa_cli_client -a node_add_staking_private_keys
