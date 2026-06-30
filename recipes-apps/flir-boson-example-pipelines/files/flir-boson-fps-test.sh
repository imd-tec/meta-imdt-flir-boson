#!/bin/sh

WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh  /dev/video1 height)"
FORMAT="$(get-camera-setup.sh /dev/video1 pixelformat-gst)"

if [ "${FORMAT}" = "GRAY14_LE" ]; then
    echo "Error: Y14 format is not supported by gstreamer, please select a different format."
    exit 1
fi

gst-launch-1.0 v4l2src device=/dev/video1 ! \
    video/x-raw,format="${FORMAT}",width="${WIDTH}",height="${HEIGHT}" ! \
    fpsdisplaysink video-sink=fakesink text-overlay=false \
    signal-fps-measurements=true -v 2>&1 | grep -i "fps\|rate"
