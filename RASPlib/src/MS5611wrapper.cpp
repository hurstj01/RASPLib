// MS5611wrapper.cpp

#include "Wire.h"
// #include "HMC58X3.h"
#include "twi.h"
#include "I2Cdev.h"
#include "MS5611.h"

MS5611 baro;
double referencePressure;

extern "C" void MS5611Baro_Init(void)
{
	
	baro.begin();
    referencePressure = baro.readPressure();
}

extern "C" void MS5611Baro_ReadRAW(float* pfData)
{
    pfData[0]=baro.readRawPressure();
	pfData[1]=baro.readRawTemperature();
}

extern "C" void MS5611Baro_Read(float* pfData)
{
    long realPressure = baro.readPressure();
    pfData[0]=baro.readPressure();
	pfData[1]=baro.readTemperature();
    pfData[2]=baro.getAltitude(realPressure);
	pfData[3]=baro.getAltitude(realPressure, referencePressure);
}

extern "C" void MS5611Baro_ReadALT(float* pfData)
{
    long realPressure = baro.readPressure();
    pfData[0]=baro.getAltitude(realPressure);
	pfData[1]=baro.getAltitude(realPressure);
}

extern "C" void MS5611Baro_ReadPT(float* pfData)
{
    pfData[0]=baro.readPressure();
	pfData[1]=baro.readTemperature();
}