# meta-imdt-flir-boson

A meta-layer to add Flir Boson camera support to IMDT platforms.
Note: Currently tested on the following platforms:
 - IMDT Pico-EM (i.MX8)

 ## What's included

- flir-boson-kernel-module: A kernel driver for the Flir Boson camera from Videology (with IMDT patches).
- camera-setup: A systemd service that configures the media pipelines for the AP1302 and the Flir Boson camera.
- flir-boson-example-pipelines: A set of scripts with some demo gstreamer pipelines for capture/testing.
- flir-boson-sdk: The Python SDK from Videology, allows userspace Python scripts to communicate with the camera to 
  configure it e.g. color LUT etc.

## How to use

### Build a Flir Boson compatible image

1. Clone this repository into your sources/ directory:
```bash
$ cd <imdt-bsp-dir>/sources
$ git clone git@github.com:imd-tec/meta-imdt-flir-boson.git
$ cd -
```

2. Source the Python virtual environment to setup Kas
```bash
source venv/bin/activate
```

2. Build the image core or multimedia image:
```bash
$ kas-container build sources/meta-imdt-flir-boson/kas/imdt-flir-boson-core.yml
```
or
```bash
$ kas-container build sources/meta-imdt-flir-boson/kas/imdt-flir-boson-multimedia.yml
```

3. Deploy the image onto the device as usual (SD Card flash/UUU/SWUpdate)

4. Boot the device with the AP1302 and Boson camera connected

5. Try a capture from the Flir-Boson by executing the following on the device:
```bash
$ flir-boson-snapshot.sh
```

A successful capture is indicated by output similar to the following output:
```
Setting pipeline to PAUSED ...
Pipeline is live and does not need PREROLL ...
Pipeline is PREROLLED ...
Setting pipeline to PLAYING ...
New clock: GstSystemClock
[57928.200419] flir_boson 3-006a: STREAM: Powering on camera...
Redistribute latency...
[57929.693994] flir_boson 3-006a: STREAM: Powering off camera...
Got EOS from element "pipeline0".
Execution ended after 0:00:01.510584000
Setting pipeline to NULL ...
Freeing pipeline ...
Snapshot Taken! File written to: /tmp/boson.jpg
```
Note: By default the file is written to /tmp/boson.jpg. You can specify a custom path if nessesary.

### Change color scheme (look-up-table)

The Boson SDK comes with a Python tool to change the colour scheme. To set it, run the following command:
```bash
$ flir-color-lut -p <i2c-port> <lut-id>
```

Note: the i2c port for the Pico-EM is "3".

The available "lut-ids" are:

- whitehot
- default
- blackhot
- rainbow
- rainbow_hc
- ironbow
- lava
- arctic
- globow
- gradedfire
- hottest
- emberglow
- aurora

### Troubleshooting
Run the following command on the device to confirm that the media pipeline has been brought up:
```bash
$ media-ctl -p
```

<details>

<summary>The output should resemble this (on a Pico-EM):</summary>

