SUMMARY = "Camera setup service"
DESCRIPTION = "Configures the V4L2 media pipeline for the FLIR Boson thermal camera and AP1302 at startup"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = " \
    file://camera-setup.sh \
    file://get-camera-setup.sh \
    file://camera-setup.service \
    file://flir-boson-deps.conf \
"

SYSTEMD_SERVICE:${PN} = "camera-setup.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "v4l-utils media-ctl"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/camera-setup.sh ${D}${bindir}/camera-setup.sh
    install -m 0755 ${WORKDIR}/get-camera-setup.sh ${D}${bindir}/get-camera-setup.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/camera-setup.service ${D}${systemd_system_unitdir}/camera-setup.service

    install -d ${D}${sysconfdir}/modprobe.d
    install -m 0644 ${WORKDIR}/flir-boson-deps.conf ${D}${sysconfdir}/modprobe.d/flir-boson-deps.conf
}

FILES:${PN} = " \
    ${bindir}/camera-setup.sh \
    ${bindir}/get-camera-setup.sh \
    ${systemd_system_unitdir}/camera-setup.service \
    ${sysconfdir}/modprobe.d/flir-boson-deps.conf \
"
