
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "MPU6050.h"

MPU6050 accelgyro;

extern "C" void MPU6050Accel_Init(void)
{
    Wire.begin();
    accelgyro.initialize();
	
/* 	// Make devAddr public and add this line:
	if(!accelgyro.testConnection())
	{
		//Serial.println("Test Connection Failed Changing I2C addr to 0x69");
		accelgyro.devAddr=0x69;
	} */
	
	
	//  Enable I2C bypass on MPU6050 so the compass can be accessed
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_USER_CTRL, MPU6050_USERCTRL_I2C_MST_EN_BIT, false);
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_INT_PIN_CFG, MPU6050_INTCFG_I2C_BYPASS_EN_BIT, true);
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_PWR_MGMT_1, MPU6050_PWR1_SLEEP_BIT, false);
}
extern "C" void MPU6050Accel_Read(int* pfData)
{
    pfData[0]=accelgyro.getAccelerationX();
    pfData[1]=accelgyro.getAccelerationY();
    pfData[2]=accelgyro.getAccelerationZ();
}

extern "C" void MPU6050Gyro_Init(int DLPFmode)
{
    Wire.begin();
	accelgyro.setDLPFMode(DLPFmode);
    accelgyro.initialize();
}

extern "C" void MPU6050Gyro_Read(int* pfData)
{
    pfData[0]=accelgyro.getRotationX();
    pfData[1]=accelgyro.getRotationY();
    pfData[2]=accelgyro.getRotationZ();    
}

extern "C" void MPU6050Temp_Read(int* pfData)
{
    pfData[0]=accelgyro.getTemperature();
}

