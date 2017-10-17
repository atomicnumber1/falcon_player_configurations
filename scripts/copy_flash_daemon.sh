#!/bin/bash

TARGET_FOLDER=/home/fpp/media
SOURCE=/media/usb

while true
do
    if lsblk | grep -i "usb"
    then
        # for usb in /media/*; do
        cp -rf $SOURCE/sequences/ $TARGET_FOLDER &> /dev/null;
        cp -rf $SOURCE/music/ $TARGET_FOLDER &> /dev/null;
        cp -rf $SOURCE/videos/ $TARGET_FOLDER &> /dev/null;
        # done
        sudo umount $SOURCE
    fi
    sleep 15;
done