// BMP280wrapper.cpp

#include "Wire.h"
#include "Adafruit_BMP280.h"

Adafruit_BMP280 bmp; // I2C

extern "C" void BMP280_Init(void)
{
	bmp.begin();
}

extern "C" void BMP280_Read(float* pfData)
{
    pfData[0]=bmp.readPressure();
	pfData[1]=bmp.readAltitude(1013.25);
	pfData[2]=bmp.readTemperature();
}
