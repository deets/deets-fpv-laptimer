{{

  AD7731 Driver

  Author: Diez Roggisch
  
  Version 1.0

  Date: 28 October 2018


}}

CON
   
VAR

  byte spi_clk, mosi, miso, chipselect, data_ready
PUB init(_spi_clk, _mosi, _miso, _chipselect, _data_ready)
    spi_clk := _spi_clk
    mosi := _mosi
    miso := _miso
    chipselect := _chipselect
    data_read := _data_ready
      

    'set output directions
    dira[spi_clk]~~   ' output
    dira[mosi]~~
    dira[chipselect]~~  
    dira[data_ready]~       'input
    dira[miso]~
    'set initial line states
    outa[chipselect]~~ 
    outa[spi_clk]~
    outa[mosi]~
  

PRI wait_for_data_ready | t 
' wait with a timeout WAIT_MS

  t := cnt
  repeat until (ina[ndrdy] == 0) or (cnt - t) / (clkfreq / 1000) > WAIT_MS

 {{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}            