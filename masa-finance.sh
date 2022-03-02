#!/bin/bash
# Default variables
function="install"

# Options
. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs an Iron Fish node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help            show the help page"
		echo -e "  -u, --update          update the node"
		echo
		echo
		return 0 2>/dev/null; exit 0
		;;
	-u|--update)
		function="update"
		shift
		;;
	*|--)
		break
		;;
	esac
done

#Menu

PS3='Select an action: '
options=(
"Update ATP"
"Setup Masa"
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
git checkout v1.02
make all

cd $HOME/masa-node-v1.0/src/build/bin
sudo cp * /usr/local/bin

cd $HOME/masa-node-v1.0
geth --datadir data init ./network/testnet/genesis.json

tee $HOME/masad.service > /dev/null <<EOF
[Unit]
Description=MASA
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which geth) \
  --identity ${MASA_NODENAME} \
  --datadir $HOME/masa-node-v1.0/data \
  --port 30300 \
  --syncmode full \
  --verbosity 4 \
  --emitcheckpoints \
  --istanbul.blockperiod 1 \
  --mine \
  --miner.threads 1 \
  --networkid 190250 \
  --rpc --rpccorsdomain "*" --rpcvhosts "*" --rpcaddr 127.0.0.1 --rpcport 8545 \
  --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul \
  --bootnodes enode://91a3c3d5e76b0acf05d9abddee959f1bcbc7c91537d2629288a9edd7a3df90acaa46ffba0e0e5d49a20598e0960ac458d76eb8fa92a1d64938c0a3a3d60f8be4@54.158.188.182:21000,enode://571be7fe060b183037db29f8fe08e4fed6e87fbb6e7bc24bc34e562adf09e29e06067be14e8b8f0f2581966f3424325e5093daae2f6afde0b5d334c2cd104c79@142.132.135.228:21000,
enode://269ecefca0b4cd09bf959c2029b2c2caf76b34289eb6717d735ce4ca49fbafa91de8182dd701171739a8eaa5d043dcae16aee212fe5fadf9ed8fa6a24a56951c@65.108.72.177:21000
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
journalctl -u masad -f -o cat | grep "new block"
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

# Actions
sudo apt install wget jq -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
if [ -f $HOME/iron_fish_${iron_fish_wallet_name}.txt ]; then mv $HOME/iron_fish_${iron_fish_wallet_name}.txt $HOME/iron_fish_${iron_fish_wallet_name}.json; fi
$function
