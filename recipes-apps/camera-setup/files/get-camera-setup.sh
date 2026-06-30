#!/bin/sh

set -eu
v4l2_format_to_gst() {
    case "$1" in
        "YUYV") echo "YUY2" ;;
        "UYVY") echo "YUY2" ;;
        "GREY") echo "GRAY8" ;;
        "Y14 ") echo "GRAY14_LE" ;; # Not supported by GStreamer
        "RGB3") echo "RGB" ;;
        "BGR3") echo "BGR" ;;
    esac
}

DEV="${1:-}"
ATTR="${2:-}"

if [ -z "$DEV" ] || [ -z "$ATTR" ]; then
    echo "Usage: $(basename "$0") <dev-node> <width|height|pixelformat|pixelformat-gst>" >&2
    exit 1
fi

if [ ! -c "$DEV" ]; then
    echo "Error: '$DEV' is not a character device." >&2
    exit 1
fi

RAW=$(v4l2-ctl -d "$DEV" --get-fmt-video 2>/dev/null)

case "$ATTR" in
    width)
        echo "$RAW" | grep 'Width/Height' | awk -F'[ /]+' '{print $(NF-1)}'
        ;;
    height)
        echo "$RAW" | grep 'Width/Height' | awk -F'[ /]+' '{print $NF}'
        ;;
    pixelformat)
        echo "$RAW" | grep 'Pixel Format' | awk -F"'" '{print $2}'
        ;;
    pixelformat-gst)
        FORMAT=$(echo "$RAW" | grep 'Pixel Format' | awk -F"'" '{print $2}')
        v4l2_format_to_gst "${FORMAT}"
        ;;
    *)
        echo "Error: unknown attribute '$ATTR'. Use width, height, pixelformat or pixelformat-gst." >&2
        exit 1
        ;;
esac
