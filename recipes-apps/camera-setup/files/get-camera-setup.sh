#!/bin/sh

set -eu

DEV="${1:-}"
ATTR="${2:-}"

if [ -z "$DEV" ] || [ -z "$ATTR" ]; then
    echo "Usage: $(basename "$0") <dev-node> <width|height|pixelformat>" >&2
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
    *)
        echo "Error: unknown attribute '$ATTR'. Use width, height, or pixelformat." >&2
        exit 1
        ;;
esac
