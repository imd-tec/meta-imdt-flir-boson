DESCRIPTION = "Flir Boson Python SDK for thermal imager over mipi"
HOMEPAGE = "https://github.com/VideologyInc/flir_boson_kernel_module"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://License.txt;md5=bcbce5abc4a0050677b9bee08b63ab43"

inherit python_setuptools_build_meta
DEPENDS += "python3-setuptools-scm-native"

SRC_URI = "git://github.com/VideologyInc/flir_boson_kernel_module.git;protocol=https;branch=master"
SRCREV = "5e433a23c2f787551648b4d88325b36f0a88c558"

RDEPENDS:${PN} += "${PYTHON_PN}-fcntl ${PYTHON_PN}-ctypes ${PYTHON_PN}-smbus2"

S = "${WORKDIR}/git"
