#!/bin/bash
# Default variables
function="install"
node="4132"
rpc="3032"

# Options
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs an Aleo client or miner node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help       show the help page"
		echo -e "  -n, --node PORT  assign the specified port to use RPC (default is ${C_LGn}${node}${RES})"
		echo -e "  -r, --rpc PORT   assign the specified port to use RPC (default is ${C_LGn}${rpc}${RES})"
		echo
		echo
		return 0 2>/dev/null; exit 0
		;;
	-n*|--node*)
		if ! grep -q "=" <<< $1; then shift; fi
		node=`option_value $1`
		shift
		;;
	-r*|--rpc*)
		if ! grep -q "=" <<< $1; then shift; fi
		rpc=`option_value $1`
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
install() {
	sudo apt update
	sudo apt upgrade -y
	sudo apt install wget jq git build-essential pkg-config libssl-dev -y
	wget -qO /usr/bin/snarkos https://raw.githubusercontent.com/Kallen-c/utils/main/snarkos
	chmod +x /usr/bin/snarkos
	if [ ! -f $HOME/account_aleo.txt ]; then
		snarkos experimental new_account > $HOME/account_aleo.txt
	fi
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n aleo_wallet_address -v `cat $HOME/account_aleo.txt | grep -oPm1 "(?<=Address  )([^%]+)(?=$)"`
	if [ ! -n "$aleo_wallet_address" ]; then
		printf_n "${C_R}There is no \$aleo_wallet_address variable! \nCheck if the contents of the file are correct:${RES} cat $HOME/account_aleo.txt"
		return 1 2>/dev/null; exit 1
	fi
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/ports_opening.sh) "$node" "$rpc"
	printf "[Unit]
Description=Aleo Miner
After=network-online.target

[Service]
User=$USER
ExecStart=`which snarkos` --miner ${aleo_wallet_address} --trial --node 0.0.0.0:${node} --rpc 0.0.0.0:${rpc}
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/aleod.service
	sudo systemctl daemon-reload
	sudo systemctl enable aleod
	sudo systemctl restart aleod
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n aleo_log -v "sudo journalctl -fn 100 -u aleod" -a
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n aleo_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/SecorD0/Aleo/main/node_info.sh) -l RU 2> /dev/null" -a
	printf_n "${C_LGn}Done!${RES}"
	printf_n "
The miner was ${C_LGn}started${RES}.
Remember to save this file: ${C_LR}$HOME/account_aleo.txt${RES}

\tv ${C_LGn}Useful commands${RES} v

To view info about the node: ${C_LGn}aleo_node_info${RES}
Page in a Checker: ${C_LGn}https://nodes.guru/aleo/aleochecker?q=`wget -qO- eth0.me`${RES}

To view the node log: ${C_LGn}aleo_log${RES}
To view the node status: ${C_LGn}sudo systemctl status aleod${RES}
To restart the node: ${C_LGn}sudo systemctl restart aleod${RES}
"
}

# Actions
sudo apt install wget -y &>/dev/null
$function
