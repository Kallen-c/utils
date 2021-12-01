#!/bin/bash
systemctl stop aleod
cd $HOME
sudo apt update
sudo apt install curl make clang pkg-config libssl-dev build-essential git mc jq unzip -y
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
sleep 1

git clone https://github.com/AleoHQ/snarkOS.git --depth 1
cd snarkOS
cargo build --release --verbose
sudo cp $HOME/snarkOS/target/release/snarkos /usr/bin
systemctl restart aleod
