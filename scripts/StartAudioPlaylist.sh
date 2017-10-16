#!/bin/bash
###########################################################
# StartAudioPlaylist.sh - Start a playlist on the local   #
# system                                                  #
# The Playlist will play once and then stop.              #
###########################################################

FPP="/opt/fpp/bin.pi/fpp"

# Playlist name
PLAYLISTNAME="audio"

# Stop any current plyalist
$FPP -d

# Start playlist
$FPP -P "${PLAYLISTNAME}" ${STARTITEM}