SUMMARY = "Flir Boson Example Gstreamer Pipelines"
DESCRIPTION = "Example Gstreamer Pipelines to test the streaming capabilites of the Flir Boson"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://flir-boson-snapshot.sh \
    file://flir-boson-fps-test.sh \
"

RDEPENDS:${PN} = "gstreamer1.0 gstreamer1.0-plugins-bad"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/flir-boson-snapshot.sh ${D}${bindir}/flir-boson-snapshot.sh
    install -m 0755 ${WORKDIR}/flir-boson-fps-test.sh ${D}${bindir}/flir-boson-fps-test.sh
}

FILES:${PN} = " \
    ${bindir}/flir-boson-snapshot.sh \
    ${bindir}/flir-boson-fps-test.sh \
"
