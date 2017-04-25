#include <math.h>
#include "Arduino.h"
#include "float2bytes.h"
#include "io_wrappers.h"
//#include "inttypes.h"
//#include "stdio.h"
//#include "stdint.h"

union{
    unsigned char b[4];
    float f;
} bfloat;


extern "C" void float2bytes(unsigned char* pfData, float fin)
{
// copy the value to memory
// Write float data to memory:
bfloat.f=fin;
// Assign those bytes in big-endian
// to the output vector
pfData[0]=bfloat.b[3];
pfData[1]=bfloat.b[2];
pfData[2]=bfloat.b[1];
pfData[3]=bfloat.b[0];
}

