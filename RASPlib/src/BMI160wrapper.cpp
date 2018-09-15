#include "BMI160Gen.h"

BMI160GenClass BMI160;

extern "C" void BMI160Gyro_Init(void)
{
  BMI160.begin(BMI160GenClass::I2C_MODE, 0x69);
}

extern "C" void BMI160Gyro_Read(int* pfData)
{
	int gx, gy, gz;         // raw gyro values
	// read raw gyro measurements from device
	BMI160.readGyro(gx, gy, gz);
	
    pfData[0]=gx;
    pfData[1]=gy;
    pfData[2]=gz;
}

