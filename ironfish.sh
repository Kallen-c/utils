#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1

function setupVars {
	if [ ! $IRONFISH_WALLET ]; then
		read -p "Enter wallet name: " IRONFISH_WALLET
		echo 'export IRONFISH_WALLET='${IRONFISH_WALLET} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour wallet name:' $IRONFISH_WALLET '\e[0m\n'
	if [ ! $IRONFISH_NODENAME ]; then
		read -p "Enter node name: " IRONFISH_NODENAME
		echo 'export IRONFISH_NODENAME='${IRONFISH_NODENAME} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour wallet name:' $IRONFISH_WALLET '\e[0m\n'
	if [ ! $IRONFISH_THREADS ]; then
		read -e -p "Enter your threads [-1]: " IRONFISH_THREADS
		echo 'export IRONFISH_THREADS='${IRONFISH_THREADS:--1} >> $HOME/.bash_profile
	fi
	echo -e '\n\e[42mYour threads count:' $IRONFISH_THREADS '\e[0m\n'
	echo "alias ironfish='yarn --cwd ~/ironfish/ironfish-cli/ start:once'" >> $HOME/.bash_profile && . $HOME/.bash_profile
	echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
	. $HOME/.bash_profile
	alias ironfish='yarn --cwd ~/ironfish/ironfish-cli/ start:once'
	sleep 1
}

function setupSwap {
	echo -e '\n\e[42mSet up swapfile\e[0m\n'
	grep -q "swapfile" /etc/fstab
  if [[ ! $? -ne 0 ]]; then
      echo -e '\n\e[42m[Swap] Swap file exist, skip.\e[0m\n'
  else
      cd $HOME
      sudo fallocate -l 4G $HOME/swapfile
      sudo dd if=/dev/zero of=swapfile bs=1K count=4M
      sudo chmod 600 $HOME/swapfile
      sudo mkswap $HOME/swapfile
      sudo swapon $HOME/swapfile
      sudo swapon --show
      echo $HOME'/swapfile swap swap defaults 0 0' >> /etc/fstab
      echo -e '\n\e[42m[Swap] Done\e[0m\n'
  fi
}

function installDeps {
	echo -e '\n\e[42mPreparing to install\e[0m\n' && sleep 1
	cd $HOME
	sudo apt update
	sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
	. $HOME/.cargo/env
	curl https://deb.nodesource.com/setup_16.x | sudo bash
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	# sudo apt upgrade -y < "/dev/null"
	sudo apt install curl make clang pkg-config libssl-dev build-essential git jq nodejs -y < "/dev/null"
	sudo npm --force install -g yarn
}

function createConfig {
	echo "{
		\"nodeName\": \"${IRONFISH_NODENAME}\",
		\"blockGraffiti\": \"${IRONFISH_NODENAME}\"
	}" > $HOME/.ironfish/config.json
}

function installSoftware {
	. $HOME/.bash_profile
	. $HOME/.cargo/env
	echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
	cd $HOME
	git clone https://github.com/iron-fish/ironfish
	cd $HOME/ironfish
	git pull
	# git checkout 45d85b7916b72f7ad263491b0c7fb6916b2edabd
	cargo install --force wasm-pack
	yarn
	cp $HOME/ironfish/ironfish-cli/bin/ironfish /usr/bin
}

function installService {
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=IronFish Node
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/yarn --cwd $HOME/ironfish/ironfish-cli/ start start
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/ironfishd.service
echo "[Unit]
Description=IronFish Miner
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/yarn --cwd $HOME/ironfish/ironfish-cli/ start miners:start -t $IRONFISH_THREADS
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
" > $HOME/ironfishd-miner.service
sudo mv $HOME/ironfishd.service /etc/systemd/system
sudo mv $HOME/ironfishd-miner.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl enable ironfishd ironfishd-miner
sudo systemctl restart ironfishd ironfishd-miner
echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service ironfishd status | grep active` =~ "running" ]]; then
  echo -e "Your IronFish node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice ironfishd status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your IronFish node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
if [[ `service ironfishd-miner status | grep active` =~ "running" ]]; then
  echo -e "Your IronFish Miner node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice ironfishd-miner status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your IronFish Miner node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
. $HOME/.bash_profile
}


function deleteIronfish {
	sudo systemctl disable ironfishd ironfishd-miner ironfishd-listener
	sudo systemctl stop ironfishd ironfishd-miner ironfishd-listener
	sudo rm -r $HOME/ironfish
}

PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Delete" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            echo -e '\n\e[42mYou choose install...\e[0m\n' && sleep 1
			setupVars
			setupSwap
			installDeps
			installSoftware
			createConfig
			installService
			#installListener
			break
            ;;
		"Delete")
            echo -e '\n\e[31mYou choose delete...\e[0m\n' && sleep 1
			deleteIronfish
			echo -e '\n\e[42mIronfish was deleted!\e[0m\n' && sleep 1
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
