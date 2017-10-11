#!/bin/sh
###########################################################
# StartVideoPlaylist.sh - Start a playlist on the local   #
# System and play video                                   #
# The Playlist will play once and then stop.              #
###########################################################

# Edit this line to hold the playlist name in quotes
PLAYLISTNAME="video"
VIDEOFILE="video.mp4"

# If you want to start on a specfic numbered entry in the playlist
# then put the entry number inside the quotes on the line below
STARTITEM=""

# Stop current playlist
fpp -d

# Start playlist
fpp -P "${PLAYLISTNAME}" ${STARTITEM}



###################################################################
# Set some environment variables
. /opt/fpp/scripts/common

sudo -u fpp /usr/bin/omxplayer --no-keys "${MEDIADIR}/videos/${VIDEOFILE}"