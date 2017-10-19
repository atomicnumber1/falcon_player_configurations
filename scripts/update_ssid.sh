#!/bin/bash

SRC=/home/fpp/code/falcon_player_configurations
FILENAME=$SRC/configurations/ssid_updated.txt

sudo sed -i.bak "s/ssid=.*/ssid=$1/g" /etc/hostapd/hostapd.conf
echo 1 > $FILENAME

exec bash $SRC/scripts/reboot.sh &