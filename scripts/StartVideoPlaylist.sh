#!/bin/bash
###########################################################
# StartVideoPlaylist.sh - Start a playlist on the local   #
# System and play video                                   #
# The Playlist will play once and then stop.              #
###########################################################

###################################################################
# Set some environment variables
# . /opt/fpp/scripts/common

FPP="/opt/fpp/bin.pi/fpp"
PLAYLISTNAME="video"
# FORCEAUDIO="-o local"
# VOLUME=75
# # 75% FPP volume is 87.5% amixer which is around 0dB in omxplayer
# DB=$(echo "((50 + (${VOLUME}/2)) - 87.5) / 2.5 * 3" | bc)
# VIDEOFILE=$(ls ${MEDIADIR}/videos/)

# Stop current playlist
$FPP -d

# Kill any omxplayers
sudo killall -9 omxplayer.bin

# Start playlist
$FPP -P "${PLAYLISTNAME}"

# Start video (No need)
# nohup sudo -u fpp /usr/bin/omxplayer ${FORCEAUDIO} --no-keys --vol ${DB}00 "${MEDIADIR}/videos/${VIDEOFILE}" &> /dev/null &