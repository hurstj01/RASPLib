
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"

#include "quaternionFilters.h"
#include "MPU9250.h"

MPU9250 myIMU;

extern "C" void MPU9250_Init(void)
{
    Wire.begin();
	
	// more setup from header file initialization
    myIMU.Mscale = 1;   // MFS_14BITS = 0, // 0.6 mG per LSB    1      MFS_16BITS      // 0.15 mG per LSB
    myIMU.Mmode = 0x02; // M_8HZ = 0x02,  // 8 Hz update        M_100HZ = 0x06 // 100 Hz continuous magnetometer
    myIMU.Gscale=0;     // GFS_250DPS = 0, GFS_500DPS =1, GFS_1000DPS=2, GFS_2000DPS
    myIMU.Ascale=0;     // AFS_2G = 0, AFS_4G, AFS_8G,  AFS_16G
	
    // Calibrate gyro and accelerometers, load biases in bias registers
    myIMU.calibrateMPU9250(myIMU.gyroBias, myIMU.accelBias);
    myIMU.initMPU9250();
    // Initialize device for active mode read of acclerometer, gyroscope, and
    // temperature

    // Get magnetometer calibration from AK8963 ROM
     myIMU.initAK8963(myIMU.factoryMagCalibration);  
	 
	// Get sensor resolutions, only need to do this once
    myIMU.getAres();
    myIMU.getGres();
    myIMU.getMres();

}

extern "C" void MPU9250_ReadRAW(int* pfData)
{
	myIMU.readAccelData(myIMU.accelCount);  // Read the x/y/z adc values
	myIMU.readGyroData(myIMU.gyroCount);  // Read the x/y/z adc values
	myIMU.readMagData(myIMU.magCount);  // Read the x/y/z adc values
	myIMU.tempCount = myIMU.readTempData();  // Read the adc values
	
    pfData[0]=myIMU.accelCount[0];
	pfData[1]=myIMU.accelCount[1];
    pfData[2]=myIMU.accelCount[2];
    pfData[3]=myIMU.gyroCount[0];
    pfData[4]=myIMU.gyroCount[1];
    pfData[5]=myIMU.gyroCount[2];
    pfData[6]=myIMU.magCount[0];
    pfData[7]=myIMU.magCount[1];
    pfData[8]=myIMU.magCount[2];
    pfData[9]=myIMU.tempCount;    
	
}

extern "C" void MPU9250_Read(float* pfData)
{
	myIMU.readAccelData(myIMU.accelCount);  // Read the x/y/z adc values
	myIMU.readGyroData(myIMU.gyroCount);  // Read the x/y/z adc values
	myIMU.readMagData(myIMU.magCount);  // Read the x/y/z adc values
	myIMU.tempCount = myIMU.readTempData();  // Read the adc values
	
	// Now we'll calculate the accleration value into actual g's
    // This depends on scale being set
    myIMU.ax =(float)myIMU.accelCount[0] * myIMU.aRes; // - myIMU.accelBias[0];
    myIMU.ay =(float)myIMU.accelCount[1] * myIMU.aRes; // - myIMU.accelBias[1];
    myIMU.az =(float)myIMU.accelCount[2] * myIMU.aRes; // - myIMU.accelBias[2];
	
	// Calculate the gyro value into actual degrees per second
    // This depends on scale being set
    myIMU.gx = (float)myIMU.gyroCount[0] * myIMU.gRes;
    myIMU.gy = (float)myIMU.gyroCount[1] * myIMU.gRes;
    myIMU.gz = (float)myIMU.gyroCount[2] * myIMU.gRes;
	
	    // Calculate the magnetometer values in milliGauss
    // Include factory calibration per data sheet and user environmental
    // corrections
    // Get actual magnetometer value, this depends on scale being set
    myIMU.mx = (float)myIMU.magCount[0] * myIMU.mRes
               * myIMU.factoryMagCalibration[0] - myIMU.magBias[0];
    myIMU.my = (float)myIMU.magCount[1] * myIMU.mRes
               * myIMU.factoryMagCalibration[1] - myIMU.magBias[1];
    myIMU.mz = (float)myIMU.magCount[2] * myIMU.mRes
               * myIMU.factoryMagCalibration[2] - myIMU.magBias[2];
			   
    // Temperature in degrees Centigrade
	myIMU.temperature = ((float) myIMU.tempCount) / 333.87 + 21.0;
	
    pfData[0]=myIMU.ax;
	pfData[1]=myIMU.ay;
    pfData[2]=myIMU.az;
    pfData[3]=myIMU.gx;
    pfData[4]=myIMU.gy;
    pfData[5]=myIMU.gz;
    pfData[6]=myIMU.mx;
    pfData[7]=myIMU.my;
    pfData[8]=myIMU.mz;
    pfData[9]=myIMU.temperature;
	
}
