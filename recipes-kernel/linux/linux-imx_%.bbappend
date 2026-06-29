FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "5663bc368e77a658af8b74472fcf6797650218b3"

# TODO: Remove patch once the Boson device tree overlay is working.
SRC_URI += "file://0001-Add-imx8mp-imdt-pico-flir-boson-dtsi.patch"
# TODO: Remove once this (or equivalent) change has been merged into linux-imdt
SRC_URI += "file://0002-Move-the-HR_CAM_EN-GPIO-into-its-own-power-regulator.patch"
# TODO: Remove once this (or equivalent) change has been merged into linux-imdt
SRC_URI += "file://0003-Add-4k-support-when-bypass-ISI-channel.patch"
