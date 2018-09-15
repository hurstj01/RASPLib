#include "BMI160Gen.h"
#include "Wire.h"

//#define DEBUG

bool BMI160GenClass::begin(Mode mode, const int arg1, const int arg2)
{
    this->mode = mode;
    i2c_addr = arg1;
    return CurieIMUClass::begin();
}

void BMI160GenClass::ss_init()
{
    i2c_init();
}

int BMI160GenClass::ss_xfer(uint8_t *buf, unsigned tx_cnt, unsigned rx_cnt)
{
    return i2c_xfer(buf, tx_cnt, rx_cnt);
}

void BMI160GenClass::i2c_init()
{
  Wire.begin();
  Wire.beginTransmission(i2c_addr);
  if( Wire.endTransmission() != 0 )
      Serial.println("BMI160GenClass::i2c_init(): I2C failed.");
}

int BMI160GenClass::i2c_xfer(uint8_t *buf, unsigned tx_cnt, unsigned rx_cnt)
{
  uint8_t *p;

  Wire.beginTransmission(i2c_addr);
  p = buf;
  while (0 < tx_cnt) {
    tx_cnt--;
    Wire.write(*p++);
  }
  if( Wire.endTransmission() != 0 ) {
      Serial.println("Wire.endTransmission() failed.");
  }
  if (0 < rx_cnt) {
    Wire.requestFrom(i2c_addr, rx_cnt);
    p = buf;
    while ( Wire.available() && 0 < rx_cnt) {
      rx_cnt--;
#ifdef DEBUG
      int t = *p++ = Wire.read();
      Serial.print(" ");
      Serial.print(t, HEX);
#else
      *p++ = Wire.read();;
#endif // DEBUG
    }
  }

  return (0);
}
