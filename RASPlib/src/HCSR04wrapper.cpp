// HCSR04wrapper.cpp

#include "NewPing.h"

// setup for max of 3 sonar readings:
NewPing sonar1(0,0,0); // NewPing setup of pins and maximum distance.
NewPing sonar2(0,0,0); // NewPing setup of pins and maximum distance.
NewPing sonar3(0,0,0); // NewPing setup of pins and maximum distance.

extern "C" void HCSR04Sonar_Init(int trigger_pin, int echo_pin, int Sonar  )
{
    //uint8_t trigger_pin=7;
    //uint8_t echo_pin=8;
    int max_cm_distance=200;
    switch (Sonar){
        case 1:
            sonar1._triggerBit = digitalPinToBitMask(trigger_pin); // Get the port register bitmask for the trigger pin.
            sonar1._echoBit = digitalPinToBitMask(echo_pin);       // Get the port register bitmask for the echo pin.
            sonar1._triggerOutput = portOutputRegister(digitalPinToPort(trigger_pin)); // Get the output port register for the trigger pin.
            sonar1._echoInput = portInputRegister(digitalPinToPort(echo_pin));         // Get the input port register for the echo pin.
            sonar1._triggerMode = (uint8_t *) portModeRegister(digitalPinToPort(trigger_pin)); // Get the port mode register for the trigger pin.
            sonar1._maxEchoTime = min(max_cm_distance, MAX_SENSOR_DISTANCE) * US_ROUNDTRIP_CM + (US_ROUNDTRIP_CM / 2); // Calculate the maximum distance in uS.
            break;
        case 2:
            sonar2._triggerBit = digitalPinToBitMask(trigger_pin); // Get the port register bitmask for the trigger pin.
            sonar2._echoBit = digitalPinToBitMask(echo_pin);       // Get the port register bitmask for the echo pin.
            sonar2._triggerOutput = portOutputRegister(digitalPinToPort(trigger_pin)); // Get the output port register for the trigger pin.
            sonar2._echoInput = portInputRegister(digitalPinToPort(echo_pin));         // Get the input port register for the echo pin.
            sonar2._triggerMode = (uint8_t *) portModeRegister(digitalPinToPort(trigger_pin)); // Get the port mode register for the trigger pin.
            sonar2._maxEchoTime = min(max_cm_distance, MAX_SENSOR_DISTANCE) * US_ROUNDTRIP_CM + (US_ROUNDTRIP_CM / 2); // Calculate the maximum distance in uS.
            break;
        case 3:
            sonar3._triggerBit = digitalPinToBitMask(trigger_pin); // Get the port register bitmask for the trigger pin.
            sonar3._echoBit = digitalPinToBitMask(echo_pin);       // Get the port register bitmask for the echo pin.
            sonar3._triggerOutput = portOutputRegister(digitalPinToPort(trigger_pin)); // Get the output port register for the trigger pin.
            sonar3._echoInput = portInputRegister(digitalPinToPort(echo_pin));         // Get the input port register for the echo pin.
            sonar3._triggerMode = (uint8_t *) portModeRegister(digitalPinToPort(trigger_pin)); // Get the port mode register for the trigger pin.
            sonar3._maxEchoTime = min(max_cm_distance, MAX_SENSOR_DISTANCE) * US_ROUNDTRIP_CM + (US_ROUNDTRIP_CM / 2); // Calculate the maximum distance in uS.
            break;
    }
    
#if DISABLE_ONE_PIN == true
    *_triggerMode |= _triggerBit; // Set trigger pin to output.
#endif
    
}

extern "C" int HCSR04Sonar_Read(int Sonar)
{
    switch (Sonar){
        case 1:
            return sonar1.ping_cm();// US_ROUNDTRIP_CM;
            break;
        case 2:
            return sonar2.ping_cm();// US_ROUNDTRIP_CM;
            break;
        case 3:
            return sonar3.ping_cm();// US_ROUNDTRIP_CM;
            break;
    }
    
}

