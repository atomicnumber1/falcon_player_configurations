#!/bin/bash
###########################################################
# StartVideoPlaylist.sh - Start a playlist on the local   #
# System and play video                                   #
# The Playlist will play once and then stop.              #
###########################################################
# Set some environment variables
. /opt/fpp/scripts/common


FPP="/opt/fpp/bin.pi/fpp"
PLAYING=$(cat /var/tmp/playing_video.txt)
FORCEAUDIO="-o local"
VOLUME=75
# 75% FPP volume is 87.5% amixer which is around 0dB in omxplayer
DB=$(echo "((50 + (${VOLUME}/2)) - 87.5) / 2.5 * 3" | bc)

function play_playlist_video {
    echo 1 > /var/tmp/playing_video.txt

    # Edit this line to hold the playlist name in quotes
    PLAYLISTNAME="video"
    VIDEOFILE=$(ls ${MEDIADIR}/videos/)

    # If you want to start on a specfic numbered entry in the playlist
    # then put the entry number inside the quotes on the line below
    STARTITEM=""

    # Stop current playlist
    $FPP -d

    # Kill any omxplayers
    sudo killall -9 omxplayer.bin

    # Start playlist
    $FPP -P "${PLAYLISTNAME}" ${STARTITEM}
    sudo -u fpp /usr/bin/omxplayer ${FORCEAUDIO} --no-keys --vol ${DB}00 "${MEDIADIR}/videos/${VIDEOFILE}"
}

function stop_playlist_video {
    echo 0 > /var/tmp/playing_video.txt
    sudo killall -9 omxplayer.bin
    $FPP -d
}


if [ "$PLAYING" -eq "0" ];
then
    play_playlist_video
else
    stop_playlist_video
fi
