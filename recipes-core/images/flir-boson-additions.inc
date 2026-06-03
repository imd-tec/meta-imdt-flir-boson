IMAGE_INSTALL:append = " \
    flir-boson-example-pipelines \
    flir-boson-kernel-module \
    flir-boson-sdk \
    camera-setup \
"
# TODO: Uncomment once device tree overlay is implemented and working
# EXTRA_IMAGEDEPENDS += " flir-boson-dtbo "
