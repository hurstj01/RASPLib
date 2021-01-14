
#include "Wire.h"
#include "twi.h"
#include "I2Cdev.h"
#include "QMC5883.h"

QMC5883 compass;

extern "C" void QMC5883_Init(void)
{
    Wire.begin();
    compass.begin();
	
	//compass.setRange(QMC5883_RANGE_2GA);
    //compass.setMeasurementMode(QMC5883_CONTINOUS); 
    //compass.setDataRate(QMC5883_DATARATE_50HZ);
    //compass.setSamples(QMC5883_SAMPLES_8);

}

extern "C" void QMC5883_ReadMag(int* pfData)
{

	Vector mag = compass.readRaw();

    pfData[0]=mag.XAxis;
	pfData[1]=mag.YAxis;
    pfData[2]=mag.ZAxis;
	
}