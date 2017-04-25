#include <Arduino.h>
#include "digitalio_arduino.h"

// Digital I/O initialization
extern "C" void digitalIOSetup(uint8_T pin, boolean_T mode) 
{   
    // mode = 0: Input
    // mode = 1: Output
    if (mode) {
        pinMode(pin, OUTPUT);
    }
    else {
        pinMode(pin, INPUT);
    }
}

// Write a logic value to pin
extern "C" void writeDigitalPin(uint8_T pin, boolean_T val)
{
    digitalWrite(pin, val);
}

// Write a logic value to pin
extern "C" void writeDigitalAnalogPin(uint8_T pin, boolean_T val)
{
    digitalWrite(pin, val);
}

// Read logical state of a digital pin
extern "C" boolean_T readDigitalPin(uint8_T pin)
{
    return ((boolean_T)digitalRead(pin));
}


// [EOF]