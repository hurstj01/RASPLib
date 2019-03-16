
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "MPU9250.h"

MPU9250 accelgyro;
int16_t ax, ay, az;
int16_t gx, gy, gz;
int16_t mx, my, mz;

extern "C" void MPU9250_Init(void)
{
    Wire.begin();
    accelgyro.initialize();
}

extern "C" void MPU9250_ReadRAW(int* pfData)
{

    accelgyro.getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
	
    pfData[0]=ax;
	pfData[1]=ay;
    pfData[2]=az;
    pfData[3]=gx;
    pfData[4]=gy;
    pfData[5]=gz;
    pfData[6]=mx;
    pfData[7]=my;
    pfData[8]=mz;
    pfData[9]=accelgyro.getTemperature();
	
}
