#include <Arduino.h>
#include "DataStartString.h"

// Digital I/O initialization
extern "C" void Send_Data_Start_String()
{
	
//#ifdef _RTT_USE_SERIAL0_
Serial.write("***Data Start***");
//#endif

}
