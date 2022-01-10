#!/bin/sh
#todo: sudo apt-get update && sudo apt-get install prometheus-node-exporter
sudo apt-get update && sudo apt-get install prometheus-node-exporter

#wget -qO- https://repos.influxdata.com/influxdb.key | sudo tee /etc/apt/trusted.gpg.d/influxdb.asc >/dev/null
#source /etc/os-release
#echo "deb https://repos.influxdata.com/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
#sudo apt-get update && sudo apt-get install telegraf
# conf telegraf & exec file create &chmod & edit /lib/systemd/system/telegraf.service run as root
#systemctl daemon-reload
#service restart
