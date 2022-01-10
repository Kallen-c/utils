#!/bin/bash

sudo apt update && sudo apt upgrade -y

# Install packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu -y

# Install GO 1.17.2
ver="1.17.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -r celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app/
make install




cd $HOME
rm -r networks
git clone https://github.com/celestiaorg/networks.git

		echo "Enter a node name: "
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n CELESTIA_NODENAME
		echo "Enter a wallet name: "
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n CELESTIA_WALLET

CELESTIA_CHAIN="devnet-2"  # do not change

# save vars
echo 'export CELESTIA_CHAIN='$CELESTIA_CHAIN >> $HOME/.bash_profile
echo 'export CELESTIA_NODENAME='${CELESTIA_NODENAME} >> $HOME/.bash_profile
echo 'export CELESTIA_WALLET='${CELESTIA_WALLET} >> $HOME/.bash_profile
source $HOME/.bash_profile

# do init
celestia-appd init $CELESTIA_NODENAME --chain-id $CELESTIA_CHAIN

# copy devnet-2 genesis
cp $HOME/networks/devnet-2/genesis.json $HOME/.celestia-app/config/

# update seeds and peers
SEEDS="74c0c793db07edd9b9ec17b076cea1a02dca511f@46.101.28.34:26656"
PEERS="34d4bfec8998a8fac6393a14c5ae151cf6a5762f@194.163.191.41:26656"

sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.celestia-app/config/config.toml

# add external
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address = \"\"/external_address = \"$external_address:26656\"/" $HOME/.celestia-app/config/config.toml

# open rpc
sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:26657"#g' $HOME/.celestia-app/config/config.toml

# Set proper defaults
sed -i 's/timeout_commit = "5s"/timeout_commit = "15s"/g' $HOME/.celestia-app/config/config.toml
sed -i 's/index_all_keys = false/index_all_keys = true/g' $HOME/.celestia-app/config/config.toml

# open rest api
sed -i '/\[api\]/{:a;n;/enabled/s/false/true/;Ta};/\[api\]/{:a;n;/enable/s/false/true/;Ta;}' $HOME/.celestia-app/config/app.toml

celestia-appd unsafe-reset-all

# add address book
wget -O $HOME/.celestia-app/config/addrbook.json "http://62.171.191.122:8000/celestia/addrbook.json"

celestia-appd config chain-id $CELESTIA_CHAIN
celestia-appd config keyring-backend test


sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-appd.service
[Unit]
  Description=celestia-appd Cosmos daemon
  After=network-online.target
[Service]
  User=$USER
  ExecStart=$(which celestia-appd) start
  Restart=on-failure
  RestartSec=3
  LimitNOFILE=4096
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable celestia-appd
sudo systemctl daemon-reload
sudo systemctl restart celestia-appd
#journalctl -u celestia-appd.service -f


cd $HOME

celestia-appd keys add $CELESTIA_WALLET


echo " !!!! SAVE MNEMONIC FROM OUTPUT !!!! "
sleep 10


# save addr and valoper to vars
CELESTIA_ADDR=$(celestia-appd keys show $CELESTIA_WALLET -a)
echo $CELESTIA_ADDR
echo 'export CELESTIA_ADDR='${CELESTIA_ADDR} >> $HOME/.bash_profile

CELESTIA_VALOPER=$(celestia-appd keys show $CELESTIA_WALLET --bech val -a)
echo $CELESTIA_VALOPER
echo 'export CELESTIA_VALOPER='${CELESTIA_VALOPER} >> $HOME/.bash_profile
source $HOME/.bash_profile
