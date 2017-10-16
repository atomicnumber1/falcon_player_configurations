#!/bin/sh
###########################################################
# stopfpp.sh - Stop current playlist                      #
###########################################################

FPP="/opt/fpp/bin.pi/fpp"
# Stop current playlist
$FPP -d

# Kill any omxplayers
sudo killall -9 omxplayer.bin