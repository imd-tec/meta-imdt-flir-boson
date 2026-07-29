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

## What's new
- v1.2.0:
  - Configure the Flir Boson with a device tree overlay instead of building it into the base device tree. 
    Check the "Setup Flir Boson Device Tree Overlay" section for more information.
  - Fix issue where the Boson would be configured by camera-setup before the hardware had been initialised.
  - Add NV12 pixel format and FPS parameter for the AP1302 in camera-setup.sh, default to 30 FPS.
  - Add the ability to build images from first principles from within this meta-layer.
    Check the "Build from first principles" section for more information.
  - Add github CI actions.
- v1.1.0:
  - Fix issue where the AP1302 could not stream at a full 5MP whilst the Flir Boson camera was also streaming (i.MX8).
  - Add support for the flir-boson C SDK
  - Add support in camera-setup.sh to configure the AP1302 and Flir Boson output resolution.
  - Add support in camera-setup.sh to configure the AP1302 and Flir Boson pixel output formats.
  - Add more example pipelines:
    - flir-boson-mp4.sh: Records a video stream to an MP4 file.
    - flir-boson-simultaneous-raw-recording.sh: Records the raw video stream from both the AP1302 and Flir Boson simultaneously into separate .mkv files.
    - flir-boson-y14-snapshot.sh: Takes a snapshot of the Flir Boson camera in Y14 format.

## How to use

### Build a Flir Boson compatible image

#### Build from first principles

1. Create a directory for the Yocto build:
```bash
$ mkdir imdt-bsp
```

2. Clone this meta-layer into the directory:
```bash
$ cd imdt-bsp
$ git clone git@github.com:imd-tec/meta-imdt-flir-boson.git
```

3. Install Kas
```bash
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install kas==4.7
```

On following sessions, source the venv to get access to the kas binary
```bash
$ source venv/bin/activate
```

4. Build the image core or multimedia image:
```bash
$ kas-container build meta-imdt-flir-boson/kas/imdt-flir-boson-core.yml
```
or
```bash
$ kas-container build meta-imdt-flir-boson/kas/imdt-flir-boson-multimedia.yml
```

#### Build from an existing IMDT BSP build
If you are starting from scratch, please follow the "Building the Yocto Image" section in the 
Getting Started Guide for your IMDT platform:

