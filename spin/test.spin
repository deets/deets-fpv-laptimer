{{
''***********************************************
''*  Program 6.1. Pulse-width modulation (PWM)
''*  Test Program.
''*  Author: Jon Titus 12-05-2014 Rev. 1
''*  Copyright 2014
''*  Released under Apache 2 license
''*  Two LEDs alternate bright-dim-bright cycles
''***********************************************
}}

CON _clkmode = xtal1 + pll16x           'Set MCU clock operation
    _xinfreq = 5_000_000                'Set for 5 MHz crystal
    
    data = 10                      
    chipselect  = 8                   
    clock  = 9
   
OBJ
  rtc  :  "rtc6715"                 

PUB go | frequency                              
  rtc.init(chipselect, clock, data)
   
  repeat
    repeat frequency from 0 to 39
        rtc.set_frequency(frequency)
        waitcnt(clkfreq/1000 + cnt)                     'wait 0.1 seconds

                            
    