// BMP180wrapper.cpp

#include "Wire.h"
#include "Adafruit_BMP085.h"

Adafruit_BMP085 bmp; // I2C

extern "C" void BMP180_Init(void)
{
	bmp.begin();
}

extern "C" void BMP180_Read(float* pfData)
{
    pfData[0]=bmp.readPressure();
	pfData[1]=bmp.readAltitude();
	pfData[2]=bmp.readTemperature();
}
