FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRCREV = "1279b82c87483e9567760fa97e7c29fc25e3aa84"

SRC_URI += "file://0001-Build-the-flir-boson-nodes-as-a-device-tree-overlay.patch"

# TODO: Remove once this (or equivalent) change has been merged into linux-imdt
SRC_URI += "file://0002-Move-the-HR_CAM_EN-GPIO-into-its-own-power-regulator.patch"
