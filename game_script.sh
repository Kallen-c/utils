#!/bin/bash
GREEN_COLOR='\033[0;32m'
RED_COLOR='\033[0;31m'
WITHOU_COLOR='\033[0m'

DELEGATOR_ADDRESS='evmos1n853'
VALIDATOR_ADDRESS='evmosvaloper1n'
PWD='впфыпвфыпывп'
DELAY=800*2 #in secs - how often restart the script
ACC_NAME=keys #example: = ACC_NAME=wallet_qwwq_54


NODE=$(echo `cat "$HOME/.nibiru/config/config.toml" | grep -oPm1 "(?<=^laddr = \")([^%]+)(?=\")"`)

for (( ;; )); do
        echo -e "Get reward from Delegation"
        echo -e "${PWD}\ny\n" | niburud tx distribution withdraw-all-rewards --from ${ACC_NAME} --chain-id nibiru-3000 --node ${NODE} --keyring-backend file --yes
        for (( timer=5; timer>0; timer-- ))
        do
                printf "* sleep for ${RED_COLOR}%02d${WITHOUT_COLOR} sec\r" $timer
                sleep 1
        done

        BAL=$( niburud query bank balances ${DELEGATOR_ADDRESS} --chain-id evmos_9000-1  --node ${NODE} | awk '/amount:/{print $NF}' | tr -d '"')
        echo -e "BALANCE: ${GREEN_COLOR}${BAL}${WITHOU_COLOR} ugame\n"

        echo -e "Claim rewards\n"
        echo -e "${PWD}\n${PWD}\n" | niburud tx distribution withdraw-rewards ${VALIDATOR_ADDRESS} --chain-idnibiru-3000 --node ${NODE} --from ${ACC_NAME} --commission --keyring-backend file --yes
        for (( timer=5; timer>0; timer-- ))
        do
                printf "* sleep for ${RED_COLOR}%02d${WITHOU_COLOR} sec\r" $timer
                sleep 1
        done
        BAL=$( niburud query bank balances ${DELEGATOR_ADDRESS} --chain-id nibiru-3000 --node ${NODE}  | awk '/amount:/{print $NF}' | tr -d '"')
        BAL=$(($BAL-50000))
        echo -e "BALANCE: ${GREEN_COLOR}${BAL}${WITHOU_COLOR} ugame\n"
        echo -e "Stake ALL 11111\n"
        if (( BAL > 9000 )); then
          echo -e "${PWD}\n${PWD}\n" | niburud tx staking delegate ${VALIDATOR_ADDRESS} ${BAL}ugame --from=${ACC_NAME} --gas-prices 0.025ugame --chain-id nibiru-3000 --node ${NODE} --keyring-backend file --yes
        else
          echo -e "BALANCE: ${GREEN_COLOR}${BAL}${WITHOU_COLOR} ugame BAL < 9000 ((((\n"
        fi
        for (( timer=${DELAY}; timer>0; timer-- ))
        do
                printf "* sleep for ${RED_COLOR}%02d${WITHOU_COLOR} sec\r" $timer
                sleep 1
        done

done
