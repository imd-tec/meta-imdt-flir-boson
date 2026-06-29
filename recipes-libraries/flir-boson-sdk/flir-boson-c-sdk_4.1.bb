DESCRIPTION = "Flir Boson C SDK for thermal imager over mipi"
HOMEPAGE = "https://github.com/VideologyInc/flir_boson_kernel_module"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://License.txt;md5=bcbce5abc4a0050677b9bee08b63ab43"

require flir-boson-sdk.inc

SRC_URI += " \
    file://ClientFiles_C_Makefile \
    file://FSLP_Makefile \
    file://libFSLP.pc \
    file://libBosonSDK.pc \
    file://I2C_Platform.c \
    file://I2C_Platform.h \
    file://Example.c \
"

S = "${WORKDIR}/git"

# Use the I2C client backend
TARGET_CFLAGS += "-DUSE_I2C_SLAVE_CP"

do_configure:prepend() {
    # The Makefiles in the repo are not Yocto friendly, e.g. hardcode the GCC binary, add incompatible
    # compiler flags etc. Copy over our working versions to allow the build to complete.
    cp ${WORKDIR}/ClientFiles_C_Makefile "${S}/BosonSDKC/ClientFiles_C/Makefile"
    cp ${WORKDIR}/FSLP_Makefile "${S}/BosonSDKC/FSLP_Files/Makefile"

    # The C SDK does not provide an I2C backend, only a UART one. Add our own.
    cp ${WORKDIR}/I2C_Platform.c "${S}/BosonSDKC/ClientFiles_C/I2C_Platform.c"
    cp ${WORKDIR}/I2C_Platform.h "${S}/BosonSDKC/ClientFiles_C/I2C_Platform.h"

    # Add an example application that uses the I2C backend
    cp ${WORKDIR}/Example.c "${S}/BosonSDKC/ClientFiles_C/Example.c"
}

do_compile() {
    # Build FSLP shared library from source
    cd ${S}/BosonSDKC/FSLP_Files
    oe_runmake

    # Copy FSLP library to ClientFiles_C for SDK build
    cp ${S}/BosonSDKC/FSLP_Files/FSLP_64.so ${S}/BosonSDKC/ClientFiles_C/

    # Build C SDK shared library and example application
    cd ${S}/BosonSDKC/ClientFiles_C
    oe_runmake
}

do_install() {
    # Install versioned libraries
    install -d ${D}${libdir}
    install -m 0755 ${S}/BosonSDKC/FSLP_Files/FSLP_64.so ${D}${libdir}/libFSLP.so.${PV}
    install -m 0755 ${S}/BosonSDKC/ClientFiles_C/C_SDK_64.so ${D}${libdir}/libBosonSDK.so.${PV}

    # Create soname and linker stub symlinks
    cd ${D}${libdir}
    ln -sf libFSLP.so.${PV}     libFSLP.so.4
    ln -sf libFSLP.so.4         libFSLP.so
    ln -sf libBosonSDK.so.${PV} libBosonSDK.so.4
    ln -sf libBosonSDK.so.4     libBosonSDK.so
    cd -

    # Install headers
    install -d ${D}${includedir}/boson
    install -m 0644 ${S}/BosonSDKC/ClientFiles_C/*.h ${D}${includedir}/boson/

    # Install example binary
    install -d ${D}${bindir}
    install -m 0755 ${S}/BosonSDKC/ClientFiles_C/Example_64.a ${D}${bindir}/flir-boson-c-sdk-example

    # Install pkgconfig files
    install -d ${D}${libdir}/pkgconfig
    install -m 0644 ${WORKDIR}/libFSLP.pc     ${D}${libdir}/pkgconfig/
    install -m 0644 ${WORKDIR}/libBosonSDK.pc ${D}${libdir}/pkgconfig/
}

FILES:${PN} = " \
    ${libdir}/libFSLP.so.${PV} \
    ${libdir}/libFSLP.so.4 \
    ${libdir}/libBosonSDK.so.${PV} \
    ${libdir}/libBosonSDK.so.4 \
    ${bindir}/flir-boson-c-sdk-example \
"

FILES:${PN}-dev = " \
    ${libdir}/libFSLP.so \
    ${libdir}/libBosonSDK.so \
    ${includedir}/boson/ \
    ${libdir}/pkgconfig/ \
"

# Prevent QA complaints about build paths in debug info
INSANE_SKIP:${PN} = "buildpaths"
