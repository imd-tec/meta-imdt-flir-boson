SUMMARY = "FLIR Boson V4L2 kernel module"
DESCRIPTION = "Linux V4L2 subdevice driver for FLIR Boson / Boson+ thermal cameras with MIPI CSI-2 interface."
HOMEPAGE = "https://github.com/VideologyInc/flir_boson_kernel_module"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://License.txt;md5=bcbce5abc4a0050677b9bee08b63ab43"

inherit module

SRC_URI = "git://github.com/VideologyInc/flir_boson_kernel_module.git;protocol=https;branch=master"
SRCREV = "5e433a23c2f787551648b4d88325b36f0a88c558"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-Power-on-the-Boson-Camera-inside-s_stream.patch"

PV = "1.0+git${SRCPV}"

S = "${WORKDIR}/git"

KERNEL_MODULE_PACKAGE_SUFFIX = ""

do_compile() {
    oe_runmake -C "${STAGING_KERNEL_DIR}" \
            M="${S}/flir_boson_v4l2" \
            O="${STAGING_KERNEL_BUILDDIR}" \
            modules
}

do_install() {
    oe_runmake -C "${STAGING_KERNEL_DIR}" \
        M="${S}/flir_boson_v4l2" \
        O="${STAGING_KERNEL_BUILDDIR}" \
        INSTALL_MOD_PATH="${D}/usr" \
        INSTALL_MOD_DIR="extra" \
        KERNELRELEASE="${KERNEL_VERSION}" \
        modules_install
}

FILES:kernel-module-flir-boson = "/usr/lib/modules/${KERNEL_VERSION}/extra/flir-boson.ko"
