#!/bin/sh

cleanup() {
    rm /tmp/snapshot.raw /tmp/snapshot.pgm
}


OUTPUT_FILE="/tmp/boson.jpg"
WIDTH="$(get-camera-setup.sh /dev/video1 width)"
HEIGHT="$(get-camera-setup.sh /dev/video1 height)"
FORMAT="$(get-camera-setup.sh /dev/video1 pixelformat-gst)"

if [ "${FORMAT}" != "GRAY14_LE" ]; then
    echo "Camera /dev/video1 is not in GRAY14_LE format (${FORMAT}). Exiting early."
    echo "To set the correct format, use: camera-setup.sh boson /dev/video1 <full/full-telemetry/subsampled> Y14"
    exit 1
fi

if [ $# -ge 1 ]; then
    OUTPUT_FILE=${1}
fi

v4l2-ctl -d /dev/video1 \
    --set-fmt-video=width="${WIDTH}",height="${HEIGHT}",pixelformat="Y14 "\
    --stream-mmap \
    --stream-count=1 \
    --stream-to=/tmp/snapshot.raw

if [ $? -ne 0 ]; then
    echo "Failed to capture snapshot from /dev/video1"
    exit 1
fi

y14-to-pgm.py /tmp/snapshot.raw /tmp/snapshot.pgm "${WIDTH}" "${HEIGHT}"

if [ $? -ne 0 ]; then
    echo "Failed to convert snapshot to PGM"
    exit 1
fi

gst-launch-1.0 filesrc location=/tmp/snapshot.pgm ! \
    pnmdec ! \
    jpegenc ! \
    filesink location="${OUTPUT_FILE}"

if [ $? -eq 0 ]; then
    echo "Snapshot Taken! File written to: ${OUTPUT_FILE}"
    cleanup
    
else
    echo "Failed to take snapshot, please double check the gstreamer log and the media pipeline setup:"
    echo "\$ systemctl status camera-setup"
    cleanup
fi
