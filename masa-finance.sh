#!/bin/bash

while true
do

#Logo

curl -s https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh | bash

#Menu

PS3='Select an action: '
options=(
"Update ATP"
"Setup Masa"
"Update Masa"
"Chek log"
"Exit")
select opt in "${options[@]}"
do
case $opt in

# ATP

"Update ATP")
echo "============================================================"
echo "ATP update started"
echo "============================================================"
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git make ncdu net-tools -y

ver="1.17.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version
echo "============================================================"
echo "ATP updated"
echo "============================================================"
break
;;

#Instal

"Setup Masa")

echo "============================================================"
echo "Setup NodeName:"
echo "============================================================"
read MASA_NODENAME
echo 'export MASA_NODENAME='${MASA_NODENAME} >> $HOME/.bash_profile
source ~/.bash_profile

echo "============================================================"
echo "Node installation started"
echo "============================================================"
cd $HOME
rm -rf masa-node-v1.0
git clone https://github.com/masa-finance/masa-node-v1.0

cd masa-node-v1.0/src
git checkout v1.03
make all

cd $HOME/masa-node-v1.0/src/build/bin
sudo cp * /usr/local/bin

cd $HOME/masa-node-v1.0
geth --datadir data init ./network/testnet/genesis.json

tee $HOME/masad.service > /dev/null <<EOF
[Unit]
Description=MASA103
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which geth) \
  --identity ${MASA_NODENAME} \
  --datadir $HOME/masa-node-v1.0/data \
  --port 30300 \
  --syncmode full \
  --verbosity 5 \
  --emitcheckpoints \
  --istanbul.blockperiod 10 \
  --mine \
  --miner.threads 1 \
  --networkid 190260 \
  --http --http.corsdomain "*" --http.vhosts "*" --http.addr 127.0.0.1 --http.port 8545 \
  --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul \
  --maxpeers 50 \
  --bootnodes enode://91a3c3d5e76b0acf05d9abddee959f1bcbc7c91537d2629288a9edd7a3df90acaa46ffba0e0e5d49a20598e0960ac458d76eb8fa92a1d64938c0a3a3d60f8be4@54.158.188.182:21000
Restart=on-failure
RestartSec=10
LimitNOFILE=4096
Environment="PRIVATE_CONFIG=ignore"
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/masad.service /etc/systemd/system

sudo systemctl daemon-reload
sudo systemctl enable masad
sudo systemctl restart masad

echo "============================================================"
echo "Checking the logs"
echo "============================================================"
journalctl -u masad -f -o cat
echo "============================================================"
echo "If there are no errors in the logs, congratulations, the node is
installed. If you have any doubts - send screenshots to our support chat"
echo "============================================================"
break
;;

"Update Masa")

echo "============================================================"
echo "Setup NodeName:"
echo "============================================================"
read MASA_NODENAME
echo 'export MASA_NODENAME='${MASA_NODENAME} >> $HOME/.bash_profile
source ~/.bash_profile

echo "============================================================"
echo "Node update started"
echo "============================================================"
sudo systemctl stop masad && cd $HOME/masa-node-v1.0 && geth removedb --datadir data

cp data/geth/nodekey $HOME
rm -r data

git pull
cd $HOME/masa-node-v1.0/src
git checkout v1.03
make all

cd $HOME/masa-node-v1.0/src/build/bin
sudo cp * /usr/local/bin

cd $HOME/masa-node-v1.0
geth --datadir data init ./network/testnet/genesis.json

cp $HOME/nodekey data/geth/

tee $HOME/masad.service > /dev/null <<EOF
[Unit]
Description=MASA103
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which geth) \
  --identity ${MASA_NODENAME} \
  --datadir $HOME/masa-node-v1.0/data \
  --port 30300 \
  --syncmode full \
  --verbosity 5 \
  --emitcheckpoints \
  --istanbul.blockperiod 10 \
  --mine \
  --miner.threads 1 \
  --networkid 190260 \
  --http --http.corsdomain "*" --http.vhosts "*" --http.addr 127.0.0.1 --http.port 8545 \
  --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul \
  --maxpeers 50 \
  --bootnodes enode://91a3c3d5e76b0acf05d9abddee959f1bcbc7c91537d2629288a9edd7a3df90acaa46ffba0e0e5d49a20598e0960ac458d76eb8fa92a1d64938c0a3a3d60f8be4@54.158.188.182:21000
Restart=on-failure
RestartSec=10
LimitNOFILE=4096
Environment="PRIVATE_CONFIG=ignore"
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/masad.service /etc/systemd/system

sudo systemctl daemon-reload
sudo systemctl enable masad
sudo systemctl start masad

echo "============================================================"
echo "Checking the logs"
echo "============================================================"
journalctl -u masad -f -o cat
echo "============================================================"
echo "If there are no errors in the logs, congratulations, the node is
installed. If you have any doubts - send screenshots to our support chat"
echo "============================================================"
break
;;

"Chek log")

echo "============================================================"
echo "Checking the logs"
echo "============================================================"
journalctl -u masad -f -o cat
echo "============================================================"
echo "If there are no errors in the logs, congratulations, the node is
installed. If you have any doubts - send screenshots to our support chat"
echo "============================================================"
break
;;

#Exit

"Exit")
exit
            ;;
*) echo "invalid option $REPLY";;
esac
done
done
