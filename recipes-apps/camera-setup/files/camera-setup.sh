#!/bin/sh
# Configure FLIR Boson or AP1302 V4L2 pipeline
# Sets correct format through the media pipeline before capture

show_help() {
    echo "Usage: $(basename "$0") <video-device> <video-dev-node> <video-mode> <video-format> (fps)"
    echo "-----------------------------------------------------------------------"
    echo "Video Devices:"
    echo "boson - Flir Boson thermal imaging camera."
    echo "ap1302 - The ap1302 external ISP."
    echo "-----------------------------------------------------------------------"
    echo "Video Modes (Flir Boson):"
    echo "full - Full resolution (640x512)."
    echo "full-telemetry - Full resolution with additional telemetry line (640x514)."
    echo "subsampled - Subsampled resolution (320x256)."
    echo "-----------------------------------------------------------------------"
    echo "Video Formats (Flir Boson):"
    echo "YUYV - Color 4:2:2 pixel format."
    echo "Y14 - Mono 1:1:4 pixel format."
    echo "GREY - Mono 1:1:1 pixel format."
    echo "-----------------------------------------------------------------------"    
    echo "Video Modes (AP1302):"
    echo "12mp - 12MP resolution (4096x3072)."
    echo "5mp - 5MP resolution (2592x1944)."
    echo "2k - DCI 2k resolution (2048x1080)."
    echo "1080p - 1080p resolution (1920x1080)."
    echo "1080-4:3 - HD resolution with 4:3 aspect ratio (1440x1080)."
    echo "720p - 720p resolution (1280x720)."
    echo "-----------------------------------------------------------------------"
    echo "Video Formats (AP1302):"
    echo "YUYV - Color 4:2:2 pixel format."
    echo "RGB3 - RGB 3:3:2 pixel format."
    echo "BGR3 - BGR 3:3:2 pixel format."
    echo "NV12 - NV12 compressed pixel format."
    echo "-----------------------------------------------------------------------"
    echo "Note: The FPS parameter only affects the AP1302 camera. If none is specified, the default is 30 FPS."
    exit 1
}

detect_ap1302_wrong_overlay() {
    if dmesg | grep -qE  "ap1302: probe of 3-003c failed with error -16"; then
        echo "Failed to probe AP1302, does the overlay match the connected sensor?"
        echo "Overlays (imx8mp-imdt-pico):"
        echo "- AR1335 (no overlay)"
        echo "- AR5021/2 (imx8mp-imdt-pico-ar0521.dtbo)"

        exit 1
    fi
}

detect_ap1302_startup_failure() {
    if dmesg | grep -qE "ap1302.*(write|read) failed: -*"; then
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

wait_for_camera() {
    DEV="$1"
    TIMEOUT="${2:-10}"
    ELAPSED=0
    INTERVAL=0.2

    while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
        if [ -e "$DEV" ] && v4l2-ctl --device="$DEV" --info >/dev/null 2>&1; then
            return 0
        fi
        sleep "$INTERVAL"
        ELAPSED=$((ELAPSED + 1))
    done

    echo "camera-setup: timed out waiting for $DEV" >&2
    return 1
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

dtbo_is_loaded() {
    if fw_printenv apply_overlays | grep "${1}" > /dev/null; then
        return 0
    else
        return 1
    fi
}

media_ctl_set() {
    MEDIA_DEVICE=${1}
    MEDIA_PAD=${2}
    MEDIA_FMT=${3}
    MEDIA_RES=${4}
    MEDIA_FPS=${5}

    if [ -n "${MEDIA_FPS}" ]; then
        (set -x; media-ctl -V "\"${MEDIA_DEVICE}\":${MEDIA_PAD} [fmt:${MEDIA_FMT}/${MEDIA_RES}@1/${MEDIA_FPS}]")
    else
        (set -x; media-ctl -V "\"${MEDIA_DEVICE}\":${MEDIA_PAD} [fmt:${MEDIA_FMT}/${MEDIA_RES}]")
    fi
}

v4l2_format_to_media_ctrl() {
    DEVICE=${1}
    V4L2_FMT=${2}

    if [ "${DEVICE}" == "boson" ]; then
        case "${V4L2_FMT}" in
            "YUYV") echo "UYVY8_1X16"
            ;;
            "Y14") echo "Y14_1X14"
            ;;
            "GREY") echo "Y8_1X8"
            ;;
            *) echo ""
            ;;
        esac
        return
    fi

    if [ "${DEVICE}" == "ap1302" ]; then
        case "${V4L2_FMT}" in
            "YUYV") echo "YUYV8_1X16"
            ;;
            "RGB3") echo "RGB888_1X24"
            ;;
            "BGR3") echo "BGR888_1X24"
            ;;
            "NV12") echo "YUYV8_1X16"
            ;;
            *) echo ""
            ;;
        esac
        return
    fi

    echo ""
}