```
Media controller API version 6.6.52

Media device information
------------------------
driver          mxc-isi
model           FSL Capture Media Device
serial
bus info        platform:32e00000.isi
hw revision     0x0
driver version  6.6.52

Device topology
- entity 1: crossbar (5 pads, 5 links, 2 routes)
            type V4L2 subdev subtype Unknown flags 0
            device node name /dev/v4l-subdev0
        routes:
                0/0 -> 3/0 [ACTIVE]
                1/0 -> 4/0 [ACTIVE]
        pad0: Sink
                [stream:0 fmt:YUYV8_1X16/2592x1944 field:none]
                <- "mxc-mipi-csi2.0":4 [ENABLED,IMMUTABLE]
        pad1: Sink
                [stream:0 fmt:UYVY8_1X16/640x512 field:none]
                <- "mxc-mipi-csi2.1":4 [ENABLED,IMMUTABLE]
        pad2: Sink
                <- "mxc_isi.output":0 [ENABLED,IMMUTABLE]
        pad3: Source
                [stream:0 fmt:YUYV8_1X16/2592x1944 field:none]
                -> "mxc_isi.0":0 [ENABLED,IMMUTABLE]
        pad4: Source
                [stream:0 fmt:UYVY8_1X16/640x512 field:none]
                -> "mxc_isi.1":0 [ENABLED,IMMUTABLE]
- entity 7: mxc_isi.0 (2 pads, 2 links, 0 routes)
            type V4L2 subdev subtype Unknown flags 0
            device node name /dev/v4l-subdev1
        pad0: Sink
                [stream:0 fmt:YUYV8_1X16/2592x1944 field:none
                 compose.bounds:(0,0)/2592x1944
                 compose:(0,0)/2592x1944]
                <- "crossbar":3 [ENABLED,IMMUTABLE]
        pad1: Source
                [stream:0 fmt:YUV8_1X24/2592x1944 field:none colorspace:jpeg xfer:srgb ycbcr:601 quantization:full-range
                 crop.bounds:(0,0)/2592x1944
                 crop:(0,0)/2592x1944]
                -> "mxc_isi.0.capture":0 [ENABLED,IMMUTABLE]

- entity 10: mxc_isi.0.capture (1 pad, 1 link)
             type Node subtype V4L flags 0
             device node name /dev/video0
        pad0: Sink
                <- "mxc_isi.0":1 [ENABLED,IMMUTABLE]

- entity 18: mxc_isi.1 (2 pads, 2 links, 0 routes)
             type V4L2 subdev subtype Unknown flags 0
             device node name /dev/v4l-subdev2
        pad0: Sink
                [stream:0 fmt:UYVY8_1X16/640x512 field:none
                 compose.bounds:(0,0)/640x512
                 compose:(0,0)/640x512]
                <- "crossbar":4 [ENABLED,IMMUTABLE]
        pad1: Source
                [stream:0 fmt:YUV8_1X24/640x512 field:none colorspace:jpeg xfer:srgb ycbcr:601 quantization:full-range
                 crop.bounds:(0,0)/640x512
                 crop:(0,0)/640x512]
                -> "mxc_isi.1.capture":0 [ENABLED,IMMUTABLE]
                - entity 21: mxc_isi.1.capture (1 pad, 1 link)
                             type Node subtype V4L flags 0
                             device node name /dev/video1
                        pad0: Sink
                                <- "mxc_isi.1":1 [ENABLED,IMMUTABLE]
                
- entity 29: mxc_isi.output (1 pad, 1 link)
              type Node subtype V4L flags 0
        pad0: Source
                -> "crossbar":2 [ENABLED,IMMUTABLE]

- entity 36: mxc-mipi-csi2.0 (5 pads, 2 links)
              type Node subtype V4L flags 0
              device node name /dev/v4l-subdev3
        pad0: Sink
                <- "ap1302.3-003c":0 [ENABLED]
        pad1: Sink
        pad2: Sink
        pad3: Sink
        pad4: Source
                -> "crossbar":0 [ENABLED,IMMUTABLE]

- entity 44: mxc-mipi-csi2.1 (5 pads, 2 links)
              type Node subtype V4L flags 0
              device node name /dev/v4l-subdev4
        pad0: Sink
                <- "flir_boson":0 [ENABLED]
        pad1: Sink
        pad2: Sink
        pad3: Sink
        pad4: Source
                -> "crossbar":1 [ENABLED,IMMUTABLE]

- entity 52: flir_boson (1 pad, 1 link, 0 routes)
              type V4L2 subdev subtype Sensor flags 0
              device node name /dev/v4l-subdev5
        pad0: Source
                [stream:0 fmt:UYVY8_1X16/640x512 field:none colorspace:srgb xfer:709 ycbcr:601 quantization:full-range]
                -> "mxc-mipi-csi2.1":0 [ENABLED]
- entity 56: ap1302.3-003c (3 pads, 2 links, 0 routes)
              type V4L2 subdev subtype Unknown flags 0
              device node name /dev/v4l-subdev7
        pad0: Source
                [stream:0 fmt:YUYV8_1X16/2592x1944@1/30 field:none colorspace:srgb
                  crop.bounds:(0,0)/4209x3121
                  crop:(0,0)/4209x3121]
                -> "mxc-mipi-csi2.0":0 [ENABLED]
        pad1: Sink
                [stream:0 fmt:SGRBG10_1X10/4208x3120@1/30 field:none colorspace:srgb
                  crop.bounds:(0,0)/4209x3121
                  crop:(0,0)/4209x3121]
                <- "ar1335 0":0 [ENABLED,IMMUTABLE]
        pad2: Sink
                [stream:0 fmt:SGRBG10_1X10/4208x3120@1/30 field:none colorspace:srgb
                  crop.bounds:(0,0)/4209x3121
                  crop:(0,0)/4209x3121]

- entity 60: ar1335 0 (1 pad, 1 link, 0 routes)
              type V4L2 subdev subtype Sensor flags 0
              device node name /dev/v4l-subdev6
        pad0: Source
                [stream:0 fmt:SGRBG10_1X10/4208x3120 field:none colorspace:srgb]
                -> "ap1302.3-003c":1 [ENABLED,IMMUTABLE]
```
</details>

If the media-ctl command fails with:
```bash
Failed to enumerate /dev/media0 (-2)
```

Check that **both** cameras are attached and check if the ap1302 driver has loaded correctly,
run the following command on the device:
```bash
$ dmesg | grep "ap1302"
```
and if you see an error like the one below:
```
[   14.139502] ap1302 3-003c: Firmware retries enabled
[   14.158507] SPI driver ap1302-spi has no spi_device_id for onnn,ap1302
[   14.165258] ap1302-spi spi1.1: driver probed successfully
[   14.203086] ap1302 3-003c: __ap1302_write: register 0xf038 write failed: -6
```

Then try the following commands:
```bash
$ modprobe -r ap1302
$ modprobe ap1302
```

And try the media-ctl command again. Note: the camera-setup service should perform this workaround
programatically on boot. We are still working for a more robust fix here.

## Known Issues

- There is a startup issue with the AP1302 driver when the Boson driver is introduced on the same I2C node.
  Performing I2C reads/writes can be unreliable on startup, if one fails then the driver must manually be reloaded.
