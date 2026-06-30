FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "5663bc368e77a658af8b74472fcf6797650218b3"

# TODO: Remove patch once the Boson device tree overlay is working.
SRC_URI += "file://0001-Add-imx8mp-imdt-pico-flir-boson-dtsi.patch"
# TODO: Remove once this (or equivalent) change has been merged into linux-imdt
SRC_URI += "file://0002-Move-the-HR_CAM_EN-GPIO-into-its-own-power-regulator.patch"
# TODO: Remove once this (or equivalent) change has been merged into linux-imdt
SRC_URI += "file://0003-Add-4k-support-when-bypass-ISI-channel.patch"

# Patches from VideologyInc for format support: 
# https://github.com/VideologyInc/meta-scailx-flir/tree/master/meta-scailx-flir/recipes-kernel/linux/linux-imx
SRC_URI += "file://0004-isi-fmt-add-extra-ISI-output-modes.patch"
SRC_URI += "file://0005-isi-cap-add-RAW-input-modes-negotiate-src-fmt-to-req.patch"
SRC_URI += "file://0006-csi2-sam-add-formats-and-negotiate-formats-with-SRC.patch"
