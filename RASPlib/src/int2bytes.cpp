#include <math.h>
#include "int2bytes.h"

union{
    unsigned char b[2];
    int i;
} bint;


extern "C" void int2bytes(unsigned char* pfData, int int_in)
{
// copy the value to memory
// Write int data to memory:
bint.i=int_in;
// Assign those bytes in big-endian
// to the output vector
pfData[0]=bint.b[1];
pfData[1]=bint.b[0];
}

