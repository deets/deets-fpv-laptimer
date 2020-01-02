{{

  RTC6715 Driver

  Author: Diez Roggisch

  Version 1.0

  Date: 28 October 2018


}}

CON

VAR

  byte clock, data

PUB init(_clock, _data)
    clock := _clock
    data := _data

    'set output directions
    dira[clock]~~
    dira[data]~~
    outa[clock]~
    outa[data]~

PUB set_frequency(chipselect, f)
    outa[chipselect]~
    write_register($1)
    write_data(frequency_table[f])
    outa[chipselect]~~

PRI write_register(r)
    r := r | $10 ' set R/W bit
    r <-= 1 ' pre-align
    repeat 5
         outa[data] := (r ->= 1) & 1
         outa[clock]~~
         'waitcnt(cnt + 800)
         outa[clock]~
         'waitcnt(cnt + 800)

PRI write_data(x)
    x <-= 1 ' pre-align
    repeat 20
         outa[data] := (x ->= 1) & 1
         outa[clock]~~
         'waitcnt(cnt + 800)
         outa[clock]~
         'waitcnt(cnt + 800)



DAT
frequency_table word $2817, $281d, $2881, $288b, $2890, $2895
                word $289f, $2902, $2903, $2906, $2909, $290c
                word $2910, $2913, $2915, $2916, $291a, $291d
                word $291f, $2984, $2987, $2987, $2989, $298e
                word $2991, $2992, $2998, $299a, $299b, $299c
                word $2a02, $2a05, $2a05, $2a0c, $2a0c, $2a0f
                word $2a19, $2a1f, $2a83, $2a8d

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