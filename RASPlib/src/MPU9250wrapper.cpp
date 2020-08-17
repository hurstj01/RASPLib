
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "MPU9250.h"

MPU9250 accgyro;
int16_t ax, ay, az;
int16_t gx, gy, gz;
int16_t mx, my, mz;

extern "C" void MPU9250_Init(void)
{
    Wire.begin();
    accgyro.initialize();
	
/*   // Make devAddr public and add this line:
  if(!accgyro.testConnection())
  {
    //Serial.println("Test Connection Failed Changing I2C addr to 0x69");
    accgyro.devAddr=0x69;
  } */
}

extern "C" void MPU9250_ReadRAW(int* pfData)
{

    accgyro.getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
	
    pfData[0]=ax;
	pfData[1]=ay;
    pfData[2]=az;
    pfData[3]=gx;
    pfData[4]=gy;
    pfData[5]=gz;
    pfData[6]=mx;
    pfData[7]=my;
    pfData[8]=mz;
    pfData[9]=accgyro.getTemperature();
	
}

extern "C" void MPU9250_ReadMag(int* pfData)
{

    accgyro.getMag(&mx, &my, &mz);
	
    pfData[0]=mx;
	pfData[1]=my;
    pfData[2]=mz;
	
	
}