get_flir_boson_resolution_from_mode() {
    VIDEO_MODE=${1}
    case "${VIDEO_MODE}" in
        "full") echo "640 512"
        ;;
        "full-telemetry") echo "640 514"
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

    # Pixel Format
    BOSON_V4L2_FORMAT=${3}
    BOSON_MEDIA_CTRL_FORMAT=$(v4l2_format_to_media_ctrl "boson" "${BOSON_V4L2_FORMAT}")

    if [ -z "${BOSON_MEDIA_CTRL_FORMAT}" ]; then
        echo "Unsupported V4L2 format for the Flir Boson: ${BOSON_V4L2_FORMAT}"
        show_help
    fi

    # Resolution
    set -- $(get_flir_boson_resolution_from_mode "${VIDEO_MODE}")
    BOSON_WIDTH="${1}"
    BOSON_HEIGHT="${2}"
    BOSON_RES="${BOSON_WIDTH}x${BOSON_HEIGHT}"

    if [ -z "${BOSON_WIDTH}" ] || [ -z "${BOSON_HEIGHT}" ]; then
        echo "Could not determine Flir Boson resolution from mode ${VIDEO_MODE}"
        show_help
    fi

    # Configure pipeline formats
    media_ctl_set "flir_boson" ${BOSON_SENSOR_SOURCE} "${BOSON_MEDIA_CTRL_FORMAT}" "${BOSON_RES}"
    media_ctl_set ${BOSON_CSI} ${BOSON_CSI_SOURCE} "${BOSON_MEDIA_CTRL_FORMAT}" "${BOSON_RES}"
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SINK} "${BOSON_MEDIA_CTRL_FORMAT}" "${BOSON_RES}"
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SOURCE} "${BOSON_MEDIA_CTRL_FORMAT}" "${BOSON_RES}"
    media_ctl_set ${BOSON_ISI} ${BOSON_ISI_SINK} "${BOSON_MEDIA_CTRL_FORMAT}" "${BOSON_RES}"

    if [ "${BOSON_V4L2_FORMAT}" == "Y14" ]; then
        # Append space to Y14 format to make it into the fourcc format
        BOSON_V4L2_FORMAT="Y14 "
    fi

    # Set capture format on video node
    v4l2-ctl -d "${VIDEO_DEVICE}" --set-fmt-video=width="${BOSON_WIDTH}",height="${BOSON_HEIGHT}",pixelformat="${BOSON_V4L2_FORMAT}"

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
    VIDEO_FPS=${4}

    if [ -z "${VIDEO_FPS}" ]; then
        echo "AP1302 FPS not specified, defaulting to 30"
        VIDEO_FPS=30
    fi

    echo "Setting up AP1302 on ${VIDEO_DEVICE} with mode ${VIDEO_MODE} at ${VIDEO_FPS}fps"

    # Media-ctl nodes
    AP1302_SENSOR="ap1302.3-003c"
    AP1302_CSI="mxc-mipi-csi2.0"
    AP1302_ISI="mxc_isi.0"

    # Pads
    AP1302_SENSOR_SOURCE=0
    AP1302_SENSOR_SINK=1
    AP1302_CSI_SOURCE=4
    CROSSBAR_AP1302_SINK=0
    CROSSBAR_AP1302_SOURCE=3
    AP1302_ISI_SINK=0

    # Pixel Format
    AP1302_V4L2_FORMAT=${3}
    AP1302_MEDIA_CTRL_FORMAT=$(v4l2_format_to_media_ctrl "ap1302" "${AP1302_V4L2_FORMAT}")

    if [ -z "${AP1302_MEDIA_CTRL_FORMAT}" ]; then
        echo "Unsupported V4L2 format for the AP1302: ${AP1302_V4L2_FORMAT}"
        show_help
    fi

    # Resolution
    set -- $(get_ap1302_resolution_from_mode "${VIDEO_MODE}")
    AP1302_WIDTH="${1}"
    AP1302_HEIGHT="${2}"
    AP1302_RES="${AP1302_WIDTH}x${AP1302_HEIGHT}"

    if [ -z "${AP1302_WIDTH}" ] || [ -z "${AP1302_HEIGHT}" ]; then
        echo "Could not determine AP1302 resolution from mode ${VIDEO_MODE}"
        show_help
    fi

    # Configure pipeline formats
    media_ctl_set ${AP1302_SENSOR} ${AP1302_SENSOR_SOURCE} "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}" "${VIDEO_FPS}"
    media_ctl_set ${AP1302_SENSOR} ${AP1302_SENSOR_SINK} "SGRBG10_1X10" "${AP1302_RES}"
    media_ctl_set ${AP1302_CSI} ${AP1302_CSI_SOURCE} "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}"
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SINK} "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}"
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SOURCE} "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}"
    media_ctl_set ${AP1302_ISI} ${AP1302_ISI_SINK} "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}"

    if ! dtbo_is_loaded "imx8mp-imdt-pico-flir-boson.dtbo"; then
        # Configure the unused ISI route to match the AP1302s route.
        # This prevents the error in V4L2:
        # error with STREAMON 32 (Broken pipe):
        # "crossbar":4 -> "mxc_isi.1":0 FAILED: src=1280x720 ... sink=640x512 
        media_ctl_set "mxc_isi.1" 0 "${AP1302_MEDIA_CTRL_FORMAT}" "${AP1302_RES}"
    fi

    # Set capture format on video node
    v4l2-ctl -d "${VIDEO_DEVICE}" --set-fmt-video=width="${AP1302_WIDTH}",height="${AP1302_HEIGHT}",pixelformat="${AP1302_V4L2_FORMAT}"

    echo "AP1302 setup complete!"
}


if [ $# -lt 4 ]; then
    show_help
fi

detect_ap1302_wrong_overlay
wait_for_media_devnode

if ! wait_for_camera "${2}"; then
    echo "Error: could not access camera ${VIDEO_DEVICE}"
    exit 1
fi

SETUP_DEVICE=${1}

case "${SETUP_DEVICE}" in
    "ap1302")
        if dtbo_is_loaded "imx8mp-imdt-pico-flir-boson-standalone.dtbo"; then
            echo "Note: imx8mp-imdt-pico-flir-boson-standalone.dtbo is loaded. Skipping AP1302 setup."
            exit 0
        fi
        setup_ap1302 "${2}" "${3}" "${4}" "${5}"
    ;;
    "boson") 
        if ! dtbo_is_loaded "imx8mp-imdt-pico-flir-boson*.dtbo"; then
            echo "Note: Neither mx8mp-imdt-pico-flir-boson.dtbo nor imx8mp-imdt-pico-flir-boson-standalone.dtbo is loaded."
            echo "Skipping Boson setup."
            exit 0
        fi
        setup_flir_boson "${2}" "${3}" "${4}"
    ;;
    *) echo "Error: Unknown device ${SETUP_DEVICE}" && show_help
    ;;
esac
