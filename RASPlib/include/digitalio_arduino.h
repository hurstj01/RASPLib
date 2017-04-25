#ifndef _DIGITALIO_ARDUINO_H_
#define _DIGITALIO_ARDUINO_H_
#include "rtwtypes.h"

#ifdef __cplusplus
extern "C" {
#endif
    
#define DIN_INIT(pin) digitalIOSetup(pin, 0)
#define DOUT_INIT(pin) digitalIOSetup(pin, 1)
void digitalIOSetup(uint8_T pin, boolean_T mode);
void writeDigitalPin(uint8_T pin, boolean_T val);
void writeDigitalAnalogPin(uint8_T pin, boolean_T val);
boolean_T readDigitalPin(uint8_T pin);

#ifdef __cplusplus
}
#endif
#endif //_DIGITALIO_ARDUINO_H_
