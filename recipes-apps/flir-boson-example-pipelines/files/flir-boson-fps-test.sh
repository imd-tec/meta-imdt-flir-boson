#!/bin/sh

WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh  /dev/video1 height)"

gst-launch-1.0 v4l2src device=/dev/video1 ! \
    video/x-raw,format=YUY2,width="${WIDTH}",height="${HEIGHT}" ! \
    fpsdisplaysink video-sink=fakesink text-overlay=false \
    signal-fps-measurements=true -v 2>&1 | grep -i "fps\|rate"
