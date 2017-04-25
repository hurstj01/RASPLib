
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "HMC58X3.h"

HMC58X3 magn;
int ix,iy,iz;

#include "MPU6050.h"

extern "C" void HMC58X3_Init(void)
{
    Wire.begin();
    magn.init(1);
	
	//  Enable I2C bypass on MPU6050 so the compass can be accessed
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_USER_CTRL, MPU6050_USERCTRL_I2C_MST_EN_BIT, false);
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_INT_PIN_CFG, MPU6050_INTCFG_I2C_BYPASS_EN_BIT, true);
	I2Cdev::writeBit(MPU6050_DEFAULT_ADDRESS, MPU6050_RA_PWR_MGMT_1, MPU6050_PWR1_SLEEP_BIT, false);
}

extern "C" void HMC58X3_Read(float* pfData)
{
	magn.getRaw(&ix,&iy,&iz);
    pfData[0]=ix;
    pfData[1]=iy;
    pfData[2]=iz;
}
