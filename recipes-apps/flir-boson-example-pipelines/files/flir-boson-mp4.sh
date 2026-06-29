#!/bin/sh

OUTPUT_FILE="/tmp/boson.mp4"
WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh /dev/video1 height)"

if [ $# -ge 1 ]; then
    OUTPUT_FILE=${1}
fi

gst-launch-1.0 v4l2src device=/dev/video1 ! \
        video/x-raw,format=YUY2,width="${WIDTH}",height="${HEIGHT}",colorimetry=bt709 ! \
        vpuenc_h264 ! h264parse ! mp4mux ! \
        filesink location="${OUTPUT_FILE}"
