#!/bin/sh
# Configure FLIR Boson or AP1302 V4L2 pipeline
# Sets correct format through the media pipeline before capture

function show_help() {
    echo "Usage: flir-boson-setup.sh <video-device> <video-dev-node>"
    echo "Video Devices:"
    echo "boson - Flir Boson thermal imaging camera."
    echo "ap1302 - The ap1302 external ISP."
    exit 1
}

function detect_ap1302_startup_failure() {
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

function wait_for_media_devnode() {
    echo "Waiting for /dev/media0 to be created..."
    TIME_WAITED=0

    while [ ! -e /dev/media0 ]; do
        sleep 0.1
        ((TIME_WAITED+=1));

        if [[ $TIME_WAITED -eq 20 ]]; then
            detect_ap1302_startup_failure
            TIME_WAITED=0
        fi
    done
}

function media_ctl_set() {
    MEDIA_DEVICE=${1}
    MEDIA_PAD=${2}
    MEDIA_FMT=${3}
    MEDIA_RES=${4}
    (set -x; media-ctl -V "\"${MEDIA_DEVICE}\":${MEDIA_PAD} [fmt:${MEDIA_FMT}/${MEDIA_RES}]")
}

function setup_flir_boson() {
    VIDEO_DEVICE=${1}
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
    BOSON_RES="640x512"

    # Configure pipeline formats
    media_ctl_set "flir_boson" ${BOSON_SENSOR_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set ${BOSON_CSI} ${BOSON_CSI_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SINK} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set "crossbar" ${CROSSBAR_BOSON_SOURCE} ${BOSON_FORMAT} ${BOSON_RES}
    media_ctl_set ${BOSON_ISI} ${BOSON_ISI_SINK} ${BOSON_FORMAT} ${BOSON_RES}

    # Set capture format on video node
    v4l2-ctl -d ${VIDEO_DEVICE} --set-fmt-video=width=640,height=512,pixelformat=YUYV

    echo "Flir Boson setup complete!"
}

function setup_ap1302() {
    VIDEO_DEVICE=${1}
    echo "Setting up AP1302 on ${VIDEO_DEVICE}"

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
    AP1302_RES="2592x1944"

    # Configure pipeline formats
    media_ctl_set ${AP1302_SENSOR} ${AP1302_SENSOR_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set ${AP1302_CSI} ${AP1302_CSI_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SINK} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set "crossbar" ${CROSSBAR_AP1302_SOURCE} ${AP1302_FORMAT} ${AP1302_RES}
    media_ctl_set ${AP1302_ISI} ${AP1302_ISI_SINK} ${AP1302_FORMAT} ${AP1302_RES}

    # Set capture format on video node
    v4l2-ctl -d ${VIDEO_DEVICE} --set-fmt-video=width=2592,height=1944,pixelformat=YUYV

    echo "AP1302 setup complete!"
}


if [[ $# -lt 2 ]]; then
    show_help
fi

wait_for_media_devnode

SETUP_DEVICE=${1}

case "${SETUP_DEVICE}" in
    "ap1302") setup_ap1302 ${2}
    ;;
    "boson") setup_flir_boson ${2}
    ;;
    *) echo "Error: Unknown device ${SETUP_DEVICE}" && show_help
    ;;
esac
