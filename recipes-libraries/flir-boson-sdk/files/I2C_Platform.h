#ifndef I2C_PLATFORM_H
#define I2C_PLATFORM_H

#define DEFAULT_BOSON_I2C_BUS  "/dev/i2c-3"
#define DEFAULT_BOSON_I2C_ADDR 0x6a

int I2C_open(const char* bus, int addr);

#endif
