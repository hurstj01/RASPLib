// HCSR04wrapper.cpp

#include "NewPing.h"

NewPing sonar(0,0,0); // NewPing setup of pins and maximum distance.

extern "C" void HCSR04Sonar_Init(int trigger_pin, int echo_pin  )
{
	//uint8_t trigger_pin=7;
	//uint8_t echo_pin=8;
	int max_cm_distance=200;
	sonar._triggerBit = digitalPinToBitMask(trigger_pin); // Get the port register bitmask for the trigger pin.
	sonar._echoBit = digitalPinToBitMask(echo_pin);       // Get the port register bitmask for the echo pin.

	sonar._triggerOutput = portOutputRegister(digitalPinToPort(trigger_pin)); // Get the output port register for the trigger pin.
	sonar._echoInput = portInputRegister(digitalPinToPort(echo_pin));         // Get the input port register for the echo pin.

	sonar._triggerMode = (uint8_t *) portModeRegister(digitalPinToPort(trigger_pin)); // Get the port mode register for the trigger pin.

	sonar._maxEchoTime = min(max_cm_distance, MAX_SENSOR_DISTANCE) * US_ROUNDTRIP_CM + (US_ROUNDTRIP_CM / 2); // Calculate the maximum distance in uS.

#if DISABLE_ONE_PIN == true
	*_triggerMode |= _triggerBit; // Set trigger pin to output.
#endif
	
}

extern "C" void HCSR04Sonar_Read(float* pfData)
{
    pfData[0]=sonar.ping_cm();// US_ROUNDTRIP_CM;
}

