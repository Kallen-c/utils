#!/bin/bash
# Default variables
function="install"
node="4132"
rpc="3032"

# Options
. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs an Aleo client or miner node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help       show the help page"
		echo -e "  -n, --node PORT  assign the specified port to use RPC (default is ${C_LGn}${node}${RES})"
		echo -e "  -r, --rpc PORT   assign the specified port to use RPC (default is ${C_LGn}${rpc}${RES})"
		echo -e "  -u, --update     update the node"
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
	-u|--update)
		function="update"
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
	sudo apt install tmux wget jq git build-essential pkg-config libssl-dev -y
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/installers/rust.sh)
	git clone https://github.com/AleoHQ/snarkOS.git --depth 1
	cd snarkOS
	cargo build --release
	mv $HOME/snarkOS/target/release/snarkos /usr/bin
	cd
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
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/miscellaneous/insert_variable.sh) -n aleo_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/aleo_ni.sh) -l RU 2> /dev/null" -a
	printf_n "${C_LGn}Done!${RES}"
	. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
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
update() {
	if [ -f /etc/systemd/system/aleod.service ]; then
		local service_file="aleod.service"
	elif [ -f /etc/systemd/system/aleod-miner.service ]; then
		local service_file="aleod-miner.service"
	else
		printf_n "${C_R}Change the name of the service file to ${C_LGn}aleod.service${RES}"
		return 1 2>/dev/null; exit 1
	fi
	if [ ! -d $HOME/snarkOS ]; then
		printf_n "${C_LGn}Building binary...${RES}"
		sudo systemctl stop "$service_file"
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/installers/rust.sh)
		/usr/bin/git clone https://github.com/AleoHQ/snarkOS.git --depth 1
		cd $HOME/snarkOS
		cargo build --release
		mv $HOME/snarkOS/target/release/snarkos /usr/bin
		sudo systemctl restart "$service_file"
	else
		printf_n "${C_LGn}Checking for updates...${RES}"
		cd $HOME/snarkOS
		/usr/bin/git stash &>/dev/null
		status=`/usr/bin/git pull`
		if [ "$status" != "Already up to date." ]; then
			printf_n "${C_LGn}Updating the node...!${RES}"
			. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/installers/rust.sh)
			/root/.cargo/bin/cargo clean
			/root/.cargo/bin/cargo build --release
			mv $HOME/snarkOS/target/release/snarkos /usr/bin
			sudo systemctl restart "$service_file"
		else
			printf_n "${C_LGn}Binary file of the current version${RES}"
		fi
	fi
	cd
	printf_n "${C_LGn}Done!${RES}"
}
auto_update() {
	echo
}

# Actions
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
cd
$function
