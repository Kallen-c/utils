sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install curl gnupg apt-transport-https ca-certificates \
lsb-release -y && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
| sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
sudo apt-get update && \
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
sudo chmod +x /usr/local/bin/docker-compose && docker-compose --version
git clone https://github.com/pontem-network/bootstrap.git pontem-bootstrap && \
cd ~/pontem-bootstrap && cp .env.testnet .env

	if [ ! $PONTEM_NODENAME ]; then
		read -p "Enter node name: " PONTEM_NODENAME
		echo 'export PONTEM_NODENAME='\"${PONTEM_NODENAME}\" >> $HOME/.bash_profile
	fi


	sed -i.bak -e "s/^NODE_NAME=my-node-name\"\"/NODE_NAME=$PONTEM_NODENAME/" $HOME/pontem-bootstrap/.env

cd ~/pontem-bootstrap && docker-compose build
 cd ~/pontem-bootstrap && \
 cd ~/pontem-bootstrap && docker-compose up -d
