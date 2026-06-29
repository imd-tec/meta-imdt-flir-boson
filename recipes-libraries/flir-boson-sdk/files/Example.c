//#include <complex>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <threads.h>
#include "Client_API.h"
#include "EnumTypes.h"
#include "UART_Connector.h"
#include "I2C_Platform.h"

static const char* bus = DEFAULT_BOSON_I2C_BUS;
static int addr = DEFAULT_BOSON_I2C_ADDR;
static int test_flash_enabled = 0;

int parse_args(int argc, const char **argv)
{
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--help", 7) == 0) {
            printf("Usage: %s -p <i2c-dev-node> -a <i2c-address> (-f)\n", argv[0]);
            printf("  -p: i2c dev node for the Flir Boson camera (default: %s)\n", DEFAULT_BOSON_I2C_BUS);
            printf("  -a: i2c address for the Flir Boson camera (default: 0x%02x)\n", DEFAULT_BOSON_I2C_ADDR);
            printf("  -f: test flash operations (default: disabled)\n");
            return -1;
        }
        if (strncmp(argv[i], "-p", 2) == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -p requires an argument\n");
                return -1;
            }
            bus = argv[++i];
        } else if (strncmp(argv[i], "-a", 2) == 0) {
            if (i + 1 >= argc) {
                fprintf(stderr, "Error: -a requires an argument\n");
                return -1;
            }
            addr = (int)strtol(argv[++i], NULL, 0);
        } else if (strncmp(argv[i], "-f", 2) == 0) {
            test_flash_enabled = 1;
        } else {
            fprintf(stderr, "Unknown argument: %s\n", argv[i]);
            return -1;
        }
    }
    return 0;
}

FLR_RESULT test_flash()
{
    uint32_t idx;
	FLR_RESULT result;
    
    printf("\n");
	uint8_t data[256];
	printf("Capture Data[0:255]: ");
	//       memReadCapture(index, offset, num_bytes, empty_data_buffer);
	result = memReadCapture(0, 0, 256, data);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf(" -- ");
	for (idx=0; idx<256; idx++)
	{
		if ( !(idx%16) )
			printf("\n\t");
		printf("  %02X",data[idx]);
	}
	printf("\n");
	printf("Erase Flash: location=%d ",FLR_MEM_LENS_DISTORTION);
	//       memEraseFlash(enum, index);
	result = memEraseFlash(FLR_MEM_LENS_DISTORTION, 1);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf("Success.\n");
	
	printf("\n");
	uint8_t flashdata[64];
	printf("Flash Data[0:64]: ");
	//       memReadFlash(enum, index, offset, num_bytes, empty_data_buffer);
	result = memReadFlash(FLR_MEM_LENS_DISTORTION, 1, 0, 64, flashdata);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf("-- ");
	for (idx=0; idx<64; idx++)
	{
		if ( !(idx%16) )
			printf("\n\t");
		printf("  %02X",flashdata[idx]);
	}
	printf("\n");
	
	uint8_t writedata[64];
	for (idx=0; idx<64; idx++)
	{
		writedata[idx] = idx;
	}
	printf("Write Flash: ");
	result = memWriteFlash(FLR_MEM_LENS_DISTORTION, 1, 0, 64, writedata);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf("success.\n");
	
	printf("\n");
	printf("Confirm Flash Data[0:64]: ");
	//       memReadFlash(enum, index, offset, num_bytes, empty_data_buffer);
	result = memReadFlash(FLR_MEM_LENS_DISTORTION, 1, 0, 64, flashdata);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	for (idx=0; idx<64; idx++)
	{
		if ( !(idx%16) )
			printf("\n\t");
		printf("  %02X",flashdata[idx]);
	}
	printf("\n");
	
	printf("\n");
	printf("Erase Flash: ");
	//       memEraseFlash(enum, index);
	result = memEraseFlash(FLR_MEM_LENS_DISTORTION, 1);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf("success.\n");
}

int main(int argc, const char **argv)
{
	uint32_t idx;
	
	FLR_RESULT result;

	if (parse_args(argc, argv) != 0) {
		return -1;
	}

	if (I2C_open(bus, addr) != 0) {
		fprintf(stderr, "Failed to initialise I2C\n");
		return -1;
	}

	printf("\n");
	printf("CameraSN: ");
	uint32_t camera_sn;
	result = bosonGetCameraSN(&camera_sn);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf(" %d \n", camera_sn);
	
	
	printf("\n");
	FLR_DVO_TYPE_E dvo_src;
	result = dvoGetType(&dvo_src);
	printf("DVO Source:  0x%08X -- 0x%08X \n", result, dvo_src);
	
	
	printf("\n");
	uint32_t major, minor, patch;
	printf("SoftwareRev:  ");
	result = bosonGetSoftwareRev(&major, &minor, &patch);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf(" %u.%u.%u \n", major,minor,patch);
	
	printf("\n");
	FLR_BOSON_SENSOR_PARTNUMBER_T part_num;
	printf("PartNum: ");
	result = bosonGetSensorPN(&part_num);
	if (result)
	{
		printf("Failed with status 0x%08X, exiting.\n",result);
		Close();
		return EXIT_FAILURE;
	}
	printf(" \"%s\"", part_num.value);
	for (idx=0; idx<sizeof(part_num); idx++)
	{
		uint8_t tempchar = part_num.value[idx];
		if ( !(idx%16) )
			printf("\n\t");
		if (tempchar>=32 && tempchar<=125)
		{
			printf(" \"%c\"",tempchar);
		}
		else
		{
			printf("  %02X",tempchar);
		}
	}
	printf("\n");

	if(test_flash_enabled) {
		if(test_flash() == EXIT_FAILURE) {
			return EXIT_FAILURE;
		}
	}
	
	result = bosonRunFFC();
	printf("RunFFC:  0x%08X \n", result);
	
	printf("\n\nClosing...\n");
	Close();
	return EXIT_SUCCESS;

}
