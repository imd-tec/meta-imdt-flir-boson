#!/bin/sh

BOSON_OUTPUT_FILE=/tmp/boson.mkv
AP1302_OUTPUT_FILE=/tmp/ap1302.mkv

BOSON_WIDTH="$(get-camera-setup.sh /dev/video1 width)"
BOSON_HEIGHT="$(get-camera-setup.sh /dev/video1 height)"
BOSON_FORMAT="$(get-camera-setup.sh /dev/video1 pixelformat-gst)"
AP1302_WIDTH="$(get-camera-setup.sh /dev/video0 width)"
AP1302_HEIGHT="$(get-camera-setup.sh /dev/video0 height)"
AP1302_FORMAT="$(get-camera-setup.sh /dev/video0 pixelformat-gst)"

if [ $# -ge 2 ]; then
    AP1302_OUTPUT_FILE=${1}
    BOSON_OUTPUT_FILE=${2}
fi

if [ "${BOSON_FORMAT}" = "GRAY14_LE" ]; then
    echo "Error: Y14 format is not supported by gstreamer, please select a different format for the Boson camera."
    exit 1
fi

gst-launch-1.0 \
  v4l2src device=/dev/video0 ! \
    video/x-raw,format="${AP1302_FORMAT}",width="${AP1302_WIDTH}",height="${AP1302_HEIGHT}",framerate=60/1,colorimetry=bt709 ! \
    matroskamux ! filesink location="${AP1302_OUTPUT_FILE}" \
  v4l2src device=/dev/video1 ! \
    video/x-raw,format="${BOSON_FORMAT}",width="${BOSON_WIDTH}",height="${BOSON_HEIGHT}",framerate=60/1,colorimetry=bt709 ! \
    matroskamux ! filesink location="${BOSON_OUTPUT_FILE}"