Pico-EM: [IMDT Pico - Getting Started Guide.pdf](https://drive.google.com/file/d/1_8spmvY4PkHqKvsojBL_bl1Poif28Mbh/view?usp=drive_link)

Once you have a build complete, perform these steps:

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

Calling kas-container on the imdt-flir-boson yml files will regenerate your BBLAYERS file,
this will automatically add the flir-boson components to imdt-image-core/multimedia.

3. Deploy the image onto the device as usual (SD Card flash/UUU/SWUpdate)

4. Boot the device with the AP1302 (with selected sensor e.g. AR0522, AR1335) on CSI0, and the Boson camera connected on CSI1.

5. Configure the Flir Boson Device Tree Overlay. Check the "Setup Flir Boson Device Tree Overlay" section for more information.

6. Try a capture from the Flir-Boson by executing the following on the device:
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
Note: By default the file is written to /tmp/boson.jpg. You can specify a custom path if necessary.

### Setup Flir Boson Device Tree Overlay

1. Connect a serial terminal to the Pico-EM and power the device on.

2. As the device is booting, interrupt the U-Boot boot count down to get access to the U-Boot shell by pressing any key on the keyboard.

3. Run one of the following commands in the U-Boot shell depending on your system configuration
For systems with Flir Boson + AP1302/AR1335:
```bash
u-boot=> setenv apply_overlays "imx8mp-imdt-pico-flir-boson.dtbo"
```

For systems with Flir Boson + AP1302/AR052(1/2)::
```bash
u-boot=> setenv apply_overlays "imx8mp-imdt-pico-flir-boson.dtbo imx8mp-imdt-pico-ar0521.dtbo"
```

For systems with just Flir Boson:
```bash
u-boot=> setenv apply_overlays "imx8mp-imdt-pico-flir-boson-standalone.dtbo"
```

Then run the following commands to save the variable changes and reboot:
```bash
u-boot=> saveenv
u-boot=> reset
```

Note: The AP1302 should always be on CSI0, the Flir Boson should always be on CSI1.
If your system has a custom configuration then manual device tree changes are required.

To set this configuration as default for your image, it is recommended to either patch U-Boot to set the
CONFIG_EXTRA_ENV_SETTINGS macro accordingly.

### Change camera resolution and pixel format

To change the camera resolution, use the included `camera-setup.sh` script:
```bash
$ camera-setup.sh <boson/ap1302> <video-devnode> <resolution> <pixel-format> (FPS)
```

For the Pico-EM, the video-devnodes are typically "/dev/video0" for the ap1302 and "/dev/video1" for the boson.

The FPS option only applies to the AP1302 and is an optional parameter. If no FPS value is provided, a default
value of "30" is used.

The available resolutions and pixel formats for each camera are:

Flir Boson Resolutions:

| Resolution Name   | Description                                               |
| ----------------- | --------------------------------------------------------- |
| full              | Full resolution (640x512).                                |
| full-telemetry    | Full resolution with additional telemetry line (640x514). |
| subsampled        | Subsampled resolution (320x256).                          |

Flir Boson Pixel Formats:

| Format Name   | Description                | v4l2 Format Name   | gstreamer Format Name |
| ------------- | -------------------------- | ------------------ | --------------------- |
| YUYV          | Color 4:2:2 pixel format.  | UYVY8_1X16         | YUY2                  |
| Y14           | Mono 1:1:4 pixel format.   | Y14_1X14           | GRAY14_LE             |
| GREY          | Mono 1:1:1 pixel format.   | Y8_1X8             | GRAY8                 |

AP1302 Resolutions:

| Resolution Name   | Description                                               |
| ----------------- | --------------------------------------------------------- |
| 12mp              | 12MP resolution (4096x3072).                              |
| 5mp               | 5MP resolution (2592x1944).                               |
| 2k                | DCI 2k resolution (2048x1080).                            |
| 1080p             | 1080p resolution (1920x1080).                             |
| 1080-4:3          | HD resolution with 4:3 aspect ratio (1440x1080).          |
| 720p              | 720p - 720p resolution (1280x720).                        |

AP1302 Pixel Formats:

| Format Name   | Description                | v4l2 Format Name   | gstreamer Format Name |
| ------------- | -------------------------- | ------------------ | --------------------- |
| YUYV          | Color 4:2:2 pixel format.  | UYVY8_1X16         | YUY2                  |
| RGB3          | RGB 3:3:2 pixel format.    | RGB888_1X24        | RGB                   |
| BGR3          | BGR 3:3:2 pixel format.    | BGR888_1X24        | BGR                   |

### Get current camera configuration

To programatically check what the current camera configuration is, you can use the "get-camera-setup.sh" script.

```bash
$ get-camera-setup.sh <video-devnode> <width/height/pixelformat/pixelformat-gst>
```

### Change color scheme (look-up-table)

The Boson SDK comes with a Python tool to change the colour scheme. To set it, run the following command:
```bash
$ flir-color-lut -p <i2c-port> set <lut-id>
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

### Camera Setup Service

To configure the media pipeline for the AP1302 and Flir Boson, a systemd service "camera-setup.service" is started on boot.
This will configure the resolution/format for each camera. Currently this configures the AP1302 in 5MP mode (2592x1944) YUYV8, the Flir Boson in 640x512 YUYV8.

The source for this service is available in recipes-apps/camera-setup/files.

### Camera test scripts

- flir-boson-fps-test.sh - Get a readout of the maximum framerate from the Flir Boson's video stream.
- flir-boson-mp4.sh - Record the output of the Flir Boson to an MP4 file.
- flir-boson-snapshot.sh - Capture a frame from the Flir Boson and save it as a JPEG.
- flir-boson-simultaneous-raw-recording.sh - Capture two raw feeds simultaneously from the Flir Boson and the AP1302 
  - Note: It is advised to create a separate partition for storing these captures as they are large. Saving them to the default
          tmpfs location will only allow for around 5 seconds of capture per sensor before running out of space.
- flir-get-info - A script that utilises the Flir Boson Python SDK to print manufacturing information about the camera.

### Camera Output Modes

The following video output modes for the Flir Boson have been tested:

Single MIPI:

| MIPI TYPE                       | DVO TYPE | Tested    |
| ------------------------------- | -------- | --------- |
| RAW8 (postAGC monochrome video) | MONO8    | **✅**    |
| UYVY (postAGC color video)      | COLOR    | **✅**    |
| RAW14 (NUC output)              | MONO14   | **✅**    |

Note: RAW14 is not supported by gstreamer, if you are using the Flir Boson inside a gstreamer pipeline, 
please use either the RAW8 or UYVY output modes instead.

Dual MIPI (not compatible with Pico-EM):

| MIPI TYPE [VC0 / VC1] ( Note: RAW8 is postAGC )  | DVO TYPE    | Tested    |
| ------------------------------------------------ | ----------- | --------- |
| RAW8 / RAW14                                     | MONO8MONO14 | ❌         |
| UYVY / RAW14                                     | COLORMONO14 | ❌         |
| UYVY / RAW8                                      | COLORMONO8  | ❌         |

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

Check that the correct device tree overlays have been loaded, and the respective cameras are attached.
if you are using the AP1302, run the following command on the device:
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

- On some HW configurations, there is an intermittent startup issue with the AP1302 driver when the 
  Boson driver is introduced on the same I2C node. Performing I2C reads/writes can be unreliable on startup, 
  if one fails then the driver must manually be reloaded.

- Currently you cannot stream from the AP1302 at 5MP over 30FPS as the AR0521/2 FW is configured for 2-lane MIPI. 
  To stream the AR0521 at 5MP@60FPS, you would need to load the 4-lane MIPI AR0521/2 FW to the AP1302.
  However, we currently don't have the HW to verify this configuration.
