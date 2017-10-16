#!/bin/bash
###########################################################
# StartAudioPlaylist.sh - Start a playlist on the local   #
# system                                                  #
# The Playlist will play once and then stop.              #
###########################################################

FPP="/opt/fpp/bin.pi/fpp"
PLAYING=$(cat /var/tmp/playing_audio.txt)

function play_playlist_audio {
    # Edit this line to hold the playlist name in quotes
    PLAYLISTNAME="audio"

    # If you want to start on a specfic numbered entry in the playlist
    # then put the entry number inside the quotes on the line below
    STARTITEM=""

    echo 1 > /var/tmp/playing_audio.txt

    # Stop any current plyalist
    $FPP -d

    # Start playlist
    $FPP -P "${PLAYLISTNAME}" ${STARTITEM}
}

function stop_playlist_audio {
    echo 0 > /var/tmp/playing_audio.txt
    $FPP -d
}


if [ "$PLAYING" -eq "0" ];
then
    play_playlist_audio
else
    stop_playlist_audio
fi
