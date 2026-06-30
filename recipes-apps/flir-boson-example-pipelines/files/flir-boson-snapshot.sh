#!/bin/sh

OUTPUT_FILE="/tmp/boson.jpg"
WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh /dev/video1 height)"
FORMAT="$(get-camera-setup.sh /dev/video1 pixelformat-gst)"
VCONVERT="videoconvert"

if [ $# -ge 1 ]; then
    OUTPUT_FILE=${1}
fi

if [ "${FORMAT}" = "GRAY14_LE" ]; then
    echo "Taking snapshot in Y14 format"
    flir-boson-y14-snapshot.sh "${OUTPUT_FILE}"
    exit $?
fi

if [ "${FORMAT}" = "GRAY8" ]; then
    VCONVERT="videoconvert ! video/x-raw,format=GRAY8"
fi


gst-launch-1.0 v4l2src device=/dev/video1 num-buffers=1 ! \
    video/x-raw,format="${FORMAT}",width="${WIDTH}",height="${HEIGHT}" ! \
    ${VCONVERT} ! \
    jpegenc ! \
    filesink location="${OUTPUT_FILE}"

if [ $? -eq 0 ]; then
    echo "Snapshot Taken! File written to: ${OUTPUT_FILE}"
else
    echo "Failed to take snapshot, please double check the gstreamer log and the media pipeline setup:"
    echo "\$ systemctl status camera-setup"
    exit 1
fi
