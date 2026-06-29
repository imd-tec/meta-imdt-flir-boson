#!/bin/sh

BOSON_OUTPUT_FILE=/tmp/boson.mkv
AP1302_OUTPUT_FILE=/tmp/ap1302.mkv

BOSON_WIDTH="$(get-camera-setup.sh /dev/video1 width)"
BOSON_HEIGHT="$(get-camera-setup.sh /dev/video1 height)"
AP1302_WIDTH="$(get-camera-setup.sh /dev/video0 width)"
AP1302_HEIGHT="$(get-camera-setup.sh /dev/video0 height)"

if [ $# -ge 2 ]; then
    AP1302_OUTPUT_FILE=${1}
    BOSON_OUTPUT_FILE=${2}
fi 

gst-launch-1.0 \
  v4l2src device=/dev/video0 ! \
    video/x-raw,format=YUY2,width="${AP1302_WIDTH}",height="${AP1302_HEIGHT}",framerate=60/1,colorimetry=bt709 ! \
    matroskamux ! filesink location="${AP1302_OUTPUT_FILE}" \
  v4l2src device=/dev/video1 ! \
    video/x-raw,format=YUY2,width="${BOSON_WIDTH}",height="${BOSON_HEIGHT}",framerate=60/1,colorimetry=bt709 ! \
    matroskamux ! filesink location="${BOSON_OUTPUT_FILE}"
