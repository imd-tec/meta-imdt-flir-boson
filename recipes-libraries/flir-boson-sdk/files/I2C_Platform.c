#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <errno.h>
#include "I2C_Connector.h"
#include "I2C_Platform.h"

static int i2c_fd = -1;
static int i2c_addr = DEFAULT_BOSON_I2C_ADDR;
static char i2c_bus[128];

int I2C_open(const char* bus, int addr) {
    if (i2c_fd >= 0) {
        return 0;
    }

    if (bus == NULL) {
        strncpy(i2c_bus, DEFAULT_BOSON_I2C_BUS, sizeof(i2c_bus) - 1);
    } else {
        strncpy(i2c_bus, bus, sizeof(i2c_bus) - 1);
    }

    i2c_addr = addr;
    i2c_bus[sizeof(i2c_bus) - 1] = '\0';

    i2c_fd = open(i2c_bus, O_RDWR);
    if (i2c_fd < 0) {
        fprintf(stderr, "Failed to open I2C bus: %s (%s)\n", i2c_bus, strerror(errno));
        return -1;
    }

    if (ioctl(i2c_fd, I2C_SLAVE_FORCE, i2c_addr) < 0) {
        fprintf(stderr, "Failed to configure I2C bus as slave: %s (%s)\n", i2c_bus, strerror(errno));
        close(i2c_fd);
        i2c_fd = -1;
        return -1;
    }

    return 0;
}

FLR_RESULT I2C_read(uint8_t* readData, uint32_t readBytes) {
    if (i2c_fd < 0) {
        return FLR_COMM_NO_DEV;
    }
       
    if (read(i2c_fd, readData, readBytes) != (ssize_t)readBytes) {
        return FLR_I2C_ERROR;
    }

    return FLR_OK;
}

FLR_RESULT I2C_write(uint8_t* writeData, uint32_t writeBytes) {
    if (i2c_fd < 0) {
        return FLR_COMM_NO_DEV;
    }

    if (write(i2c_fd, writeData, writeBytes) != (ssize_t)writeBytes) {
        return FLR_I2C_ERROR;
    }

    return FLR_OK;
}
