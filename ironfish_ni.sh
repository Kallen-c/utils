#!/bin/bash
# Default variables
language="EN"
raw_output="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about an Iron Fish node"
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
		local t_nn="\nНазвание ноды:          ${C_LGn}%s${RES}"
		local t_nv="Версия ноды:            ${C_LGn}%s${RES}"
		local t_lb="Последний блок:         ${C_LGn}%d${RES}"
		local t_sy1="Нода синхронизирована:  ${C_LR}нет${RES}\n"
		local t_sy2="Нода синхронизирована:  ${C_LGn}да${RES}\n"

		local t_m1="Майнер запущен:         ${C_LGn}да${RES}"
		local t_m2="Майнер запущен:         ${C_LR}нет${RES}"
		local t_t="Потоков используется:   ${C_LGn}%d${RES}"
		local t_bm="Блоков намайнено:       ${C_LGn}%d${RES}\n"

		local t_wn="Название кошелька:      ${C_LGn}%s${RES}"
		local t_wa="Адрес кошелька:         ${C_LGn}%s${RES}"
		local t_bal="Баланс:                 ${C_LGn}%f${RES} IRON\n"

	else
		local t_nn="\nMoniker:               ${C_LGn}%s${RES}"
		local t_nv="Node version:          ${C_LGn}%s${RES}"
		local t_lb="Latest block height:   ${C_LGn}%d${RES}"
		local t_sy1="Node is synchronized:  ${C_LR}no${RES}\n"
		local t_sy2="Node is synchronized:  ${C_LGn}yes${RES}\n"

		local t_m1="Miner launched:        ${C_LGn}yes${RES}"
		local t_m2="Miner launched:        ${C_LR}no${RES}"
		local t_t="Threads are used:      ${C_LGn}%d${RES}"
		local t_bm="Blocks mined:          ${C_LGn}%d${RES}\n"

		local t_wn="Wallet name:           ${C_LGn}%s${RES}"
		local t_wa="Wallet address:        ${C_LGn}%s${RES}"
		local t_bal="Balance:               ${C_LGn}%f${RES} IRON\n"
	fi

	# Actions
	sudo apt install wget awk jq bc -y &>/dev/null
	if docker ps -a | grep -q iron_fish_node; then
		local command="docker exec -t iron_fish_node ironfish"
		local threads=`docker inspect iron_fish_miner | jq -r ".[0].Config.Cmd[2]"`
	else
		local command="ironfish"
	fi

	local moniker=`$command config:get nodeName --no-color | tr -d '"' | tr -d '\r'`
	local status=`$command status | tr -d '\r'`
	local node_version=`echo "$status" | awk 'NR == 2 {print $2}'`
	local latest_block_height=`echo "$status" | awk 'NR == 10 {print $(NF)}' | tr -d '(' | tr -d ')'`
	if [ `echo "$status" | awk 'NR == 10 {print $2}'` = "SYNCED" ]; then
		local catching_up="false"
	else
		local catching_up="true"
	fi
	if [ `echo "$status" | awk 'NR == 7 {print $4}'` -ge 1 ]; then
		local miner="true"
	else
		local miner="false"
	fi
	local blocks_mined=`echo "$status" | awk 'NR == 7 {print $6}'`
	local wallet_name=`$command accounts:which | tr -d '\r'`
	local wallet_address=`$command accounts:publickey | tr -d '\r' | awk '{print $(NF)}'`
	local balance=`$command accounts:balance | tr -d '\r' | awk '{print $(NF-2)}'`

	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '{"moniker": "%s", "node_version": "%s", "latest_block_height": %d, "catching_up": %b, "miner": %b, "threads": %d, "blocks_mined": %d, "wallet_name": "%s", "wallet_address": "%s", "balance": %f}' \
"$moniker" \
"$node_version" \
"$latest_block_height" \
"$catching_up" \
"$miner" \
"$threads" \
"$blocks_mined" \
"$wallet_name" \
"$wallet_address" \
"$balance" 2>/dev/null
	else
		printf_n "$t_nn" "$moniker"
		printf_n "$t_nv" "$node_version"
		printf_n "$t_lb" "$latest_block_height"
		if [ "$catching_up" = "true" ]; then
			printf_n "$t_sy1"
		else
			printf_n "$t_sy2"
		fi

		if [ "$miner" = "true" ]; then
			printf_n "$t_m1"
		else
			printf_n "$t_m2"
		fi
		if [ -n "$threads" ]; then printf_n "$t_t" "$threads"; fi
		printf_n "$t_bm" "$blocks_mined"

		printf_n "$t_wn" "$wallet_name"
		printf_n "$t_wa" "$wallet_address"
		printf_n "$t_bal" "$balance" 2>/dev/null
	fi
}

main
