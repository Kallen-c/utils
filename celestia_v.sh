#!/bin/bash

celestia-appd q bank balances $CELESTIA_ADDR

# check vars
echo $CELESTIA_NODENAME $CELESTIA_CHAIN $CELESTIA_WALLET

# create validator
celestia-appd tx staking create-validator \
 --amount=1050000celes \
 --pubkey=$(celestia-appd tendermint show-validator) \
 --moniker=$CELESTIA_NODENAME \
 --chain-id=$CELESTIA_CHAIN \
 --commission-rate=0.1 \
 --commission-max-rate=0.2 \
 --commission-max-change-rate=0.01 \
 --min-self-delegation=1000000 \
 --from=$CELESTIA_WALLET

# check validator
celestia-appd q staking validator $CELESTIA_VALOPER



echo "Download and save $HOME/.celestia-app/config/priv_validator_key.json to your PC!"
sleep 5


# active set
celestia-appd q staking validators --limit=3000 -oj \
 | jq -r '.validators[] | select(.status=="BOND_STATUS_BONDED") | [(.tokens|tonumber / pow(10;6)), .description.moniker] | @csv' \
 | column -t -s"," | tr -d '"'| sort -k1 -n -r | nl
