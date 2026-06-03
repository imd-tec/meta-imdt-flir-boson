#!/bin/sh

gst-launch-1.0 v4l2src device=/dev/video1 ! \
    video/x-raw,format=YUY2,width=640,height=512 ! \
    fpsdisplaysink video-sink=fakesink text-overlay=false \
    signal-fps-measurements=true -v 2>&1 | grep -i "fps\|rate"
