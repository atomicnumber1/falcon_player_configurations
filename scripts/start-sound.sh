#!/bin/bash

FILENAME='/home/fpp/code/falcon_player_configurations/sounds/Dock.ogg'

sudo omxplayer -o local $FILENAME 2>&1 >/dev/null &