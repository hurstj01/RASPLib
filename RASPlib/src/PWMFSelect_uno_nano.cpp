#include <Arduino.h>
#include "PWMFSelect.h"

// Digital I/O initialization
extern "C" void PWM_Select(uint8_T PWM_Divisor, uint8_T PWM_Timer)
{

// If you reading this - yes, there is a better way to code this
// and if you know how, email me joshua.hurst.rpi@gmail.com
    

    /*
     * Timer	Pins
     * 0    	5, 6
     * 1		9, 10
     * 2		3, 11

    
    // DSelect: the frequency divisor selection
    /*
     * DSelect Setting 	Divisor 	Frequency
     * 1		0x01 	 	1           31372.55
     * 2		0x02 	 	8           3921.16
     * 3		0x03  		64          490.20   <--DEFAULT
     * 4		0x04  		256 	 	122.55
     * 5		0x05 	 	1024 	 	30.64
     */
       
    switch(PWM_Divisor) {
        case 1:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x01;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x01;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x01;
                    break;              
                default:
                    break;
            }
            break;
            
            
        case 2:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x02;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x02;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x02;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 3:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x03;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x03;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x03;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 4:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x04;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x04;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x04;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 5:
            
            switch(PWM_Timer) {
                 case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x05;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x05;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x05;
                    break;
                default:
                    break;
            }
            break;
            
            
        default:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR0B=TCCR0B & 0b11111000 | 0x03;
                    break;
                case 2:
                    TCCR1B=TCCR1B & 0b11111000 | 0x03;
                    break;
                case 3:
                    TCCR2B=TCCR2B & 0b11111000 | 0x03;
                    break;
                default:
                    break;
            }
            break;
            
    }
}
