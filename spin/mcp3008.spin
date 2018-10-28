{{

  mcp3008 Driver

  Author: Diez Roggisch

  Version 1.0

  Date: 28 October 2018


}}

CON

VAR

  byte chipselect, clock, mosi, miso
PUB init(_chipselect, _clock, _mosi, _miso)
    chipselect := _chipselect
    clock := _clock
    mosi := _mosi
    miso := _miso

    'set output directions
    dira[chipselect]~~   ' output
    dira[clock]~~
    dira[mosi]~~
    dira[miso]~          ' input
    'set initial line states
    outa[chipselect]~~
    outa[clock]~
    outa[mosi]~

PUB read_channel(c) : r
    outa[chipselect]~ ' assert cs
    c |= %11000 ' set start bit and single aquisition
    c ><= 5     ' reverse bit order, msb first
    c <-= 1     ' pre-align
    repeat 5
      outa[mosi] := (c ->= 1) & 1
      outa[clock]~~
      outa[clock]~

    ' cycle a clock to acquire data
    outa[clock]~~
    outa[clock]~

    repeat 10
      outa[clock]~~
      r |= ina[miso]
      outa[clock]~
      r <-= 1
    'r ><= 10

    outa[chipselect]~~

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