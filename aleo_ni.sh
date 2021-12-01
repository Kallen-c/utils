#!/bin/bash
# Config
wallet_address="$aleo_wallet_address"
explorer_url_template="https://nodes.guru/aleo/aleochecker?q="

# Default variables
language="EN"
raw_output="false"

# Options
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about an Aleo node"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help               show help page"
		echo -e "  -l, --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                           LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -ro, --raw-output        the raw JSON output"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
main() {
	# Texts
	if [ "$language" = "RU" ]; then
		local t_wa="\nАдрес кошелька:         ${C_LGn}%s${RES}"

		local t_nv="\nВерсия ноды:            ${C_LGn}%s${RES}"
		local t_lb="Последний блок:         ${C_LGn}%s${RES}"
		local t_sy1="Нода синхронизирована:  ${C_LR}нет${RES}"
		local t_sy2="Осталось нагнать:       ${C_LR}%d-%d=%d (около %.2f мин.)${RES}"
		local t_sy3="Нода синхронизирована:  ${C_LGn}да${RES}"
		local t_sy_err="${C_LR}\nНода не запущена или запускается!${RES}"
	#elif [ "$language" = ".." ]; then
	else
		local t_wa="\nWallet address:          ${C_LGn}%s${RES}"

		local t_nv="\nNode version:            ${C_LGn}%s${RES}"
		local t_lb="Latest block height:     ${C_LGn}%s${RES}"
		local t_sy1="Node is synchronized:    ${C_LR}no${RES}"
		local t_sy2="It remains to catch up:  ${C_LR}%d-%d=%d (about %.2f min.)${RES}"
		local t_sy3="Node is synchronized:    ${C_LGn}yes${RES}"
		local t_sy_err="${C_LR}\nThe node isn't running or is starting!${RES}"
	fi

	# Actions
	sudo apt install wget jq bc -y &>/dev/null
	if [ -n "$ALEO_ADDRESS" ]; then local wallet_address="$ALEO_ADDRESS"; fi
	if [ -f /etc/systemd/system/aleod.service ]; then
		local service_file="/etc/systemd/system/aleod.service"
	elif [ -f /etc/systemd/system/aleod-miner.service ]; then
		local service_file="/etc/systemd/system/aleod-miner.service"
	else
		printf_n "${C_R}Change the name of the service file to ${C_LGn}aleod.service${RES}"
		return 1 2>/dev/null; exit 1
	fi
	local port=`cat "$service_file" 2>/dev/null | grep -oPm1 "(?<=rpc )([^%]+)(?=$)" | grep -oPm1 "(?<=:)([^%]+)(?=$)"`
	if [ ! -n "$port" ]; then
		local port=`cat "$service_file" 2>/dev/null | grep -oPm1 "(?<=rpc )([^%]+)(?= --)" | grep -oPm1 "(?<=:)([^%]+)(?=$)"`
		if [ ! -n "$port" ]; then
			local port="3032"
		fi
	fi

	local local_rpc="http://localhost:${port}/"
	local node_info=`wget -qO-  -t 1 -T 5 --post-data '{"jsonrpc": "2.0", "id":"documentation", "method": "getnodestate", "params": [] }' "$local_rpc" 2>/dev/null | jq`

	local node_version=`snarkos --version`
	if [ -n "$node_info" ]; then
		local latest_block_height=`jq -r ".result.latest_block_height" <<< $node_info`
		if [ `jq -r ".result.status" <<< $node_info` = "Mining" ]; then
			local catching_up="false"
		else
			local catching_up="true"
		fi
	fi

	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '{"wallet_address": "%s", "node_version": "%s", "latest_block_height": %d, "catching_up": %b}' \
"$wallet_address" \
"$node_version" \
"$latest_block_height" \
"$catching_up" 2>/dev/null
	else
		if [ -n "$wallet_address" ]; then
			printf_n "$t_wa" "$wallet_address"
		fi
		printf_n "$t_nv" "$node_version"
		if [ -n "$latest_block_height" ]; then
			printf_n "$t_lb" "$latest_block_height"
			if [ "$catching_up" = "true" ]; then
				local current_block=`wget -qO- https://www.aleo.network/api/latestblocks?limit=1 | jq -r ".[0].height"`
				local diff=`bc -l <<< "$current_block-$latest_block_height"`
				local takes_time=`bc -l <<< "$diff/20/60"`
				printf_n "$t_sy1"
				printf_n "$t_sy2" "$current_block" "$latest_block_height" "$diff" "$takes_time"
			else
				printf_n "$t_sy3"
			fi
		else
			printf_n "$t_sy_err"
		fi
		printf_n
	fi
}

main
