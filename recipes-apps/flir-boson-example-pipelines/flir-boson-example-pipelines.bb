SUMMARY = "Flir Boson Example Gstreamer Pipelines"
DESCRIPTION = "Example Gstreamer Pipelines to test the streaming capabilites of the Flir Boson"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://flir-boson-snapshot.sh \
    file://flir-boson-fps-test.sh \
    file://flir-boson-mp4.sh \
    file://flir-boson-simultaneous-raw-recording.sh \
    file://flir-boson-y14-snapshot.sh \
    file://y14-to-pgm.py \
"

RDEPENDS:${PN} = "gstreamer1.0 gstreamer1.0-plugins-bad camera-setup python3-core"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/flir-boson-snapshot.sh ${D}${bindir}/flir-boson-snapshot.sh
    install -m 0755 ${WORKDIR}/flir-boson-fps-test.sh ${D}${bindir}/flir-boson-fps-test.sh
    install -m 0755 ${WORKDIR}/flir-boson-mp4.sh ${D}${bindir}/flir-boson-mp4.sh
    install -m 0755 ${WORKDIR}/flir-boson-simultaneous-raw-recording.sh ${D}${bindir}/flir-boson-simultaneous-raw-recording.sh
    install -m 0755 ${WORKDIR}/flir-boson-y14-snapshot.sh ${D}${bindir}/flir-boson-y14-snapshot.sh
    install -m 0755 ${WORKDIR}/y14-to-pgm.py ${D}${bindir}/y14-to-pgm.py
}

FILES:${PN} = " \
    ${bindir}/flir-boson-snapshot.sh \
    ${bindir}/flir-boson-fps-test.sh \
    ${bindir}/flir-boson-mp4.sh \
    ${bindir}/flir-boson-simultaneous-raw-recording.sh \
    ${bindir}/flir-boson-y14-snapshot.sh \
    ${bindir}/y14-to-pgm.py \
"
