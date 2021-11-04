#!/bin/bash


. <(wget -qO- https://raw.githubusercontent.com/Kallen-c/utils/main/logo.sh)
sudo apt update && sudo apt upgrade -y
sudo apt install wget jq unzip git build-essential pkg-config libssl-dev -y
