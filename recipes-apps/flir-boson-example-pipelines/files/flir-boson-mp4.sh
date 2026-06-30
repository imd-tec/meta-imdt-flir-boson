#!/bin/sh

OUTPUT_FILE="/tmp/boson.mp4"
WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh /dev/video1 height)"
FORMAT="$(get-camera-setup.sh /dev/video1 pixelformat-gst)"

if [ $# -ge 1 ]; then
    OUTPUT_FILE=${1}
fi

if [ "${FORMAT}" = "GRAY14_LE" ]; then
    echo "Error: Y14 format is not supported by gstreamer, please select a different format."
    exit 1
fi

gst-launch-1.0 v4l2src device=/dev/video1 ! \
        video/x-raw,format="${FORMAT}",width="${WIDTH}",height="${HEIGHT}",colorimetry=bt709 ! \
        vpuenc_h264 ! h264parse ! mp4mux ! \
        filesink location="${OUTPUT_FILE}"
