#include <Arduino.h>
#include "PWMFSelect.h"

// Digital I/O initialization
extern "C" void PWM_Select(uint8_T PWM_Divisor, uint8_T PWM_Timer)
{

// If you reading this - yes, there is a better way to code this
// and if you know how, email me joshua.hurst.rpi@gmail.com
    

    /*
     * Timer	Pins
     * 0    	4,13
     * 1		11,12
     * 2		9,10
     * 3		2,3,5
     * 4 		6,7,8
     * 5 		44,45,46
     */
    
    // DSelect: the frequency divisor selection
    /*
     * DSelect Setting 	Divisor 	Frequency
     * 1		0x01 	 	1           31372.55
     * 2		0x02 	 	8           3921.16
     * 3		0x03  		64          490.20   <--DEFAULT
     * 4		0x04  		256 	 	122.55
     * 5		0x05 	 	1024 	 	30.64
     */
    
    /*
     * OR
     * Arduino Pin	 Register    Timer   	Prescale Register
     * 2	         OCR3B		 3			TCCR3B
     * 3	         OCR3C       3			TCCR3B
     * 4	         OCR0B       0			TCCR0B //Caution: will directly affects major timing functions { i.e delay and millis}
     * 5	         OCR3A       3			TCCR3B
     * 6	         OCR4A       4			TCCR4B
     * 7	         OCR4B       4			TCCR4B
     * 8	         OCR4C       4			TCCR4B
     * 9	         OCR2B       2			TCCR2B
     * 10	         OCR2A       2			TCCR2B
     * 11	         OCR1A       1			TCCR1B
     * 12	         OCR1B       1			TCCR1B
     * 13	         OCR0A       0			TCCR0B //Caution: will directly affects major timing functions { i.e delay and millis}
     * 44	         OCR5C       5			TCCR5B
     * 45	         OCR5B       5			TCCR5B
     * 46	         OCR5A       5			TCCR5B
     */
    
    
    
    
    switch(PWM_Divisor) {
        case 1:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x01;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x01;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x01;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x01;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x01;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x01;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 2:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x02;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x02;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x02;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x02;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x02;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x02;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 3:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x03;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x03;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x03;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x03;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x03;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x03;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 4:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x04;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x04;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x04;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x04;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x04;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x04;
                    break;
                default:
                    break;
            }
            break;
            
            
        case 5:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x05;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x05;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x05;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x05;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x05;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x05;
                    break;
                default:
                    break;
            }
            break;
			
        
            
        default:
            
            switch(PWM_Timer) {
                case 1:
                    TCCR1B=TCCR1B & 0b11111000 | 0x03;
                    break;
                case 2:
                    TCCR2B=TCCR2B & 0b11111000 | 0x03;
                    break;
                case 3:
                    TCCR3B=TCCR3B & 0b11111000 | 0x03;
                    break;
                case 4:
                    TCCR4B=TCCR4B & 0b11111000 | 0x03;
                    break;
                case 5:
                    TCCR5B=TCCR5B & 0b11111000 | 0x03;
                    break;
				case 6: 
					TCCR0B=TCCR0B & 0b11111000 | 0x03;
                    break;
                default:
                    break;
            }
            break;
            
    }
}
