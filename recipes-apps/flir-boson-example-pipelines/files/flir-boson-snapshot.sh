#!/bin/sh

OUTPUT_FILE="/tmp/boson.jpg"
WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh /dev/video1 height)"

if [ $# -ge 1 ]; then
    OUTPUT_FILE=${1}
fi

gst-launch-1.0 v4l2src device=/dev/video1 num-buffers=1 ! \
    video/x-raw,format=YUY2,width="${WIDTH}",height="${HEIGHT}" ! \
    videoconvert ! \
    jpegenc ! \
    filesink location="${OUTPUT_FILE}"

if [ $? -eq 0 ]; then
    echo "Snapshot Taken! File written to: ${OUTPUT_FILE}"
else
    echo "Failed to take snapshot, please double check the gstreamer log and the media pipeline setup:"
    echo "\$ systemctl status camera-setup"
    exit 1
fi
