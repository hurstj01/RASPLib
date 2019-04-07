
/* #include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "MPU6050.h" */

#include "Wire.h"
#include "VL53L0X.h"

VL53L0X sensor;

extern "C" void VL53L0X_Init(void)
{
  Wire.begin();
  sensor.init();
  //sensor.setTimeout(500);

  // Start continuous back-to-back mode (take readings as
  // fast as possible).  To use continuous timed mode
  // instead, provide a desired inter-measurement period in
  // ms (e.g. sensor.startContinuous(100)).
  sensor.startContinuous();
  
}
extern "C" void VL53L0X_Read(int* pfData)
{
	// set default sensor value to zero if out of range (or any desired value)
	int mm=0;
	mm=sensor.readRangeContinuousMillimeters();
	if(mm>8000){
		mm=0;
	}
	
    pfData[0]=mm;
}

