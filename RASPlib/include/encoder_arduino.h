#ifndef _ENCODER_ARDUINO_H
#define _ENCODER_ARDUINO_H
#include "rtwtypes.h"

#ifdef __cplusplus
extern "C" {
#endif

void enc_init(int enc, int pinA, int pinB);
long enc_output(long enc);

#ifdef __cplusplus
}
#endif
#endif //_ENCODER_ARDUINO_H

