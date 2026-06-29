#!/bin/sh
# Configure FLIR Boson or AP1302 V4L2 pipeline
# Sets correct format through the media pipeline before capture

show_help() {
    echo "Usage: $(basename "$0") <video-device> <video-dev-node> <video-mode>"
    echo "-----------------------------------------------------------------------"
    echo "Video Devices:"
    echo "boson - Flir Boson thermal imaging camera."
    echo "ap1302 - The ap1302 external ISP."
    echo "-----------------------------------------------------------------------"
    echo "Video Modes (Flir Boson):"
    echo "full - Full resolution (640x512)."
    echo "full-telemetry - Full resolution with additional telemetry line (640x513)."
    echo "subsampled - Subsampled resolution (320x256)."
    echo "-----------------------------------------------------------------------"
    echo "Video Modes (AP1302):"
    echo "12mp - 12MP resolution (4096x3072)."
    echo "5mp - 5MP resolution (2592x1944)."
    echo "2k - DCI 2k resolution (2048x1080)."
    echo "1080p - 1080p resolution (1920x1080)."
    echo "1080-4:3 - HD resolution with 4:3 aspect ratio (1440x1080)."
    echo "720p - 720p resolution (1280x720)."
    echo "-----------------------------------------------------------------------"
    exit 1
}

detect_ap1302_startup_failure() {
    if dmesg | grep -qE "ap1302.*(write|read) failed: -6"; then
        echo "AP1302 firmware load failed, reloading modules..."

        modprobe -r ap1302
        sleep 1
        modprobe ap1302
        sleep 2

        if dmesg | grep -q "ap1302.*Sensor ready"; then
            echo "AP1302 recovered successfully"
        else
            echo "Failed to reload AP1302 driver..."
        fi
    fi
}

wait_for_media_devnode() {
    echo "Waiting for /dev/media0 to be created..."
    TIME_WAITED=0

    while [ ! -e /dev/media0 ]; do
        sleep 0.1
        TIME_WAITED=$((TIME_WAITED+1))

        if [ $TIME_WAITED -eq 20 ]; then
            detect_ap1302_startup_failure
            TIME_WAITED=0
        fi
    done
}

media_ctl_set() {
    MEDIA_DEVICE=${1}
    MEDIA_PAD=${2}
    MEDIA_FMT=${3}
    MEDIA_RES=${4}
    (set -x; media-ctl -V "\"${MEDIA_DEVICE}\":${MEDIA_PAD} [fmt:${MEDIA_FMT}/${MEDIA_RES}]")
}

get_flir_boson_resolution_from_mode() {
    VIDEO_MODE=${1}
    case "${VIDEO_MODE}" in
        "full") echo "640 512"
        ;;
        "full-telemetry") echo "640 513"
        ;;
        "subsampled") echo "320 256"
        ;;
        *) echo ""
        ;;
    esac
}

setup_flir_boson() {
    VIDEO_DEVICE=${1}
    VIDEO_MODE=${2}
    echo "Setting up Flir Boson on ${VIDEO_DEVICE}"

    # Media-ctl nodes
    BOSON_CSI="mxc-mipi-csi2.1"
    BOSON_ISI="mxc_isi.1"

    # Pad indexes
    BOSON_SENSOR_SOURCE=0
    BOSON_CSI_SOURCE=4
    CROSSBAR_BOSON_SINK=1
    CROSSBAR_BOSON_SOURCE=4
    BOSON_ISI_SINK=0

    # Format and Resolution
    BOSON_FORMAT="UYVY8_1X16"   
    set -- $(get_flir_boson_resolution_from_mode "${VIDEO_MODE}")
    BOSON_WIDTH="${1}"
    BOSON_HEIGHT="${2}"
    BOSON_RES="${BOSON_WIDTH}x${BOSON_HEIGHT}"

    if [ -z "${BOSON_WIDTH}" ] || [ -z "${BOSON_HEIGHT}" ]; then
        echo "Could not determine Flir Boson resolution from mode ${VIDEO_MODE}"
        show_help
    fi

    # Configure pipeline formats
    media_ctl_set "flir_boson" ${BOSON_SENSOR_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set ${BOSON_CSI} ${BOSON_CSI_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SINK} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set ${BOSON_ISI} ${BOSON_ISI_SINK} ${BOSON_FORMAT} ${BOSON_RES}

    # Set capture format on video node
    v4l2-ctl -d "${VIDEO_DEVICE}" --set-fmt-video=width=${BOSON_WIDTH},height=${BOSON_HEIGHT},pixelformat=YUYV

    echo "Flir Boson setup complete!"
}

get_ap1302_resolution_from_mode() {
    VIDEO_MODE=${1}
    case "${VIDEO_MODE}" in
        "12mp") echo "4096 3072"
        ;;
        "5mp") echo "2592 1944"
        ;;
        "2k") echo "2048 1080"
        ;;
        "1080p") echo "1920 1080"
        ;;
        "1080-4:3") echo "1440 1080"
        ;;
        "720p") echo "1280 720"
        ;;
        *) echo ""
        ;;
    esac
}

setup_ap1302() {
    VIDEO_DEVICE=${1}
    VIDEO_MODE=${2}
    
    echo "Setting up AP1302 on ${VIDEO_DEVICE} with mode ${VIDEO_MODE}"

    # Media-ctl nodes
    AP1302_SENSOR="ap1302.3-003c"
    AP1302_CSI="mxc-mipi-csi2.0"
    AP1302_ISI="mxc_isi.0"

    # Pads
    AP1302_SENSOR_SOURCE=0
    AP1302_CSI_SOURCE=4
    CROSSBAR_AP1302_SINK=0
    CROSSBAR_AP1302_SOURCE=3
    AP1302_ISI_SINK=0

    # Format and Resolution
    AP1302_FORMAT="YUYV8_1X16"
    set -- $(get_ap1302_resolution_from_mode "${VIDEO_MODE}")
    AP1302_WIDTH="${1}"
    AP1302_HEIGHT="${2}"
    AP1302_RES="${AP1302_WIDTH}x${AP1302_HEIGHT}"

    if [ -z "${AP1302_WIDTH}" ] || [ -z "${AP1302_HEIGHT}" ]; then
        echo "Could not determine AP1302 resolution from mode ${VIDEO_MODE}"
        show_help
    fi

    # Configure pipeline formats
    media_ctl_set ${AP1302_SENSOR} ${AP1302_SENSOR_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set ${AP1302_CSI} ${AP1302_CSI_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SINK} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set ${AP1302_ISI} ${AP1302_ISI_SINK} ${AP1302_FORMAT} ${AP1302_RES}

    # Set capture format on video node
    v4l2-ctl -d "${VIDEO_DEVICE}" --set-fmt-video=width=${AP1302_WIDTH},height=${AP1302_HEIGHT},pixelformat=YUYV

    echo "AP1302 setup complete!"
}


if [ $# -lt 3 ]; then
    show_help
fi

wait_for_media_devnode

SETUP_DEVICE=${1}

case "${SETUP_DEVICE}" in
    "ap1302") setup_ap1302 "${2}" "${3}"
    ;;
    "boson") setup_flir_boson "${2}" "${3}"
    ;;
    *) echo "Error: Unknown device ${SETUP_DEVICE}" && show_help
    ;;
esac
